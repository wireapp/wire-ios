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

/// Process conversation update events.

protocol ConversationEventProcessorProtocol {

    /// Process a conversation update event.
    ///
    /// Processing an event is the app's only chance to consume
    /// some remote changes to update its local state.
    ///
    /// - Parameter event: A conversation update event.

    func processEvent(_ event: ConversationEvent) async throws

}

struct ConversationEventProcessor {

    let accessUpdateEventProcessor: any ConversationAccessUpdateEventProcessorProtocol
    let codeUpdateEventProcessor: any ConversationCodeUpdateEventProcessorProtocol
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

    func processEvent(_ event: ConversationEvent) async throws {
        switch event {
        case .accessUpdate(let event):
            try await accessUpdateEventProcessor.processEvent(event)

        case .codeUpdate(let event):
            try await codeUpdateEventProcessor.processEvent(event)

        case .create(let event):
            try await createEventProcessor.processEvent(event)

        case .delete(let event):
            try await deleteEventProcessor.processEvent(event)

        case .memberJoin(let event):
            try await memberJoinEventProcessor.processEvent(event)

        case .memberLeave(let event):
            try await memberLeaveEventProcessor.processEvent(event)

        case .memberUpdate(let event):
            try await memberUpdateEventProcessor.processEvent(event)

        case .messageTimerUpdate(let event):
            try await messageTimerUpdateEventProcessor.processEvent(event)

        case .mlsMessageAdd(let event):
            try await mlsMessageAddEventProcessor.processEvent(event)

        case .mlsWelcome(let event):
            try await mlsWelcomeEventProcessor.processEvent(event)

        case .proteusMessageAdd(let event):
            try await proteusMessageAddEventProcessor.processEvent(event)

        case .protocolUpdate(let event):
            try await protocolUpdateEventProcessor.processEvent(event)

        case .receiptModeUpdate(let event):
            try await receiptModeUpdateEventProcessor.processEvent(event)

        case .rename(let event):
            try await renameEventProcessor.processEvent(event)

        case .typing(let event):
            try await typingEventProcessor.processEvent(event)
        }
    }

}
