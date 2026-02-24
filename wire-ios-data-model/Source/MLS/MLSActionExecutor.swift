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
import WireLogging

public protocol MLSActionExecutorProtocol {

    /// Processes a welcome message.
    ///
    /// - Parameters:
    ///     - message: The welcome message to process.
    ///     - context: if provided, processing will happen within the existing transaction
    /// - Returns: The group ID of the group the welcome message was for.
    ///
    /// If any new CRL distribution points are found, they will be published.
    /// They can be observed with ``MLSActionExecutor/onNewCRLsDistributionPoints()``

    func processWelcomeMessage(_ message: Data, context: CoreCryptoContextProtocol?) async throws -> MLSGroupID

    /// Creates and sends a commit bundle to add the invitees to a group.
    ///
    /// - Parameters:
    ///   - invitees: The key packages of the clients to add.
    ///   - groupID: The group ID of the group to add members to.
    /// - Returns: Update events returned by the backend.
    ///
    /// If any new CRL distribution points are found, they will be published.
    /// They can be observed with ``MLSActionExecutor/onNewCRLsDistributionPoints()``

    func addMembers(
        _ invitees: [KeyPackage],
        to groupID: MLSGroupID
    ) async throws

    /// Creates and sends a commit bundle to remove clients from a group.
    ///
    /// - Parameters:
    ///   - clients: The IDs of the clients to remove.
    ///   - groupID: The group ID of the group to remove clients from.
    /// - Returns: Update events returned by the backend.

    func removeClients(
        _ clients: [ClientId],
        from groupID: MLSGroupID
    ) async throws

    /// Creates and sends a commit bundle to update the key material for a group.
    ///
    /// - Parameter groupID: The group ID of the group to update key material for.
    /// - Returns: Update events returned by the backend.

    func updateKeyMaterial(for groupID: MLSGroupID) async throws

    /// Creates and sends a commit bundle to commit the pending proposals for a group.
    ///
    /// - Parameter groupID: The group ID of the group to commit pending proposals for.
    /// - Returns: Update events returned by the backend.
    /// - Throws: `CommitError.noPendingProposals` if there are no proposals to commit.

    func commitPendingProposals(in groupID: MLSGroupID) async throws

    /// Creates and sends an **external** commit to join a group.
    ///
    /// - Parameters:
    ///   - groupID: The group ID of the group to join.
    ///   - groupInfo: The group info of the group to join.
    /// - Returns: Update events returned by the backend.
    ///
    /// If any new CRL distribution points are found, they will be published.
    /// They can be observed with ``MLSActionExecutor/onNewCRLsDistributionPoints()``

    func joinGroup(
        _ groupID: MLSGroupID,
        groupInfo: Data
    ) async throws

    /// Decrypts a message for a group.
    ///
    /// - Parameters:
    ///   - message: The message to decrypt.
    ///   - groupID: The group ID of the group this message was for.
    ///   - context: if provided, decryption will happen within the existing transaction
    /// - Returns: The decrypted message.

    func decryptMessage(
        _ message: Data,
        in groupID: MLSGroupID,
        context: CoreCryptoContextProtocol?
    ) async throws -> DecryptedMessage?

    /// Returns a publisher that emits the new CRL distribution points when they are found

    func onNewCRLsDistributionPoints() -> AnyPublisher<CRLsDistributionPoints, Never>

}

/// An actor responsible for performing commits on MLS groups and decrypting messages in a non-reentrant manner.

let coreCryptoCommitForMissingProposalError =
    "Incoming message is a commit for which we have not yet received all the proposals. Buffering until all proposals have arrived."

