//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

struct ConversationAccessUpdateEventProcessor: ConversationAccessUpdateEventProcessorProtocol {

    let repository: any ConversationRepositoryProtocol
    let localStore: any ConversationLocalStoreProtocol

    func processEvent(_ event: ConversationAccessUpdateEvent) async {
        let conversationID = event.conversationID

        let localConversation = await repository.fetchOrCreateConversation(
            id: conversationID.id,
            domain: conversationID.domain
        )

        let accessRoles = if let legacyAccessRole = event.legacyAccessRole {
            getAccessRoles(from: legacyAccessRole)
        } else {
            event.accessRoles ?? [.teamMember, .nonTeamMember, .app]
        }

        await localStore.updateAccesses(
            for: localConversation,
            accessModes: event.accessModes.map { $0.toDataModel() },
            accessRoles: accessRoles.map { $0.toDataModel() }
        )
    }

    private func getAccessRoles(
        from legacyRole: ConversationAccessRoleLegacy
    ) -> Set<ConversationAccessRole> {
        switch legacyRole {
        case .team:
            [.teamMember]
        case .activated:
            [.teamMember, .nonTeamMember, .guest]
        case .nonActivated:
            [.teamMember, .nonTeamMember, .guest, .app]
        case .private:
            []
        }
    }

}

private extension WireNetwork.ConversationAccessMode {
    func toDataModel() -> String {
        switch self {
        case .private:
            "private"
        case .invite:
            "invite"
        case .link:
            "link"
        case .code:
            "code"
        }
    }
}

private extension WireNetwork.ConversationAccessRole {
    func toDataModel() -> String {
        switch self {
        case .teamMember:
            "team_member"
        case .nonTeamMember:
            "non_team_member"
        case .guest:
            "guest"
        case .app:
            "service"
        }
    }
}
