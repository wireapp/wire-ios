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

protocol MLSActionExecutorProtocol {

    func addMembers(_ invitees: [Invitee], to groupID: MLSGroupID) async throws -> [ZMUpdateEvent]
    func removeClients(_ clients: [ClientId], from groupID: MLSGroupID) async throws -> [ZMUpdateEvent]
    func updateKeyMaterial(for groupID: MLSGroupID) async throws -> [ZMUpdateEvent]
    func commitPendingProposals(in groupID: MLSGroupID) async throws -> [ZMUpdateEvent]
    func joinGroup(_ groupID: MLSGroupID, publicGroupState: Data) async throws -> [ZMUpdateEvent]

}

actor MLSActionExecutor: MLSActionExecutorProtocol {

    // MARK: - Types

    enum Action: CustomDebugStringConvertible {

        case addMembers([Invitee])
        case removeClients([ClientId])
        case updateKeyMaterial
        case proposal
        case joinGroup(Data)

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

    enum Error: Swift.Error, Equatable {

        // Commits
        case failedToGenerateCommit
        case failedToSendCommit(recovery: CommitErrorRecovery)
        case failedToMergeCommit
        case failedToClearCommit
        case noPendingProposals

        // External Commits
        case failedToSendExternalCommit(recovery: ExternalCommitErrorRecovery)
        case failedToMergePendingGroup
        case failedToClearPendingGroup

    }

    enum CommitErrorRecovery: Equatable {

        /// Perform a quick sync, then commit pending proposals.
        ///
        /// Core Crypto can automatically recover if it processes all
        /// incoming handshake messages. It will migrate any pending
        /// commits/proposals, which can then be committed as pending
        /// proposals.

        case commitPendingProposalsAfterQuickSync

        /// Perform a quick sync, then retry the action in its entirety.
        ///
        /// Core Crypto can not automatically recover by itself. It needs
        /// to process incoming handshake messages then generate a new commit.

        case retryAfterQuickSync

        /// Abort the action and inform the user.
        ///
        /// There is no way to automatically recover from the error.

        case giveUp

        /// Whether the pending commit should be discarded.

        var shouldDiscardCommit: Bool {
            switch self {
            case .commitPendingProposalsAfterQuickSync:
                return false

            case .retryAfterQuickSync, .giveUp:
                return true
            }
        }

    }

    enum ExternalCommitErrorRecovery {

        /// Retry the action from the beginning

        case retry

        /// Abort the action and log the error

        case giveUp

        /// Whether the pending group should be cleared

        var shouldClearPendingGroup: Bool {
            switch self {
            case .retry:
                return false

            case .giveUp:
                return true
            }
        }
    }

    // MARK: - Properties

    private let coreCrypto: SafeCoreCryptoProtocol
    private let context: NSManagedObjectContext
    private let actionsProvider: MLSActionsProviderProtocol

    // MARK: - Life cycle

    init(
        coreCrypto: SafeCoreCryptoProtocol,
        context: NSManagedObjectContext,
        actionsProvider: MLSActionsProviderProtocol = MLSActionsProvider()
    ) {
        self.coreCrypto = coreCrypto
        self.context = context
        self.actionsProvider = actionsProvider
    }

    // MARK: - Actions

    func addMembers(_ invitees: [Invitee], to groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        do {
            WireLogger.mls.info("adding members to group (\(groupID))...")
            let bundle = try commitBundle(for: .addMembers(invitees), in: groupID)
            let result = try await sendCommitBundle(bundle, for: groupID)
            WireLogger.mls.info("success: adding members to group (\(groupID))")
            return result
        } catch {
            WireLogger.mls.info("failed: adding members to group (\(groupID)): \(String(describing: error))")
            throw error
        }
    }

    func removeClients(_ clients: [ClientId], from groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        do {
            WireLogger.mls.info("removing clients from group (\(groupID))...")
            let bundle = try commitBundle(for: .removeClients(clients), in: groupID)
            let result = try await sendCommitBundle(bundle, for: groupID)
            WireLogger.mls.info("success: removing clients from group (\(groupID))")
            return result
        } catch {
            WireLogger.mls.info("error: removing clients from group (\(groupID)): \(String(describing: error))")
            throw error
        }
    }

    func updateKeyMaterial(for groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        do {
            WireLogger.mls.info("updating key material for group (\(groupID))...")
            let bundle = try commitBundle(for: .updateKeyMaterial, in: groupID)
            let result = try await sendCommitBundle(bundle, for: groupID)
            WireLogger.mls.info("success: updating key material for group (\(groupID))")
            return result
        } catch {
            WireLogger.mls.info("error: updating key material for group (\(groupID)): \(String(describing: error))")
            throw error
        }
    }

    func commitPendingProposals(in groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        do {
            WireLogger.mls.info("committing pending proposals for group (\(groupID))...")
            let bundle = try commitBundle(for: .proposal, in: groupID)
            let result = try await sendCommitBundle(bundle, for: groupID)
            WireLogger.mls.info("success: committing pending proposals for group (\(groupID))")
            return result
        } catch {
            WireLogger.mls.info("error: committing pending proposals for group (\(groupID)): \(String(describing: error))")
            throw error
        }
    }

    func joinGroup(_ groupID: MLSGroupID, publicGroupState: Data) async throws -> [ZMUpdateEvent] {
        do {
            WireLogger.mls.info("joining group (\(groupID)) via external commit")
            let bundle = try commitBundle(for: .joinGroup(publicGroupState), in: groupID)
            let result = try await sendExternalCommitBundle(bundle, for: groupID)
            WireLogger.mls.info("success: joining group (\(groupID)) via external commit")
            return result
        } catch {
            WireLogger.mls.info("error: joining group (\(groupID)) via external commit: \(String(describing: error))")
            throw error
        }
    }

    // MARK: - Commit generation

    private func commitBundle(for action: Action, in groupID: MLSGroupID) throws -> CommitBundle {
        do {
            WireLogger.mls.info("generating commit for action (\(String(describing: action))) for group (\(groupID))...")
            switch action {
            case .addMembers(let clients):
                let memberAddMessages = try coreCrypto.perform { try $0.addClientsToConversation(
                    conversationId: groupID.bytes,
                    clients: clients
                ) }

                return CommitBundle(
                    welcome: memberAddMessages.welcome,
                    commit: memberAddMessages.commit,
                    publicGroupState: memberAddMessages.publicGroupState
                )

            case .removeClients(let clients):
                return try coreCrypto.perform {
                    try $0.removeClientsFromConversation(
                        conversationId: groupID.bytes,
                        clients: clients
                    )
                }

            case .updateKeyMaterial:
                return try coreCrypto.perform {
                    try $0.updateKeyingMaterial(conversationId: groupID.bytes)
                }

            case .proposal:
                guard let bundle = try coreCrypto.perform({ try $0.commitPendingProposals(
                    conversationId: groupID.bytes
                ) }) else {
                    throw Error.noPendingProposals
                }

                return bundle

            case .joinGroup(let publicGroupState):
                let conversationInitBundle = try coreCrypto.perform { try $0.joinByExternalCommit(publicGroupState: publicGroupState.bytes,
                                                                                                  customConfiguration: .init(keyRotationSpan: nil, wirePolicy: nil), credentialType: .basic) }

                return CommitBundle(
                    welcome: nil,
                    commit: conversationInitBundle.commit,
                    publicGroupState: conversationInitBundle.publicGroupState
                )
            }
        } catch Error.noPendingProposals {
            throw Error.noPendingProposals
        } catch {
            WireLogger.mls.warn("failed: generating commit for action (\(String(describing: action))) for group (\(groupID)): \(String(describing: error))")
            throw Error.failedToGenerateCommit
        }
    }

    // MARK: - Sending messages

    private func sendCommitBundle(_ bundle: CommitBundle, for groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        do {
            let events = try await sendCommitBundle(bundle)
            try mergeCommit(in: groupID)
            return events
        } catch let error as SendCommitBundleAction.Failure {
            WireLogger.mls.warn("failed to send commit bundle: \(String(describing: error))")

            let recoveryStrategy = error.commitRecoveryStrategy

            if recoveryStrategy.shouldDiscardCommit {
                try discardPendingCommit(in: groupID)
            }

            throw MLSActionExecutor.Error.failedToSendCommit(recovery: recoveryStrategy)
        }
    }

    private func sendExternalCommitBundle(
        _ bundle: CommitBundle,
        for groupID: MLSGroupID
    ) async throws -> [ZMUpdateEvent] {
        do {
            let events = try await sendCommitBundle(bundle)
            try mergePendingGroup(in: groupID)
            return events
        } catch let error as SendCommitBundleAction.Failure {
            WireLogger.mls.warn("failed to send external commit bundle: \(String(describing: error))")

            let recoveryStrategy = error.externalCommitRecoveryStrategy

            if recoveryStrategy.shouldClearPendingGroup {
                try clearPendingGroup(in: groupID)
            }

            throw MLSActionExecutor.Error.failedToSendExternalCommit(recovery: recoveryStrategy)
        }
    }

    private func sendCommitBundle(_ bundle: CommitBundle) async throws -> [ZMUpdateEvent] {
        return try await actionsProvider.sendCommitBundle(
            try bundle.protobufData(),
            in: context.notificationContext
        )
    }

    // MARK: - Post sending

    private func mergeCommit(in groupID: MLSGroupID) throws {
        do {
            try coreCrypto.perform { try $0.commitAccepted(conversationId: groupID.bytes) }
        } catch {
            throw Error.failedToMergeCommit
        }
    }

    private func discardPendingCommit(in groupID: MLSGroupID) throws {
        do {
            try coreCrypto.perform { try $0.clearPendingCommit(conversationId: groupID.bytes) }
        } catch {
            throw Error.failedToClearCommit
        }
    }

    private func mergePendingGroup(in groupID: MLSGroupID) throws {
        do {
            try coreCrypto.perform {
                try $0.mergePendingGroupFromExternalCommit(
                    conversationId: groupID.bytes
                )
            }
        } catch {
            throw Error.failedToMergePendingGroup
        }
    }

    private func clearPendingGroup(in groupID: MLSGroupID) throws {
        do {
            try coreCrypto.perform {
                try $0.clearPendingGroupFromExternalCommit(conversationId: groupID.bytes)
            }
        } catch {
            throw Error.failedToClearPendingGroup
        }
    }
}

extension SendCommitBundleAction.Failure {

    var commitRecoveryStrategy: MLSActionExecutor.CommitErrorRecovery {
        switch self {
        case .mlsClientMismatch:
            return .retryAfterQuickSync

        case .mlsStaleMessage, .mlsCommitMissingReferences:
            return .commitPendingProposalsAfterQuickSync

        default:
            return .giveUp
        }
    }

    var externalCommitRecoveryStrategy: MLSActionExecutor.ExternalCommitErrorRecovery {
        switch self {
        case .mlsStaleMessage:
            return .retry

        default:
            return .giveUp
        }
    }

}
