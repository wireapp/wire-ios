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

import WireAPI
import WireDataModel

/// An extension that encapsulates storage work related to conversation group (user, role, members).

extension ConversationLocalStore {

    // MARK: - User & Role

    func fetchUserAndRole(
        from payload: WireAPI.Conversation.Member,
        for conversation: ZMConversation
    ) -> (ZMUser, Role?)? {
        guard let userID = payload.id ?? payload.qualifiedID?.uuid else {
            return nil
        }

        let user = ZMUser.fetchOrCreate(
            with: userID,
            domain: payload.qualifiedID?.domain,
            in: context
        )

        func fetchOrCreateRoleForConversation(
            name: String,
            conversation: ZMConversation
        ) -> Role {
            Role.fetchOrCreateRole(
                with: name,
                teamOrConversation: conversation.team != nil ? .team(conversation.team!) : .conversation(conversation),
                in: context
            )
        }

        let role = payload.conversationRole.map {
            fetchOrCreateRoleForConversation(name: $0, conversation: conversation)
        }

        return (user, role)
    }

    // MARK: - Members

    func updateMembers(
        from payload: WireAPI.Conversation,
        for conversation: ZMConversation
    ) {
        guard let members = payload.members else {
            return
        }

        let otherMembers = members.others.compactMap {
            fetchUserAndRole(
                from: $0,
                for: conversation
            )
        }

        let selfUserRole = fetchUserAndRole(
            from: members.selfMember,
            for: conversation
        )?.1

        conversation.updateMembers(otherMembers, selfUserRole: selfUserRole)
    }

    // MARK: 1:1

    func linkOneOnOneUserIfNeeded(
        for conversation: ZMConversation
    ) {
        guard
            conversation.conversationType == .oneOnOne,
            let otherUser = conversation.localParticipantsExcludingSelf.first
        else {
            return
        }

        conversation.oneOnOneUser = otherUser
    }

}
