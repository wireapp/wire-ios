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

/// An extension that encapsulates storage operations related to conversation group (user, role, members).

extension ConversationLocalStore {

    // MARK: - User & Role

    func fetchUserAndRole(
        from remoteConversationMember: WireAPI.Conversation.Member,
        for localConversation: ZMConversation
    ) -> (user: ZMUser, role: Role?)? {
        guard let userID = remoteConversationMember.id ?? remoteConversationMember.qualifiedID?.uuid else {
            return nil
        }

        let user = ZMUser.fetchOrCreate(
            with: userID,
            domain: remoteConversationMember.qualifiedID?.domain,
            in: context
        )

        func fetchOrCreateRoleForConversation(
            name: String,
            conversation: ZMConversation
        ) -> Role {
            Role.fetchOrCreateRole(
                with: name,
                teamOrConversation: .matching(conversation),
                in: context
            )
        }

        let role = remoteConversationMember.conversationRole.map {
            fetchOrCreateRoleForConversation(name: $0, conversation: localConversation)
        }

        return (user, role)
    }

    // MARK: - Members

    func updateMembers(
        from remoteConversation: WireAPI.Conversation,
        for localConversation: ZMConversation
    ) {
        guard let members = remoteConversation.members else {
            return
        }

        let otherMembers = members.others.compactMap {
            fetchUserAndRole(
                from: $0,
                for: localConversation
            )
        }

        let selfUserRole = fetchUserAndRole(
            from: members.selfMember,
            for: localConversation
        )?.role

        localConversation.updateMembers(otherMembers, selfUserRole: selfUserRole)
    }

    // MARK: - 1:1

    func linkOneOnOneUserIfNeeded(
        for localConversation: ZMConversation
    ) {
        guard
            localConversation.conversationType == .oneOnOne,
            let otherUser = localConversation.localParticipantsExcludingSelf.first,
            otherUser.oneOnOneConversation == nil
        else {
            return
        }

        localConversation.oneOnOneUser = otherUser
    }

}
