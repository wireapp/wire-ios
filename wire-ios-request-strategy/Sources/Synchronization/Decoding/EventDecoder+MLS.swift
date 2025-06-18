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

import Foundation
import WireLogging

extension EventDecoder {

    enum Failure: Error {
        case missingMLSGroupID
    }

    func processWelcomeMessage(
        from updateEvent: ZMUpdateEvent,
        context: NSManagedObjectContext
    ) async {
        guard let decryptionService = await context.perform({ context.mlsDecryptionService }) else {
            WireLogger.mls.critical("failed to decrypt mls message: mlsDecyptionService is missing")
            fatalError("failed to decrypt mls message: mlsService is missing")
        }

        let decoder = EventPayloadDecoder()

        do {
            let payload = try decoder.decode(Payload.UpdateConversationMLSWelcome.self, from: updateEvent.payload)
            let groupID = try await decryptionService.processWelcomeMessage(welcomeMessage: payload.data, context: nil)
            await context.perform {
                let conversation = ZMConversation.fetchOrCreate(
                    with: payload.id,
                    domain: payload.qualifiedID?.domain,
                    in: context
                )
                conversation.remoteIdentifier = payload.qualifiedID?.uuid
                conversation.domain = payload.qualifiedID?.domain
                conversation.mlsGroupID = groupID
                conversation.mlsStatus = .ready
                context.saveOrRollback()
            }
        } catch {
            WireLogger.mls.warn("failed to decrypt mls welcome message: \(String(describing: error))")
            return
        }
    }

    func decryptMlsMessage(
        from updateEvent: ZMUpdateEvent,
        context: NSManagedObjectContext
    ) async throws -> [ZMUpdateEvent] {
        guard !DeveloperFlag.skipMLSMessagesDecryption.isOn else { return [] }

        WireLogger.mls.info("decrypting mls message", attributes: updateEvent.logAttributes)

        guard let decryptionService = await context.perform({ context.mlsDecryptionService }) else {
            WireLogger.mls.critical(
                "failed to decrypt mls message: mlsDecyptionService is missing",
                attributes: updateEvent.logAttributes
            )
            fatalError("failed to decrypt mls message: mlsService is missing")
        }

        let decoder = EventPayloadDecoder()
        let payload = try decoder.decode(
            Payload.UpdateConversationMLSMessageAdd.self,
            from: updateEvent.payload
        )

        var conversation: ZMConversation?
        let groupID: MLSGroupID? = await context.perform {
            conversation = ZMConversation.fetch(with: payload.id, domain: payload.qualifiedID?.domain, in: context)

            guard let conversation else {
                WireLogger.mls.error(
                    "failed to decrypt mls message: conversation not found in db",
                    attributes: updateEvent.logAttributes
                )
                return nil
            }

            guard conversation.mlsStatus == .ready else {
                WireLogger.mls
                    .warn(
                        "failed to decrypt mls message: conversation is not ready (status: \(String(describing: conversation.mlsStatus)))",
                        attributes: updateEvent.logAttributes
                    )
                return nil
            }

            return conversation.mlsGroupID
        }

        guard let groupID else {
            throw Failure.missingMLSGroupID
        }

        let results = try await decryptionService.decrypt(
            message: payload.data,
            for: groupID,
            subconversationType: payload.subconversationType,
            context: nil
        )

        if results.isEmpty {
            WireLogger.mls.info(
                "successfully decrypted mls message but no result was returned",
                attributes: updateEvent.logAttributes
            )
            return []
        }

        var events = [ZMUpdateEvent]()
        for result in results {

            switch result {
            case let .message(decryptedData, senderClientID):
                if let event = updateEvent.decryptedMLSEvent(
                    decryptedData: decryptedData,
                    senderClientID: senderClientID
                ) {
                    events.append(event)
                }

            case let .proposal(commitDelay):
                let scheduledDate = (updateEvent.timestamp ?? Date()) + TimeInterval(commitDelay)
                await context.perform {
                    conversation?.commitPendingProposalDate = scheduledDate
                }
            }
        }

        if let mlsService = await context.perform({ context.mlsService }),
           updateEvent.source == .webSocket {
            Task.detached { [mlsService] in
                // we don't need to wait for this, as it can take a while to finish
                // it should not block decryption
                await mlsService.commitPendingProposalsIfNeeded()
            }
        }

        return events
    }

}
