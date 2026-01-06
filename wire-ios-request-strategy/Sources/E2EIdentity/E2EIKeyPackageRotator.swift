//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Combine
import Foundation
import WireCoreCrypto
import WireDataModel
import WireLogging

// sourcery: AutoMockable
public protocol E2EIKeyPackageRotating {

    func rotateKeysAndMigrateConversations(
        enrollment: E2eiEnrollmentProtocol,
        certificateChain: String
    ) async throws

}

public class E2EIKeyPackageRotator: E2EIKeyPackageRotating {

    // MARK: - Types

    enum Error: Swift.Error {
        case noSelfClient
        case invalidGroupID
        case invalidIdentity
        case invalidCiphersuite
    }

    // MARK: - Properties

    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private let context: NSManagedObjectContext
    private let newKeyPackageCount: UInt32 = 100
    private let featureRepository: LegacyFeatureRepositoryInterface
    private let onNewCRLsDistributionPointsSubject: PassthroughSubject<CRLsDistributionPoints, Never>

    private var coreCrypto: SafeCoreCryptoProtocol {
        get async throws {
            try await coreCryptoProvider.coreCrypto()
        }
    }

    // MARK: - Life cycle

    public init(
        coreCryptoProvider: CoreCryptoProviderProtocol,
        context: NSManagedObjectContext,
        onNewCRLsDistributionPointsSubject: PassthroughSubject<CRLsDistributionPoints, Never>,
        featureRepository: LegacyFeatureRepositoryInterface
    ) {
        self.coreCryptoProvider = coreCryptoProvider
        self.context = context
        self.onNewCRLsDistributionPointsSubject = onNewCRLsDistributionPointsSubject
        self.featureRepository = featureRepository
    }

    // MARK: - Interface

    public func rotateKeysAndMigrateConversations(
        enrollment: E2eiEnrollmentProtocol,
        certificateChain: String
    ) async throws {

        // We need to cast this to `E2eiEnrollment` because we only have access
        // to the protocol it conforms to (E2eiEnrollmentProtocol),
        // but the `e2eiRotateAll` function below expects the `E2eiEnrollment` type
        guard let enrollment = enrollment as? E2eiEnrollment else {
            throw Error.invalidIdentity
        }

        let crlNewDistributionPoints = try await coreCrypto.perform { context in
            try await context.saveX509Credential(
                enrollment: enrollment,
                certificateChain: certificateChain
            )
        }

        try await replaceKeyPackages()
        try await replaceCredentialsInExistingConversations()

        // Publish new certificate revocation lists (CRLs) distribution points
        if let newDistributionPoints = CRLsDistributionPoints(from: crlNewDistributionPoints) {
            onNewCRLsDistributionPointsSubject.send(newDistributionPoints)
        }
    }

    // MARK: - Helpers

    private func replaceCredentialsInExistingConversations() async throws {
        let mlsConversationsToMigrate = try await context.perform {
            var mlsGroupIDs = try ZMConversation.fetchConversationsWithMLSGroupStatus(
                mlsGroupStatus: .ready,
                in: self.context
            ).compactMap(\.mlsGroupID)

            if let selfMLSGroupID = ZMConversation.fetchSelfMLSConversation(in: self.context)?.mlsGroupID {
                mlsGroupIDs.append(selfMLSGroupID)
            }

            return mlsGroupIDs
        }

        try await coreCrypto.perform { context in
            for groupID in mlsConversationsToMigrate {
                do {
                    try await context.e2eiRotate(conversationId: groupID.conversationId)
                } catch {
                    WireLogger.e2ei
                        .warn(
                            "failed to rotate keys for group \(groupID.safeForLoggingDescription): \(String(describing: error))"
                        )
                }
            }
        }
    }

    private func replaceKeyPackages() async throws {
        let mlsConfig = await featureRepository.fetchMLS().config

        guard let clientID = await context.perform({ [self] in
            ZMUser.selfUser(in: context).selfClient()?.remoteIdentifier
        }) else {
            throw Error.noSelfClient
        }

        guard let ciphersuite = MLSCipherSuite(rawValue: mlsConfig.defaultCipherSuite.rawValue) else {
            throw Error.invalidCiphersuite
        }

        try await coreCrypto.perform { coreCryptoContext in
            let newKeyPackages = try await coreCryptoContext.clientKeypackages(
                ciphersuite: ciphersuite.coreCryptoCipherSuite,
                credentialType: .x509,
                amountRequested: self.newKeyPackageCount
            )

            var action = ReplaceSelfMLSKeyPackagesAction(
                clientID: clientID,
                keyPackages: newKeyPackages.map { $0.copyBytes().base64EncodedString() },
                ciphersuite: ciphersuite
            )
            try await action.perform(in: self.context.notificationContext)
            try await coreCryptoContext.deleteStaleKeyPackages(
                ciphersuite: ciphersuite.coreCryptoCipherSuite
            )
        }
    }

}
