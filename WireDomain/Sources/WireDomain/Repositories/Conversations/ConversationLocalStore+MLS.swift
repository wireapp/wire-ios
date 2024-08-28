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

/// An extension that encapsulates storage work related to conversation MLS.

extension ConversationLocalStore {

    // MARK: - Message protocols

    func assignMessageProtocol(
        from payload: WireAPI.Conversation,
        for conversation: ZMConversation
    ) {
        guard let newMessageProtocol = payload.messageProtocol else {
            return
        }

        conversation.messageProtocol = newMessageProtocol.toDomainModel()
    }

    func updateMessageProtocol(
        from payload: WireAPI.Conversation,
        for conversation: ZMConversation
    ) {
        guard let newMessageProtocol = payload.messageProtocol else {
            return
        }

        let sender = ZMUser.selfUser(in: context)

        switch conversation.messageProtocol {
        case .proteus:
            switch newMessageProtocol {
            case .proteus:
                break /// no update, ignore
            case .mixed:
                conversation.appendMLSMigrationStartedSystemMessage(sender: sender, at: .now)
                conversation.messageProtocol = newMessageProtocol.toDomainModel()

            case .mls:
                let date = conversation.lastModifiedDate ?? .now
                conversation.appendMLSMigrationPotentialGapSystemMessage(sender: sender, at: date)
                conversation.messageProtocol = newMessageProtocol.toDomainModel()
            }

        case .mixed:
            switch newMessageProtocol {
            case .proteus, .mixed:
                break /// no update, ignore
            case .mls:
                conversation.appendMLSMigrationFinalizedSystemMessage(sender: sender, at: .now)
                conversation.messageProtocol = newMessageProtocol.toDomainModel()
            }

        case .mls:
            switch newMessageProtocol {
            case .proteus, .mixed, .mls:
                break
            }
        }
    }

    // MARK: - Self / MLS

    func createOrJoinSelfConversation(
        from conversation: ZMConversation
    ) async throws {
        guard let context = conversation.managedObjectContext else {
            return
        }

        let (groupID, mlsService, hasRegisteredMLSClient) = await context.perform {
            (
                conversation.mlsGroupID,
                context.mlsService,
                ZMUser.selfUser(in: context).selfClient()?.hasRegisteredMLSClient == true
            )
        }

        guard let groupID, let mlsService, hasRegisteredMLSClient else {
            return
        }

        if await context.perform({ conversation.epoch <= 0 }) {
            let ciphersuite = try await mlsService.createSelfGroup(for: groupID)
            await context.perform { conversation.ciphersuite = ciphersuite }
        } else if try await !mlsService.conversationExists(groupID: groupID) {
            try await mlsService.joinGroup(with: groupID)
        }
    }
}
