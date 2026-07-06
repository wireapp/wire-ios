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

    @MainActor
    func addParticipants(_ participants: [WireCallingDomain.Member], to conversationID: WireCallingDomain.QualifiedID) async throws {
        guard !participants.isEmpty,
              let session = ZMUserSession.shared() else { return }

        guard let conversation = await conversationRepository.fetchConversation(
            id: conversationID.id,
            domain: conversationID.domain
        ) else { return }

        let objectID = conversation.objectID
        let syncContext = session.syncContext

        // Mirror CreateGroupConversationUseCase.setupMLS: create the local CoreCrypto group
        // before adding members, otherwise CoreCrypto throws "Couldn't find conversation".
        try await createMLSGroupIfNeeded(objectID: objectID, syncContext: syncContext)

        let users = await syncContext.perform {
            participants.compactMap { member in
                ZMUser.fetch(with: member.qualifiedID.id, domain: member.qualifiedID.domain, in: syncContext)
            }
        }

        guard !users.isEmpty else { return }

        let syncConversation = try await syncContext.perform {
            try ZMConversation.existingObject(for: objectID, in: syncContext)
        }

        let service = ConversationParticipantsService(
            context: syncContext,
            localDomain: session.resolvedBackendMetadata.domain
        )
        try await service.addParticipants(users, to: syncConversation)
    }

    private func createMLSGroupIfNeeded(
        objectID: NSManagedObjectID,
        syncContext: NSManagedObjectContext
    ) async throws {
        let mlsGroupID = await syncContext.perform {
            guard
                let conv = try? ZMConversation.existingObject(for: objectID, in: syncContext),
                conv.messageProtocol == .mls
            else { return nil as MLSGroupID? }
            return conv.mlsGroupID
        }

        guard let mlsGroupID else { return }

        let mlsService = await syncContext.perform { syncContext.mlsService }
        guard let mlsService else { return }

        let ciphersuite = try await mlsService.createGroup(for: mlsGroupID, removalKeys: nil)

        await syncContext.perform {
            guard let conv = try? ZMConversation.existingObject(for: objectID, in: syncContext) else { return }
            conv.mlsStatus = .ready
            conv.ciphersuite = ciphersuite
            _ = syncContext.saveOrRollback()
        }
    }
}
