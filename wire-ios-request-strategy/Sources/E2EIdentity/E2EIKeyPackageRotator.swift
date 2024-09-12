//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

import Foundation
import WireCoreCrypto
import WireDataModel
import Combine

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
    private let conversationEventProcessor: ConversationEventProcessorProtocol
    private let context: NSManagedObjectContext
    private let commitSender: CommitSending
    private let newKeyPackageCount: UInt32 = 100
    private let featureRepository: FeatureRepositoryInterface
    private let onNewCRLsDistributionPointsSubject: PassthroughSubject<CRLsDistributionPoints, Never>

    private var coreCrypto: SafeCoreCryptoProtocol {
        get async throws {
            try await coreCryptoProvider.coreCrypto()
        }
    }

    // MARK: - Life cycle

    public init(
        coreCryptoProvider: CoreCryptoProviderProtocol,
        conversationEventProcessor: ConversationEventProcessorProtocol,
        context: NSManagedObjectContext,
        onNewCRLsDistributionPointsSubject: PassthroughSubject<CRLsDistributionPoints, Never>,
        commitSender: CommitSending? = nil,
        featureRepository: FeatureRepositoryInterface
    ) {
        self.coreCryptoProvider = coreCryptoProvider
        self.conversationEventProcessor = conversationEventProcessor
        self.context = context
        self.onNewCRLsDistributionPointsSubject = onNewCRLsDistributionPointsSubject
        self.commitSender = commitSender ?? CommitSender(
            coreCryptoProvider: coreCryptoProvider,
            notificationContext: context.notificationContext
        )
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

        // Get the rotate bundle from core crypto
        let rotateBundle = try await coreCrypto.perform {
            try await $0.e2eiRotateAll(
                enrollment: enrollment,
                certificateChain: certificateChain,
                newKeyPackagesCount: newKeyPackageCount
            )
        }

        guard rotateBundle.commits.isNonEmpty else {
            // TODO: [WPB-6281] [jacob] remove this guard when implementing
            return
        }

        // Replace the key packages with the ones including the certificate
        try await replaceKeyPackages(rotateBundle: rotateBundle)

        // Send migration commits after key packages rotations
        for (groupID, commit) in rotateBundle.commits {
            do {
                try await migrateConversation(with: groupID, commit: commit)
            } catch {
                WireLogger.e2ei.warn("failed to rotate keys for group: \(String(describing: error))")
            }
        }

        // Publish new certificate revocation lists (CRLs) distribution points
        if let newDistributionPoints = CRLsDistributionPoints(from: rotateBundle.crlNewDistributionPoints) {
            onNewCRLsDistributionPointsSubject.send(newDistributionPoints)
        }
    }

    // MARK: - Helpers

    private func replaceKeyPackages(rotateBundle: RotateBundle) async throws {

        guard let clientID = await context.perform({ [self] in
            ZMUser.selfUser(in: context).selfClient()?.remoteIdentifier
        }) else {
            throw Error.noSelfClient
        }

        let newKeyPackages = rotateBundle.newKeyPackages.map { $0.base64String() }
        let mlsConfig = await featureRepository.fetchMLS().config
        guard let ciphersuite = MLSCipherSuite(rawValue: mlsConfig.defaultCipherSuite.rawValue) else {
            throw Error.invalidCiphersuite
        }
        var action = ReplaceSelfMLSKeyPackagesAction(
            clientID: clientID,
            keyPackages: newKeyPackages,
            ciphersuite: ciphersuite
        )
        try await action.perform(in: context.notificationContext)
    }

    private func migrateConversation(with groupID: String, commit: CommitBundle) async throws {
        guard let groupData = groupID.zmHexDecodedData() else {
            throw Error.invalidGroupID
        }

        let groupID = MLSGroupID(groupData)
        let events = try await commitSender.sendCommitBundle(
            commit,
            for: groupID
        )

        await conversationEventProcessor.processConversationEvents(events)
    }

}
