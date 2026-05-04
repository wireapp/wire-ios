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

import WireDataModel
import WireNetwork

/// An extension that encapsulates storage operations related to MLS.

extension ConversationLocalStore {

    // MARK: - Update message protocols

    func assignMessageProtocol(
        from conversation: Conversation,
        for localConversation: ZMConversation
    ) {
        guard let newMessageProtocol = conversation.messageProtocol else {
            eventProcessingLogger.warn(
                "message protocol is missing"
            )
            return
        }

        localConversation.messageProtocol = newMessageProtocol
    }

    func updateMessageProtocol(
        from conversation: Conversation,
        for localConversation: ZMConversation
    ) {
        guard let newMessageProtocol = conversation.messageProtocol else {
            eventProcessingLogger.warn(
                "message protocol is missing"
            )
            return
        }

        let sender = ZMUser.selfUser(in: context)

        switch localConversation.messageProtocol {
        case .proteus:
            switch newMessageProtocol {
            case .proteus:
                break /// no update, ignore
            case .mixed:
                localConversation.appendMLSMigrationStartedSystemMessage(sender: sender, at: .now)
                localConversation.messageProtocol = newMessageProtocol

            case .mls:
                let date = localConversation.lastModifiedDate ?? .now

                localConversation.appendMLSMigrationPotentialGapSystemMessage(
                    sender: sender, at: date
                )

                localConversation.messageProtocol = newMessageProtocol
            }

        case .mixed:
            switch newMessageProtocol {
            case .proteus:
                updateEventLogger.warn(
                    "update message protocol from \(localConversation.messageProtocol) to \(newMessageProtocol) is not allowed, ignore event!"
                )

            case .mixed:
                break /// no update, ignore
            case .mls:
                localConversation.appendMLSMigrationFinalizedSystemMessageIfNeeded(sender: sender, at: .now)
                localConversation.messageProtocol = newMessageProtocol
            }

        case .mls:
            switch newMessageProtocol {
            case .proteus, .mixed:
                updateEventLogger.warn(
                    "update message protocol from '\(localConversation.messageProtocol)' to '\(newMessageProtocol)' is not allowed, ignore event!"
                )

            case .mls:
                break
            }
        }
    }

    // MARK: - Self MLS Conversation

    func createOrJoinSelfConversation(
        from localConversation: ZMConversation
    ) async throws {
        let (groupID, mlsService, hasRegisteredMLSClient) = await context.perform { [context] in
            (
                localConversation.mlsGroupID,
                context.mlsService,
                ZMUser.selfUser(in: context).selfClient()?.hasRegisteredMLSClient == true
            )
        }

        guard let groupID, let mlsService, hasRegisteredMLSClient else {
            mlsLogger.warn(
                "no mlsService or not registered mls client to createOrJoinSelfConversation"
            )
            return
        }

        mlsLogger.debug(
            "createOrJoinSelfConversation for \(groupID.safeForLoggingDescription); conv payload: \(String(describing: self))"
        )

        if await context.perform({ localConversation.epoch <= 0 }) {
            let ciphersuite = try await mlsService.createSelfGroup(
                for: groupID
            )

            await context.perform {
                localConversation.ciphersuite = ciphersuite
            }

        } else if try await !mlsService.conversationExists(groupID: groupID) {
            try await mlsService.joinGroup(with: groupID)
        }
    }

}
