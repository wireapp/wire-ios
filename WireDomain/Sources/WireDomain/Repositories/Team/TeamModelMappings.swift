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

import WireNetwork

extension WireNetwork.ConversationRole {

    func toDomainModel() -> TeamRoleInfo {
        .init(
            role: name,
            actions: actions.map(\.name)
        )
    }

}

extension WireNetwork.TeamMember {

    func toDomainModel() -> TeamMemberInfo {
        .init(
            id: userID,
            selfPermission: permissions?.selfPermissions,
            creatorID: creatorID,
            creationDate: creationDate
        )
    }

}

private extension WireNetwork.ConversationAction {

    var name: String {
        switch self {
        case .addConversationMember:
            "add_conversation_member"
        case .removeConversationMember:
            "remove_conversation_member"
        case .modifyConversationName:
            "modify_conversation_name"
        case .modifyConversationMessageTimer:
            "modify_conversation_message_timer"
        case .modifyConversationReceiptMode:
            "modify_conversation_receipt_mode"
        case .modifyConversationAccess:
            "modify_conversation_access"
        case .modifyOtherConversationMember:
            "modify_other_conversation_member"
        case .leaveConversation:
            "leave_conversation"
        case .deleteConversation:
            "delete_conversation"
        case .modifyAddPermission:
            "modify_add_permission"
        }
    }

}
