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

import WireLogging
import WireNetwork

struct ConversationEventProcessor: ConversationEventProcessorProtocol {

    let accessUpdateEventProcessor: any ConversationAccessUpdateEventProcessorProtocol
    let createEventProcessor: any ConversationCreateEventProcessorProtocol
    let deleteEventProcessor: any ConversationDeleteEventProcessorProtocol
    let memberJoinEventProcessor: any ConversationMemberJoinEventProcessorProtocol
    let memberLeaveEventProcessor: any ConversationMemberLeaveEventProcessorProtocol
    let memberUpdateEventProcessor: any ConversationMemberUpdateEventProcessorProtocol
    let messageTimerUpdateEventProcessor: any ConversationMessageTimerUpdateEventProcessorProtocol
    let mlsMessageAddEventProcessor: any ConversationMLSMessageAddEventProcessorProtocol
    let mlsWelcomeEventProcessor: any ConversationMLSWelcomeEventProcessorProtocol
    let proteusMessageAddEventProcessor: any ConversationProteusMessageAddEventProcessorProtocol
    let protocolUpdateEventProcessor: any ConversationProtocolUpdateEventProcessorProtocol
    let receiptModeUpdateEventProcessor: any ConversationReceiptModeUpdateEventProcessorProtocol
    let renameEventProcessor: any ConversationRenameEventProcessorProtocol
    let typingEventProcessor: any ConversationTypingEventProcessorProtocol
    let addPermissionEventProcessor: any ConversationAddPermissionEventProcessorProtocol
    let mlsResetEventProcessor: any ConversationMLSResetEventProcessorProtocol

    func processEvent(_ event: ConversationEvent) async throws {
        WireLogger.eventProcessing.info(
            "process conversation event: \(event.name)",
            attributes: [.conversationId: event.conversationID.id.safeForLoggingDescription],
            .safePublic
        )

        switch event {
        case let .accessUpdate(event):
            await accessUpdateEventProcessor.processEvent(event)

        case .codeUpdate:
            // Event is not currently processed instead we fetch guest link on demand directly from API, see
            // `CreateConversationGuestLinkUseCase` and `CreateConversationGuestLinkActionHandler`
            break

        case let .create(event):
            await createEventProcessor.processEvent(event)

        case let .delete(event):
            try await deleteEventProcessor.processEvent(event)

        case let .memberJoin(event):
            try await memberJoinEventProcessor.processEvent(event)

        case let .memberLeave(event):
            try await memberLeaveEventProcessor.processEvent(event)

        case let .memberUpdate(event):
            try await memberUpdateEventProcessor.processEvent(event)

        case let .messageTimerUpdate(event):
            await messageTimerUpdateEventProcessor.processEvent(event)

        case let .mlsMessageAdd(event):
            try await mlsMessageAddEventProcessor.processEvent(event)

        case let .mlsWelcome(event):
            try await mlsWelcomeEventProcessor.processEvent(event)

        case let .proteusMessageAdd(event):
            try await proteusMessageAddEventProcessor.processEvent(event)

        case let .protocolUpdate(event):
            try await protocolUpdateEventProcessor.processEvent(event)

        case let .receiptModeUpdate(event):
            try await receiptModeUpdateEventProcessor.processEvent(event)

        case let .rename(event):
            try await renameEventProcessor.processEvent(event)

        case let .typing(event):
            await typingEventProcessor.processEvent(event)

        case let .permissionUpdate(event):
            await addPermissionEventProcessor.processEvent(event)
        // TODO: [WPB-18464] - process new event when backend ready, processor will properly map the duration to a localized string and pass it to the messageLocalStore.addSystemMessage(..)
//        case let .channelHistoryDepthModified(event):
//            await channelHistoryDepthModifiedProcessor.processEvent(event)

        case let .mlsReset(event):
            try await mlsResetEventProcessor.processEvent(event)
        }
    }

}
