//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import Combine

public protocol MLSActionExecutorProtocol {

    func addMembers(_ invitees: [KeyPackage], to groupID: MLSGroupID) async throws -> [ZMUpdateEvent]
    func removeClients(_ clients: [ClientId], from groupID: MLSGroupID) async throws -> [ZMUpdateEvent]
    func updateKeyMaterial(for groupID: MLSGroupID) async throws -> [ZMUpdateEvent]
    func commitPendingProposals(in groupID: MLSGroupID) async throws -> [ZMUpdateEvent]
    func joinGroup(_ groupID: MLSGroupID, groupInfo: Data) async throws -> [ZMUpdateEvent]
    func decryptMessage(_ message: Data, in groupID: MLSGroupID) async throws -> DecryptedMessage
    func onEpochChanged() -> AnyPublisher<MLSGroupID, Never>

}

public actor MLSActionExecutor: MLSActionExecutorProtocol {

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
    private let commitSender: CommitSending
    private var continuationsByGroupID: [MLSGroupID: [CheckedContinuation<Void, Never>]] = [:]

    private var coreCrypto: SafeCoreCryptoProtocol {
        get async throws {
            try await coreCryptoProvider.coreCrypto(requireMLS: true)
        }
    }

    // MARK: - Life cycle

    public init(
        coreCryptoProvider: CoreCryptoProviderProtocol,
        commitSender: CommitSending
    ) {
        self.coreCryptoProvider = coreCryptoProvider
        self.commitSender = commitSender
    }

    // MARK: - Non-reentrant

    /// Perform an non-rentrant operation on an MLS group.
    ///
    /// That is only one operation is allowed execute concurrently, if multiple operations for the same group is scheduled
    /// they will be queued and executed in sequence.
    ///
    /// This is used for operations where ordering is important. For example when sending a commit to add client to a group, this is a two-step operations:
    ///
    /// 1. Create pending commit and send to distribution server
    /// 2. Merge pending commit when accepted by distribution server
    ///
    /// Here's it's critical that no other operation like `decryptMessage` is performed
    /// between step 1 and 2. We enforce this by wrapping all `decrypt` and `commit` operations
    /// inside `performNonReentrant`
    /// 
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
                if continuations.isNonEmpty {
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

    public func addMembers(_ invitees: [KeyPackage], to groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        try await performNonReentrant(groupID: groupID) {
            do {
                WireLogger.mls.info("adding members to group (\(groupID.safeForLoggingDescription))...")
                let bundle = try await commitBundle(for: .addMembers(invitees), in: groupID)
                let result = try await commitSender.sendCommitBundle(bundle, for: groupID)
                WireLogger.mls.info("success: adding members to group (\(groupID.safeForLoggingDescription))")
                return result
            } catch {
                WireLogger.mls.info("failed: adding members to group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
                throw error
            }
        }
    }

    public func removeClients(_ clients: [ClientId], from groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        try await performNonReentrant(groupID: groupID) {
            do {
                WireLogger.mls.info("removing clients from group (\(groupID.safeForLoggingDescription))...")
                let bundle = try await commitBundle(for: .removeClients(clients), in: groupID)
                let result = try await commitSender.sendCommitBundle(bundle, for: groupID)
                WireLogger.mls.info("success: removing clients from group (\(groupID.safeForLoggingDescription))")
                return result
            } catch {
                WireLogger.mls.info("error: removing clients from group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
                throw error
            }
        }
    }

    public func updateKeyMaterial(for groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        try await performNonReentrant(groupID: groupID) {
            do {
                WireLogger.mls.info("updating key material for group (\(groupID.safeForLoggingDescription))...")
                let bundle = try await commitBundle(for: .updateKeyMaterial, in: groupID)
                let result = try await commitSender.sendCommitBundle(bundle, for: groupID)
                WireLogger.mls.info("success: updating key material for group (\(groupID.safeForLoggingDescription))")
                return result
            } catch {
                WireLogger.mls.info("error: updating key material for group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
                throw error
            }
        }
    }

    public func commitPendingProposals(in groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        try await performNonReentrant(groupID: groupID) {
            do {
                WireLogger.mls.info("committing pending proposals for group (\(groupID.safeForLoggingDescription))...")
                let bundle = try await commitBundle(for: .proposal, in: groupID)
                let result = try await commitSender.sendCommitBundle(bundle, for: groupID)
                WireLogger.mls.info("success: committing pending proposals for group (\(groupID.safeForLoggingDescription))")
                return result
            } catch CommitError.noPendingProposals {
                throw CommitError.noPendingProposals
            } catch {
                WireLogger.mls.info("error: committing pending proposals for group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
                throw error
            }
        }
    }

    public func joinGroup(_ groupID: MLSGroupID, groupInfo: Data) async throws -> [ZMUpdateEvent] {
        try await performNonReentrant(groupID: groupID) {
            do {
                WireLogger.mls.info("joining group (\(groupID.safeForLoggingDescription)) via external commit")
                let bundle = try await commitBundle(for: .joinGroup(groupInfo), in: groupID)
                let result = try await commitSender.sendExternalCommitBundle(bundle, for: groupID)
                WireLogger.mls.info("success: joining group (\(groupID.safeForLoggingDescription)) via external commit")
                return result
            } catch {
                WireLogger.mls.info("error: joining group (\(groupID.safeForLoggingDescription)) via external commit: \(String(describing: error))")
                throw error
            }
        }
    }

    // MARK: - Decryption

    public func decryptMessage(_ message: Data, in groupID: MLSGroupID) async throws -> DecryptedMessage {
        try await performNonReentrant(groupID: groupID) {
            try await coreCrypto.perform {
                try await $0.decryptMessage(conversationId: groupID.data, payload: message)
            }
        }
    }

    // MARK: - Commit generation

    private func commitBundle(for action: Action, in groupID: MLSGroupID) async throws -> CommitBundle {
        do {
            WireLogger.mls.info("generating commit for action (\(String(describing: action))) for group (\(groupID.safeForLoggingDescription))...")
            switch action {
            case .addMembers(let clients):
                let memberAddMessages = try await coreCrypto.perform {
                    try await $0.addClientsToConversation(
                        conversationId: groupID.data,
                        keyPackages: clients.compactMap(\.keyPackage.base64DecodedData)
                    )
                }

                return CommitBundle(
                    welcome: memberAddMessages.welcome,
                    commit: memberAddMessages.commit,
                    groupInfo: memberAddMessages.groupInfo
                )

            case .removeClients(let clients):
                return try await coreCrypto.perform {
                    try await $0.removeClientsFromConversation(
                        conversationId: groupID.data,
                        clients: clients
                    )
                }

            case .updateKeyMaterial:
                return try await coreCrypto.perform {
                    try await $0.updateKeyingMaterial(conversationId: groupID.data)
                }

            case .proposal:
                guard let bundle = try await coreCrypto.perform({
                    do {
                        return try await $0.commitPendingProposals(conversationId: groupID.data)
                    } catch {
                        // if we already have a pending commit `commitPendingProposals()` will fail
                        // and we must first clear it in order to generate the commit again.
                        try? await $0.clearPendingCommit(conversationId: groupID.data)
                        return try await $0.commitPendingProposals(conversationId: groupID.data)
                    }
                }) else {
                    throw CommitError.noPendingProposals
                }

                return bundle

            case .joinGroup(let groupInfo):
                let conversationInitBundle = try await coreCrypto.perform {
                    try await $0.joinByExternalCommit(
                        groupInfo: groupInfo,
                        customConfiguration: .init(keyRotationSpan: nil, wirePolicy: nil),
                        credentialType: .basic
                    )
                }

                return CommitBundle(
                    welcome: nil,
                    commit: conversationInitBundle.commit,
                    groupInfo: conversationInitBundle.groupInfo
                )
            }
        } catch CommitError.noPendingProposals {
            throw CommitError.noPendingProposals
        } catch {
            WireLogger.mls.warn("failed: generating commit for action (\(String(describing: action))) for group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
            throw CommitError.failedToGenerateCommit
        }
    }

    // MARK: - Epoch publisher

    nonisolated
    public func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        commitSender.onEpochChanged()
    }
}

extension MLSActionExecutor.Action: CustomDebugStringConvertible {

    var debugDescription: String {
        switch self {
        case .addMembers:
            return "addMembers"

        case .removeClients:
            return "removeClients"

        case .updateKeyMaterial:
            return "updateKeyMaterial"

        case .proposal:
            return "proposal"

        case .joinGroup:
            return "joinGroup"
        }
    }

}
