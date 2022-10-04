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

protocol MLSActionExecutorProtocol {

    func addMembers(_ invitees: [Invitee], to groupID: MLSGroupID) async throws -> [ZMUpdateEvent]
    func removeClients(_ clients: [ClientId], from groupID: MLSGroupID) async throws -> [ZMUpdateEvent]
    func updateKeyMaterial(for groupID: MLSGroupID) async throws -> [ZMUpdateEvent]
    func commitPendingProposals(in groupID: MLSGroupID) async throws -> [ZMUpdateEvent]

}

actor MLSActionExecutor: MLSActionExecutorProtocol {

    // MARK: - Types

    enum Action {

        case addMembers([Invitee])
        case removeClients([ClientId])
        case updateKeyMaterial
        case proposal

    }

    enum MLSActionExecutorError: Error {

        case failedToGenerateCommit
        case failedToSendCommit
        case failedToSendWelcome
        case failedToMergeCommit
        case failedToClearCommit
        case noPendingProposals

    }

    // MARK: - Properties

    private let coreCrypto: CoreCryptoProtocol
    private let context: NSManagedObjectContext
    private let actionsProvider: MLSActionsProviderProtocol

    // MARK: - Life cycle

    init(
        coreCrypto: CoreCryptoProtocol,
        context: NSManagedObjectContext,
        actionsProvider: MLSActionsProviderProtocol = MLSActionsProvider()
    ) {
        self.coreCrypto = coreCrypto
        self.context = context
        self.actionsProvider = actionsProvider
    }

    // MARK: - Actions

    func addMembers(_ invitees: [Invitee], to groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        let bundle = try commitBundle(for: .addMembers(invitees), in: groupID)
        return try await sendCommitBundle(bundle, for: groupID)
    }

    func removeClients(_ clients: [ClientId], from groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        let bundle = try commitBundle(for: .removeClients(clients), in: groupID)
        return try await sendCommitBundle(bundle, for: groupID)
    }

    func updateKeyMaterial(for groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        let bundle = try commitBundle(for: .updateKeyMaterial, in: groupID)
        return try await sendCommitBundle(bundle, for: groupID)
    }

    func commitPendingProposals(in groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        let bundle = try commitBundle(for: .proposal, in: groupID)
        return try await sendCommitBundle(bundle, for: groupID)
    }

    // MARK: - Commit generation

    private func commitBundle(for action: Action, in groupID: MLSGroupID) throws -> CommitBundle {
        do {
            switch action {
            case .addMembers(let clients):
                let memberAddMessages = try coreCrypto.wire_addClientsToConversation(
                    conversationId: groupID.bytes,
                    clients: clients
                )

                return CommitBundle(
                    welcome: memberAddMessages.welcome,
                    commit: memberAddMessages.commit,
                    publicGroupState: memberAddMessages.publicGroupState
                )

            case .removeClients(let clients):
                return try coreCrypto.wire_removeClientsFromConversation(
                    conversationId: groupID.bytes,
                    clients: clients
                )

            case .updateKeyMaterial:
                return try coreCrypto.wire_updateKeyingMaterial(conversationId: groupID.bytes)

            case .proposal:
                guard let bundle = try coreCrypto.wire_commitPendingProposals(
                    conversationId: groupID.bytes
                ) else {
                    throw MLSActionExecutorError.noPendingProposals
                }

                return bundle
            }
        } catch {
            throw MLSActionExecutorError.failedToGenerateCommit
        }
    }

    // MARK: - Sending messages

    private func sendCommitBundle(_ bundle: CommitBundle, for groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        do {
            let events = try await sendCommit(bundle.commit)
            try mergeCommit(in: groupID)

            if let welcome = bundle.welcome {
                try await sendWelcome(welcome)
            }

            return events

        } catch MLSActionExecutorError.failedToSendCommit {
            // TODO: [John] implement proper error handling
            //try clearPendingCommit(in: groupID)
            throw MLSActionExecutorError.failedToSendCommit
        }
    }


    private func sendCommit(_ bytes: Bytes) async throws -> [ZMUpdateEvent] {
        var events = [ZMUpdateEvent]()

        do {
            events = try await actionsProvider.sendMessage(
                bytes.data,
                in: context.notificationContext
            )
        } catch {
            throw MLSActionExecutorError.failedToSendCommit
        }

        return events
    }

    private func sendWelcome(_ message: Bytes) async throws {
        do {
            try await actionsProvider.sendWelcomeMessage(
                message.data,
                in: context.notificationContext
            )
        } catch {
            throw MLSActionExecutorError.failedToSendWelcome
        }
    }

    // MARK: - Post sending

    private func mergeCommit(in groupID: MLSGroupID) throws {
        do {
            try coreCrypto.wire_commitAccepted(conversationId: groupID.bytes)
        } catch {
            throw MLSActionExecutorError.failedToMergeCommit
        }
    }

    private func clearPendingCommit(in groupID: MLSGroupID) throws {
        do {
            try coreCrypto.wire_clearPendingCommit(conversationId: groupID.bytes)
        } catch {
            throw MLSActionExecutorError.failedToClearCommit
        }
    }

}
