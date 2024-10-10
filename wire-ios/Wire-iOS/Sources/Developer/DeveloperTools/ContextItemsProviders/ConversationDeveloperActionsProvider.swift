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
import WireDataModel
import WireUtilities

struct ConversationDeveloperActionsProvider: DeveloperToolsContextItemsProvider {

    private typealias ButtonItem = DeveloperToolsViewModel.ButtonItem
    private let conversation: ZMConversation

    init?(context: DeveloperToolsContext) {
        guard let conversation = context.currentConversation else {
            return nil
        }
        self.conversation = conversation
    }
    
    func getActionItems() -> [DeveloperToolsViewModel.Item] {
        var items = [makeConversationIdItem()]

        if let groupIdItem = makeConversationGroupIdItem() {
            items.append(groupIdItem)
        }

        if DeveloperFlag.debugDuplicateObjects.isOn {
            items.append(makeDuplicateConversationItem())
        }

        if let toggleReadButton = makeToggleReadItem() {
            items.append(toggleReadButton)
        }

        return items
    }

    private func makeConversationGroupIdItem() -> DeveloperToolsViewModel.Item? {
        switch conversation.messageProtocol {
        case .mls, .mixed:
            return .text(DeveloperToolsViewModel.TextItem(
                title: "Conversation ID",
                value: conversation.remoteIdentifier.uuidString
            ))
        default:
            return nil
        }
    }

    private func makeConversationIdItem() -> DeveloperToolsViewModel.Item {
        .text(DeveloperToolsViewModel.TextItem(
            title: "Conversation ID",
            value: conversation.remoteIdentifier.uuidString
        ))
    }

    private func makeDuplicateConversationItem() -> DeveloperToolsViewModel.Item {
        .button(ButtonItem(
            title: "Duplicate Conversation",
            action: { Task { await duplicateConversation() } }
        ))
    }

    private func makeToggleReadItem() -> DeveloperToolsViewModel.Item? {
        if conversation.unreadMessages.count > 0 {
            return .button(ButtonItem(
                title: "Mark as read",
                action: { Task { await markAsRead() } }
            ))
        } else if conversation.unreadMessages.count == 0 && conversation.canMarkAsUnread() {
            return .button(ButtonItem(
                title: "Mark as unread",
                action: { Task { await markAsUnread() } }
            ))
        }

        return nil
    }

    @MainActor
    private func markAsRead() async {
        guard let context = conversation.managedObjectContext?.zm_sync else {
            return
        }

        await context.perform {
            guard let conversation = ZMConversation.existingObject(for: conversation.objectID, in: context) else {
                return
            }

            conversation.markAsRead()
        }
    }

    @MainActor
    private func markAsUnread() async {
        guard let context = conversation.managedObjectContext?.zm_sync else {
            return
        }

        await context.perform {
            guard let conversation = ZMConversation.existingObject(for: conversation.objectID, in: context) else {
                return
            }

            conversation.markAsUnread()
        }
    }

    @MainActor
    private func duplicateConversation() async {
        guard let context = conversation.managedObjectContext?.zm_sync else {
            return
        }

        await context.perform {
            guard let original = ZMConversation.existingObject(for: conversation.objectID, in: context) else {
                return
            }
            let duplicate = ZMConversation.insertNewObject(in: context)
            duplicate.remoteIdentifier = original.remoteIdentifier
            duplicate.domain = original.domain
            duplicate.nonTeamRoles = original.nonTeamRoles
            duplicate.creator = original.creator
            duplicate.conversationType = original.conversationType
            duplicate.participantRoles = original.participantRoles

            context.saveOrRollback()

            WireLogger.conversation.debug("duplicate conversation \(String(describing: original.qualifiedID?.safeForLoggingDescription))")
        }
    }

}
