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

import WireAPI
import WireDataModel

struct ConversationAccessUpdateEventProcessor<Dependencies>: ConversationAccessUpdateEventProcessorProtocol
where Dependencies: ConversationAccessUpdateEventProcessorDependencies {

    let repository: ConversationRepository
    let localStore: ConversationLocalStore

    func processEvent(_ event: ConversationAccessUpdateEvent) async {
        let conversationID = event.conversationID

        let localConversation = await repository.fetchOrCreateConversation(
            id: conversationID.uuid,
            domain: conversationID.domain
        )

        let accessRoles = if let legacyAccessRole = event.legacyAccessRole {
            getAccessRoles(from: legacyAccessRole)
        } else {
            event.accessRoles ?? [.teamMember, .nonTeamMember, .service]
        }

        await localStore.updateAccesses(
            for: localConversation,
            accessModes: event.accessModes.map(\.rawValue),
            accessRoles: accessRoles.map(\.rawValue)
        )
    }

    private func getAccessRoles(
        from legacyRole: ConversationAccessRoleLegacy
    ) -> Set<WireAPI.ConversationAccessRole> {
        switch legacyRole {
        case .team:
            [.teamMember]
        case .activated:
            [.teamMember, .nonTeamMember, .guest]
        case .nonActivated:
            [.teamMember, .nonTeamMember, .guest, .service]
        case .private:
            []
        }
    }

}

protocol ConversationAccessUpdateEventProcessorDependencies {
    associatedtype ConversationRepository: ConversationRepositoryProtocol
    where ConversationRepository.ConversationEntity == ZMConversation
    associatedtype ConversationLocalStore: ConversationLocalStoreProtocol
}

extension ConversationAccessUpdateEventProcessor {
    typealias ConversationRepository = Dependencies.ConversationRepository
    typealias ConversationLocalStore = Dependencies.ConversationLocalStore
}
