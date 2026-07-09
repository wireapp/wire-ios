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
import WireFoundation

/// Bridges `WireDomain`'s `ConversationRepositoryProtocol` into `WireCallingDomain`'s
/// `MeetingConversationRepositoryProtocol`, so the meetings feature can pull meeting
/// conversations and add participants (including MLS group establishment) without
/// depending on `WireDomain` directly.
struct MeetingConversationRepositoryBridge: MeetingConversationRepositoryProtocol, @unchecked Sendable {

    let conversationRepository: any ConversationRepositoryProtocol
    let contextProvider: any ContextProvider

    func pullConversation(id: UUID, domain: String) async throws {
        try await conversationRepository.pullConversation(id: id, domain: domain)
    }

    func addParticipants(
        _ participants: [MeetingMember],
        to conversationID: WireFoundation.QualifiedID
    ) async throws {
        guard !participants.isEmpty else { return }

        guard let conversation = await conversationRepository.fetchConversation(
            id: conversationID.id,
            domain: conversationID.domain
        ) else { return }

        let objectID = conversation.objectID
        let syncContext = contextProvider.syncContext

        let mlsGroupID = await syncContext.perform {
            guard
                let conv = ZMConversation.existingObject(for: objectID, in: syncContext),
                conv.messageProtocol == .mls
            else { return nil as MLSGroupID? }
            return conv.mlsGroupID
        }

        guard let mlsGroupID else { return }

        try await addMLSParticipants(
            participants,
            to: mlsGroupID,
            conversationObjectID: objectID,
            syncContext: syncContext,
            mlsService: syncContext.performAndWait { syncContext.mlsService }
        )
    }

    // Establishes the local CoreCrypto group and adds all users in one commit.
    // Using establishGroup (not createGroup + addMembers separately) avoids the
    // mls-client-mismatch 409, which happens when the self user's other devices
    // aren't included in the initial group state before a separate add commit.
    private func addMLSParticipants(
        _ participants: [MeetingMember],
        to mlsGroupID: MLSGroupID,
        conversationObjectID objectID: NSManagedObjectID,
        syncContext: NSManagedObjectContext,
        mlsService: (any MLSServiceInterface)?
    ) async throws {
        guard let mlsService else { return }

        let mlsUsers = participants.map { member in
            MLSUser(id: member.qualifiedID.id, domain: member.qualifiedID.domain)
        }

        let ciphersuite = try await mlsService.establishGroup(
            for: mlsGroupID,
            with: mlsUsers,
            removalKeys: nil
        )

        await syncContext.perform {
            guard let conv = ZMConversation.existingObject(for: objectID, in: syncContext) else { return }
            conv.mlsStatus = .ready
            conv.ciphersuite = ciphersuite
            _ = syncContext.saveOrRollback()
        }
    }

}
