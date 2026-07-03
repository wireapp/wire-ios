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

import Foundation
import WireCallingDomain
import WireDataModel
import WireDomain
import WireSyncEngine

struct MeetingConversationRepository: MeetingConversationRepositoryProtocol {

    var conversationRepository: any ConversationRepositoryProtocol

    func pullConversation(id: UUID, domain: String) async throws {
        try await conversationRepository.pullConversation(id: id, domain: domain)
    }

    func addParticipants(_ participants: [WireCallingDomain.Member], to conversationID: WireCallingDomain.QualifiedID) async throws {
        guard !participants.isEmpty,
              let session = ZMUserSession.shared() else { return }

        guard let conversation = await conversationRepository.fetchConversation(
            id: conversationID.id,
            domain: conversationID.domain
        ) else { return }

        let syncContext = session.syncContext
        let users = await syncContext.perform {
            participants.compactMap { member in
                ZMUser.fetch(with: member.qualifiedID.id, domain: member.qualifiedID.domain, in: syncContext)
            }
        }

        guard !users.isEmpty else { return }

        let objectID = conversation.objectID
        let syncConversation = try await syncContext.perform {
            try ZMConversation.existingObject(for: objectID, in: syncContext)
        }

        let service = ConversationParticipantsService(
            context: syncContext,
            localDomain: session.resolvedBackendMetadata.domain
        )
        try await service.addParticipants(users, to: syncConversation)
    }
}
