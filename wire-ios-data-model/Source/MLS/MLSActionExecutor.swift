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

protocol MLSActionExecutorProtocol {

    func addMembers(_ invitees: [Invitee], to groupID: MLSGroupID) async throws -> [ZMUpdateEvent]
    func removeClients(_ clients: [ClientId], from groupID: MLSGroupID) async throws -> [ZMUpdateEvent]
    func updateKeyMaterial(for groupID: MLSGroupID) async throws -> [ZMUpdateEvent]
    func commitPendingProposals(in groupID: MLSGroupID) async throws -> [ZMUpdateEvent]
    func joinGroup(_ groupID: MLSGroupID, groupInfo: Data) async throws -> [ZMUpdateEvent]
    func onEpochChanged() -> AnyPublisher<MLSGroupID, Never>

}

actor MLSActionExecutor: MLSActionExecutorProtocol {

    // MARK: - Types

    enum Action {

        case addMembers([Invitee])
        case removeClients([ClientId])
        case updateKeyMaterial
        case proposal
        case joinGroup(Data)

    }

    // MARK: - Properties

    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private let commitSender: CommitSending

    private var coreCrypto: SafeCoreCryptoProtocol {
        get async throws {
            try await coreCryptoProvider.coreCrypto(requireMLS: true)
        }
    }

    // MARK: - Life cycle

    init(
        coreCryptoProvider: CoreCryptoProviderProtocol,
        commitSender: CommitSending
    ) {
        self.coreCryptoProvider = coreCryptoProvider
        self.commitSender = commitSender
    }

    // MARK: - Actions

    func addMembers(_ invitees: [Invitee], to groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        do {
            WireLogger.mls.info("adding members to group (\(groupID.safeForLoggingDescription))...")
            let bundle = try commitBundle(for: .addMembers(invitees), in: groupID)
            let result = try await commitSender.sendCommitBundle(bundle, for: groupID)
            WireLogger.mls.info("success: adding members to group (\(groupID.safeForLoggingDescription))")
            return result
        } catch {
            WireLogger.mls.info("failed: adding members to group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
            throw error
        }
    }

    func removeClients(_ clients: [ClientId], from groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        do {
            WireLogger.mls.info("removing clients from group (\(groupID.safeForLoggingDescription))...")
            let bundle = try commitBundle(for: .removeClients(clients), in: groupID)
            let result = try await commitSender.sendCommitBundle(bundle, for: groupID)
            WireLogger.mls.info("success: removing clients from group (\(groupID.safeForLoggingDescription))")
            return result
        } catch {
            WireLogger.mls.info("error: removing clients from group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
            throw error
        }
    }

    func updateKeyMaterial(for groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        do {
            WireLogger.mls.info("updating key material for group (\(groupID.safeForLoggingDescription))...")
            let bundle = try commitBundle(for: .updateKeyMaterial, in: groupID)
            let result = try await commitSender.sendCommitBundle(bundle, for: groupID)
            WireLogger.mls.info("success: updating key material for group (\(groupID.safeForLoggingDescription))")
            return result
        } catch {
            WireLogger.mls.info("error: updating key material for group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
            throw error
        }
    }

    func commitPendingProposals(in groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        do {
            WireLogger.mls.info("committing pending proposals for group (\(groupID.safeForLoggingDescription))...")
            let bundle = try commitBundle(for: .proposal, in: groupID)
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

    func joinGroup(_ groupID: MLSGroupID, groupInfo: Data) async throws -> [ZMUpdateEvent] {
        do {
            WireLogger.mls.info("joining group (\(groupID.safeForLoggingDescription)) via external commit")
            let bundle = try commitBundle(for: .joinGroup(groupInfo), in: groupID)
            let result = try await commitSender.sendExternalCommitBundle(bundle, for: groupID)
            WireLogger.mls.info("success: joining group (\(groupID.safeForLoggingDescription)) via external commit")
            return result
        } catch {
            WireLogger.mls.info("error: joining group (\(groupID.safeForLoggingDescription)) via external commit: \(String(describing: error))")
            throw error
        }
    }

    // MARK: - Commit generation

    private func commitBundle(for action: Action, in groupID: MLSGroupID) throws -> CommitBundle {
        do {
            WireLogger.mls.info("generating commit for action (\(String(describing: action))) for group (\(groupID.safeForLoggingDescription))...")
            switch action {
            case .addMembers(let clients):
                let memberAddMessages = try await coreCrypto.perform {
                    try $0.addClientsToConversation(
                        conversationId: groupID.bytes,
                        clients: clients
                    )
                }

                return CommitBundle(
                    welcome: memberAddMessages.welcome,
                    commit: memberAddMessages.commit,
                    groupInfo: memberAddMessages.groupInfo
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
                guard let bundle = try coreCrypto.perform({
                    try $0.commitPendingProposals(conversationId: groupID.bytes)
                }) else {
                    throw CommitError.noPendingProposals
                }

                return bundle

            case .joinGroup(let groupInfo):
                let conversationInitBundle = try coreCrypto.perform {
                    try $0.joinByExternalCommit(
                        groupInfo: groupInfo.bytes,
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
    func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
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
