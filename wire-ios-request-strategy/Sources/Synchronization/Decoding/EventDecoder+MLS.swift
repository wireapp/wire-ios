//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

extension EventDecoder {

    func decryptMlsMessage(
        from updateEvent: ZMUpdateEvent,
        context: NSManagedObjectContext
    ) -> ZMUpdateEvent? {
        Logging.mls.info("decrypting mls message")

        guard let decryptionService = context.mlsDecryptionService else {
            WireLogger.mls.warn("failed to decrypt mls message: mlsDecyptionService is missing, maybe apiV5 not available")
            return nil
        }

        guard let payload = updateEvent.eventPayload(type: Payload.UpdateConversationMLSMessageAdd.self) else {
            WireLogger.mls.error("failed to decrypt mls message: invalid update event payload")
            return nil
        }

        guard let conversation = ZMConversation.fetch(with: payload.id, domain: payload.qualifiedID?.domain, in: context) else {
            WireLogger.mls.error("failed to decrypt mls message: conversation not found in db")
            return nil
        }

        guard conversation.mlsStatus == .ready else {
            WireLogger.mls.warn("failed to decrypt mls message: conversation is not ready (status: \(String(describing: conversation.mlsStatus)))")
            return nil
        }

        guard let groupID = conversation.mlsGroupID else {
            WireLogger.mls.error("failed to decrypt mls message: missing MLS group ID")
            return nil
        }

        do {
            guard
                let result = try decryptionService.decrypt(
                    message: payload.data,
                    for: groupID,
                    subconversationType: payload.subconversationType
                )
            else {
                WireLogger.mls.info("successfully decrypted mls message but no result was returned")
                return nil
            }

            switch result {
            case .message(let decryptedData, let senderClientID):
                return updateEvent.decryptedMLSEvent(decryptedData: decryptedData, senderClientID: senderClientID)

            case .proposal(let commitDelay):
                let scheduledDate = (updateEvent.timestamp ?? Date()) + TimeInterval(commitDelay)
                conversation.commitPendingProposalDate = scheduledDate

                if let mlsService = context.mlsService, updateEvent.source == .webSocket {
                    Task {
                        do {
                            try await mlsService.commitPendingProposals()
                        } catch {
                            WireLogger.mls.error("failed to commit pending proposals: \(String(describing: error))")
                        }
                    }
                }

                return nil
            }

        } catch {
            Logging.mls.warn("failed to decrypt mls message: \(String(describing: error))")
            return nil
        }
    }

}
