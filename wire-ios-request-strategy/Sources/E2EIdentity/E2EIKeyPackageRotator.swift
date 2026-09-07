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

import CoreData
import Foundation
import WireCoreCrypto
import WireDataModel
import WireLogging

// sourcery: AutoMockable
public protocol E2EIKeyPackageRotating {
    func rotateKeysAndMigrateConversations(credential: Credential) async throws
    func uploadNewKeyPackages(credentialRef: CredentialRef) async throws
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

    private var coreCrypto: SafeCoreCrypto {
        get async throws {
            try await coreCryptoProvider.coreCrypto()
        }
    }

    // MARK: - Life cycle

    public init(
        coreCryptoProvider: CoreCryptoProviderProtocol,
        context: NSManagedObjectContext,
        featureRepository: LegacyFeatureRepositoryInterface
    ) {
        self.coreCryptoProvider = coreCryptoProvider
        self.context = context
        self.featureRepository = featureRepository
    }

    // MARK: - Interface

    public func rotateKeysAndMigrateConversations(credential: Credential) async throws {
        let credentialRef = try await coreCrypto.transaction { context in
            try await context.addCredential(credential: credential)
        }

        try await replaceCredentialsInExistingConversations(with: credentialRef)
        try await replaceKeyPackages(with: credentialRef)
    }

    public func uploadNewKeyPackages(credentialRef: CredentialRef) async throws {
        try await replaceKeyPackages(with: credentialRef)
    }

    // MARK: - Helpers

    private func replaceCredentialsInExistingConversations(with credential: CredentialRef) async throws {
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

        try await coreCrypto.transaction { context in
            for groupID in mlsConversationsToMigrate {
                do {
                    try await context.setConversationCredential(
                        conversationId: groupID.conversationId,
                        credentialRef: credential
                    )
                } catch {
                    WireLogger.e2ei
                        .warn(
                            "failed to rotate keys for group \(groupID.safeForLoggingDescription): \(String(describing: error))"
                        )
                }
            }
        }
    }

    private func replaceKeyPackages(with credentialRef: CredentialRef) async throws {
        let mlsConfig = await featureRepository.fetchMLS().config
        let context = context

        guard let clientID = await context.perform({
            ZMUser.selfUser(in: context).selfClient()?.remoteIdentifier
        }) else {
            throw Error.noSelfClient
        }

        guard let ciphersuite = MLSCipherSuite(rawValue: mlsConfig.defaultCipherSuite.rawValue) else {
            throw Error.invalidCiphersuite
        }

        let existingCredentials = try await coreCrypto.coreCrypto.findCredentials(
            clientId: nil,
            publicKey: nil,
            cipherSuite: ciphersuite.coreCryptoCipherSuite,
            credentialType: nil,
            earliestValidity: nil
        )

        let previousCredential = existingCredentials.first { credential in
            credential.publicKeyHash() != credentialRef.publicKeyHash()
        }

        try await coreCrypto.transaction { coreCryptoContext in
            var newKeyPackages: [WireCoreCrypto.KeyPackage] = []

            for _ in 0 ..< self.newKeyPackageCount {
                let keyPackage = try await coreCryptoContext.generateKeyPackage(
                    credentialRef: credentialRef,
                    lifetime: nil
                )
                newKeyPackages.append(keyPackage)
            }

            var action = ReplaceSelfMLSKeyPackagesAction(
                clientID: clientID,
                keyPackages: try newKeyPackages.map { try $0.serialize().base64EncodedString() },
                ciphersuite: ciphersuite
            )
            try await action.perform(in: self.context.notificationContext)

            if let previousCredential {
                try await coreCryptoContext.removeCredential(credentialRef: previousCredential)
            }
        }
    }

}
