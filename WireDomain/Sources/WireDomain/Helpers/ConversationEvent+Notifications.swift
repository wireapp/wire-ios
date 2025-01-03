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

import Foundation
import WireAPI

extension ConversationEvent {
    var senderID: UserID {
        switch self {
        case let .accessUpdate(conversationAccessUpdateEvent):
            conversationAccessUpdateEvent.senderID
        case let .codeUpdate(conversationCodeUpdateEvent):
            conversationCodeUpdateEvent.senderID
        case let .create(conversationCreateEvent):
            conversationCreateEvent.senderID
        case let .delete(conversationDeleteEvent):
            conversationDeleteEvent.senderID
        case let .memberJoin(conversationMemberJoinEvent):
            conversationMemberJoinEvent.senderID
        case let .memberLeave(conversationMemberLeaveEvent):
            conversationMemberLeaveEvent.senderID
        case let .memberUpdate(conversationMemberUpdateEvent):
            conversationMemberUpdateEvent.senderID
        case let .messageTimerUpdate(conversationMessageTimerUpdateEvent):
            conversationMessageTimerUpdateEvent.senderID
        case let .mlsMessageAdd(conversationMLSMessageAddEvent):
            conversationMLSMessageAddEvent.senderID
        case let .mlsWelcome(conversationMLSWelcomeEvent):
            conversationMLSWelcomeEvent.senderID
        case let .proteusMessageAdd(conversationProteusMessageAddEvent):
            conversationProteusMessageAddEvent.senderID
        case let .protocolUpdate(conversationProtocolUpdateEvent):
            conversationProtocolUpdateEvent.senderID
        case let .receiptModeUpdate(conversationReceiptModeUpdateEvent):
            conversationReceiptModeUpdateEvent.senderID
        case let .rename(conversationRenameEvent):
            conversationRenameEvent.senderID
        case let .typing(conversationTypingEvent):
            conversationTypingEvent.senderID
        }
    }

    var conversationID: WireAPI.QualifiedID {
        switch self {
        case let .accessUpdate(conversationAccessUpdateEvent):
            conversationAccessUpdateEvent.conversationID
        case let .codeUpdate(conversationCodeUpdateEvent):
            conversationCodeUpdateEvent.conversationID
        case let .create(conversationCreateEvent):
            conversationCreateEvent.conversationID
        case let .delete(conversationDeleteEvent):
            conversationDeleteEvent.conversationID
        case let .memberJoin(conversationMemberJoinEvent):
            conversationMemberJoinEvent.conversationID
        case let .memberLeave(conversationMemberLeaveEvent):
            conversationMemberLeaveEvent.conversationID
        case let .memberUpdate(conversationMemberUpdateEvent):
            conversationMemberUpdateEvent.conversationID
        case let .messageTimerUpdate(conversationMessageTimerUpdateEvent):
            conversationMessageTimerUpdateEvent.conversationID
        case let .mlsMessageAdd(conversationMLSMessageAddEvent):
            conversationMLSMessageAddEvent.conversationID
        case let .mlsWelcome(conversationMLSWelcomeEvent):
            conversationMLSWelcomeEvent.conversationID
        case let .proteusMessageAdd(conversationProteusMessageAddEvent):
            conversationProteusMessageAddEvent.conversationID
        case let .protocolUpdate(conversationProtocolUpdateEvent):
            conversationProtocolUpdateEvent.conversationID
        case let .receiptModeUpdate(conversationReceiptModeUpdateEvent):
            conversationReceiptModeUpdateEvent.conversationID
        case let .rename(conversationRenameEvent):
            conversationRenameEvent.conversationID
        case let .typing(conversationTypingEvent):
            conversationTypingEvent.conversationID
        }
    }

    var timestamp: Date? {
        switch self {
        case let .create(conversationCreateEvent):
            conversationCreateEvent.timestamp
        case let .delete(conversationDeleteEvent):
            conversationDeleteEvent.timestamp
        case let .memberJoin(conversationMemberJoinEvent):
            conversationMemberJoinEvent.timestamp
        case let .memberLeave(conversationMemberLeaveEvent):
            conversationMemberLeaveEvent.timestamp
        case let .memberUpdate(conversationMemberUpdateEvent):
            conversationMemberUpdateEvent.timestamp
        case let .messageTimerUpdate(conversationMessageTimerUpdateEvent):
            conversationMessageTimerUpdateEvent.timestamp
        case let .mlsMessageAdd(conversationMLSMessageAddEvent):
            conversationMLSMessageAddEvent.timestamp
        case let .proteusMessageAdd(conversationProteusMessageAddEvent):
            conversationProteusMessageAddEvent.timestamp
        case let .rename(conversationRenameEvent):
            conversationRenameEvent.timestamp
        default:
            nil
        }
    }
}
