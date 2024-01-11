//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

public struct ConversationPostProtocolChangeUpdater {

    public init() { }

    public func updateLocalConversation(
        for qualifiedID: QualifiedID,
        to newMessageProtocol: MessageProtocol,
        context: NSManagedObjectContext
    ) async throws {
        let conversation = await context.perform {
            ZMConversation.fetch(
                with: qualifiedID.uuid,
                domain: qualifiedID.domain,
                in: context
            )
        }

        guard let conversation else {
            assertionFailure("can not fetch conversation with qualifiedID \(qualifiedID)!")
            return
        }

        try await updateLocalConversation(
            conversation,
            qualifiedID: qualifiedID,
            to: newMessageProtocol,
            context: context
        )
    }

    public func updateLocalConversation(
        _ conversation: ZMConversation,
        qualifiedID: QualifiedID,
        to newMessageProtocol: MessageProtocol,
        context: NSManagedObjectContext
    ) async throws {
        // get current messageProtocol before syncing conversation
        let messageProtocol = await context.perform { conversation.messageProtocol }

        try await syncConversation(qualifiedID, in: context.notificationContext)

        if messageProtocol == newMessageProtocol {
            // skip adding system message for equal protocols!
            return
        }

        await context.perform {
            let selfUser = ZMUser.selfUser(in: context)
            self.addProtocolChangeSystemMessage(
                conversation: conversation,
                newMessageProtocol: newMessageProtocol,
                user: selfUser
            )
        }
    }

    // MARK: - Helpers

    private func syncConversation(_ qualifiedID: QualifiedID, in notificationContext: NotificationContext) async throws {
        var action = SyncConversationAction(qualifiedID: qualifiedID)

        do {
            try await action.perform(in: notificationContext)
        } catch {
            Logging.eventProcessing.error("syncConversation: perform 'SyncConversationAction' failed with error: \(error)")
            throw error
        }
    }

    private func addProtocolChangeSystemMessage(
        conversation: ZMConversation,
        newMessageProtocol: MessageProtocol,
        user: ZMUser
    ) {
        let now = Date()

        switch newMessageProtocol {
        case .mixed:
            conversation.appendMLSMigrationStartedSystemMessage(
                sender: user,
                at: now
            )
        case .mls:
            conversation.appendMLSMigrationFinalizedSystemMessage(
                sender: user,
                at: now
            )
        case .proteus:
            assertionFailure("unexpected value for 'messageProtocol' '\(String(describing: newMessageProtocol))', that can not be processed!")
        }

    }
}