public actor MLSActionExecutor: MLSActionExecutorProtocol {

    enum Failure: Error {
        case bufferedDecryptedMessage
    }

    // MARK: - Types

    enum Action {

        case addMembers([KeyPackage])
        case removeClients([ClientId])
        case updateKeyMaterial
        case proposal
        case joinGroup(Data)

    }

    // MARK: - Properties

    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private var continuationsByGroupID: [MLSGroupID: [CheckedContinuation<Void, Never>]] = [:]
    private let onNewCRLsDistributionPointsSubject = PassthroughSubject<CRLsDistributionPoints, Never>()
    private let featureRepository: LegacyFeatureRepositoryInterface

    private var coreCrypto: SafeCoreCryptoProtocol {
        get async throws {
            try await coreCryptoProvider.coreCrypto()
        }
    }

    // MARK: - Life cycle

    public init(
        coreCryptoProvider: CoreCryptoProviderProtocol,
        featureRepository: LegacyFeatureRepositoryInterface
    ) {
        self.coreCryptoProvider = coreCryptoProvider
        self.featureRepository = featureRepository
    }

    // MARK: - Non-reentrant

    /// Perform an non-rentrant operation on an MLS group.
    ///
    /// That is only one operation is allowed execute concurrently, if multiple operations for the same group is
    /// scheduled
    /// they will be queued and executed in sequence.
    ///
    /// This is used for operations where ordering is important. For example when sending a commit to add client to a
    /// group, this is a two-step operations:
    ///
    /// 1. Create pending commit and send to distribution server
    /// 2. Merge pending commit when accepted by distribution server
    ///
    /// Here's it's critical that no other operation like `decryptMessage` is performed
    /// between step 1 and 2. We enforce this by wrapping all `decrypt` and `commit` operations
    /// inside `performNonReentrant`

    func performNonReentrant<T>(groupID: MLSGroupID, operation: () async throws -> T) async rethrows -> T {
        if continuationsByGroupID.keys.contains(groupID) {
            await withCheckedContinuation { continuation in
                continuationsByGroupID[groupID]?.append(continuation)
            }
        }

        if !continuationsByGroupID.keys.contains(groupID) {
            // an empty entry means an operation is currently executing, a non-empty
            // entry are queued operations.
            continuationsByGroupID[groupID] = []
        }

        defer {
            if var continuations = continuationsByGroupID[groupID] {
                if !continuations.isEmpty {
                    continuations.removeFirst().resume()
                    continuationsByGroupID[groupID] = continuations
                }

                if continuations.isEmpty {
                    continuationsByGroupID.removeValue(forKey: groupID)
                }
            }
        }

        return try await operation()
    }

    // MARK: - Actions

    public func processWelcomeMessage(_ message: Data, context: CoreCryptoContextProtocol?) async throws -> MLSGroupID {
        if let context {
            try await processWelcomeMessageInternal(message, context: context)
        } else {
            try await coreCrypto.perform { context in
                try await self.processWelcomeMessageInternal(message, context: context)
            }
        }
    }

    private func processWelcomeMessageInternal(
        _ message: Data,
        context: CoreCryptoContextProtocol
    ) async throws -> MLSGroupID {
        let welcomeBundle = try await context.processWelcomeMessage(
            welcomeMessage: .init(bytes: message),
            customConfiguration: .init(keyRotationSpan: nil, wirePolicy: nil)
        )

        if let newDistributionPoints = CRLsDistributionPoints(
            from: welcomeBundle.crlNewDistributionPoints
        ) {
            onNewCRLsDistributionPointsSubject.send(newDistributionPoints)
        }

        return MLSGroupID(welcomeBundle.id)
    }

    public func addMembers(_ invitees: [WireDataModel.KeyPackage], to groupID: MLSGroupID) async throws {
        try await performNonReentrant(groupID: groupID) {
            do {
                WireLogger.mls.info("adding members to group...", attributes: groupID.safeAttributes)

                let crlNewDistributionPoints = try await coreCrypto.perform {
                    try await $0.addClientsToConversation(
                        conversationId: groupID.conversationId,
                        keyPackages: invitees.compactMap(\.coreCryptoKeyPackage)
                    )
                }

                if let newDistributionPoints = CRLsDistributionPoints(
                    from: crlNewDistributionPoints
                ) {
                    onNewCRLsDistributionPointsSubject.send(newDistributionPoints)
                }

                WireLogger.mls.info("success: adding members to group", attributes: groupID.safeAttributes)
            } catch {
                WireLogger.mls
                    .error(
                        "failed: adding members to group: \(String(describing: error))",
                        attributes: groupID.safeAttributes
                    )
                throw error
            }
        }
    }

    public func removeClients(_ clients: [ClientId], from groupID: MLSGroupID) async throws {
        try await performNonReentrant(groupID: groupID) {
            do {
                WireLogger.mls.info("removing clients from group...", attributes: groupID.safeAttributes)
                return try await coreCrypto.perform {
                    try await $0.removeClientsFromConversation(
                        conversationId: groupID.conversationId,
                        clients: clients
                    )
                }
            } catch {
                WireLogger.mls
                    .error(
                        "error: removing clients from group: \(String(describing: error))",
                        attributes: groupID.safeAttributes
                    )
                throw error
            }
        }
    }

    public func updateKeyMaterial(for groupID: MLSGroupID) async throws {
        try await performNonReentrant(groupID: groupID) {
            do {
                WireLogger.mls.info("updating key material for group...", attributes: groupID.safeAttributes)
                return try await coreCrypto.perform {
                    try await $0.updateKeyingMaterial(conversationId: groupID.conversationId)
                }
            } catch {
                WireLogger.mls
                    .error(
                        "error: updating key material for group: \(String(describing: error))",
                        attributes: groupID.safeAttributes
                    )
                throw error
            }
        }
    }

    public func commitPendingProposals(in groupID: MLSGroupID) async throws {
        try await performNonReentrant(groupID: groupID) {
            do {
                WireLogger.mls.info("committing pending proposals for group", attributes: groupID.safeAttributes)
                try await coreCrypto.perform {
                    try await $0.commitPendingProposals(conversationId: groupID.conversationId)
                }
                WireLogger.mls
                    .info("success: committing pending proposals for group", attributes: groupID.safeAttributes)
            } catch {
                WireLogger.mls
                    .error(
                        "error: committing pending proposals for group: \(String(describing: error))",
                        attributes: groupID.safeAttributes
                    )
                throw error
            }
        }
    }

    public func joinGroup(_ groupID: MLSGroupID, groupInfo: Data) async throws {
        try await performNonReentrant(groupID: groupID) {
            do {
                WireLogger.mls.info("joining group via external commit", attributes: groupID.safeAttributes)
                let ciphersuite = await featureRepository.fetchMLS().config.defaultCipherSuite.coreCryptoCipherSuite
                let conversationInitBundle = try await coreCrypto.perform {
                    let e2eiIsEnabled = try await $0.e2eiIsEnabled(ciphersuite: ciphersuite)
                    return try await $0.joinByExternalCommit(
                        groupInfo: GroupInfo(bytes: groupInfo),
                        customConfiguration: .init(keyRotationSpan: nil, wirePolicy: nil),
                        credentialType: e2eiIsEnabled ? .x509 : .basic
                    )
                }
                if let newDistributionPoints = CRLsDistributionPoints(
                    from: conversationInitBundle.crlNewDistributionPoints
                ) {
                    onNewCRLsDistributionPointsSubject.send(newDistributionPoints)
                }
                WireLogger.mls.info("success: joining group via external commit", attributes: groupID.safeAttributes)
            } catch {
                WireLogger.mls
                    .error(
                        "error: joining group via external commit: \(String(describing: error))",
                        attributes: groupID.safeAttributes
                    )
                throw error
            }
        }
    }

    // MARK: - Decryption

    public func decryptMessage(
        _ message: Data,
        in groupID: MLSGroupID,
        context: CoreCryptoContextProtocol?
    ) async throws -> DecryptedMessage? {
        if let context {
            try await decryptMessageInternal(message, in: groupID, context: context)
        } else {
            try await performNonReentrant(groupID: groupID) {
                try await coreCrypto.perform {
                    try await self.decryptMessageInternal(message, in: groupID, context: $0)
                }
            }
        }
    }

    private func decryptMessageInternal(
        _ message: Data,
        in groupID: MLSGroupID,
        context: CoreCryptoContextProtocol
    ) async throws -> DecryptedMessage? {
        do {
            return try await context.decryptMessage(conversationId: groupID.conversationId, payload: message)
        } catch let CoreCryptoError.Mls(error) {
            switch error {
            case .BufferedFutureMessage, .BufferedCommit:
                // ignore error so transaction is saved and message is saved too.
                return nil
            default:
                throw CoreCryptoError.Mls(error)
            }
        } catch {
            throw error
        }
    }

    // MARK: - CRLs distribution points publisher

    public nonisolated
    func onNewCRLsDistributionPoints() -> AnyPublisher<CRLsDistributionPoints, Never> {
        onNewCRLsDistributionPointsSubject.eraseToAnyPublisher()
    }

}

extension MLSActionExecutor.Action: CustomDebugStringConvertible {

    var debugDescription: String {
        switch self {
        case .addMembers:
            "addMembers"

        case .removeClients:
            "removeClients"

        case .updateKeyMaterial:
            "updateKeyMaterial"

        case .proposal:
            "proposal"

        case .joinGroup:
            "joinGroup"
        }
    }

}

extension MLSGroupID {
    var safeAttributes: LogAttributes {
        [.mlsGroupID: safeForLoggingDescription, .public: true]
    }
}
