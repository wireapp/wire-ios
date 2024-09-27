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

// MARK: - ConversationEventProcessorProtocol

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

// MARK: - ConversationEventProcessor

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
        case let .accessUpdate(event):
            try await accessUpdateEventProcessor.processEvent(event)

        case let .codeUpdate(event):
            try await codeUpdateEventProcessor.processEvent(event)

        case let .create(event):
            try await createEventProcessor.processEvent(event)

        case let .delete(event):
            try await deleteEventProcessor.processEvent(event)

        case let .memberJoin(event):
            try await memberJoinEventProcessor.processEvent(event)

        case let .memberLeave(event):
            try await memberLeaveEventProcessor.processEvent(event)

        case let .memberUpdate(event):
            try await memberUpdateEventProcessor.processEvent(event)

        case let .messageTimerUpdate(event):
            try await messageTimerUpdateEventProcessor.processEvent(event)

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
            try await typingEventProcessor.processEvent(event)
        }
    }
}
