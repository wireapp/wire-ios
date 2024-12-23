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
import Foundation

extension ConversationEvent {
    var senderID: UserID {
        switch self {
        case .accessUpdate(let conversationAccessUpdateEvent):
            return conversationAccessUpdateEvent.senderID
        case .codeUpdate(let conversationCodeUpdateEvent):
            return conversationCodeUpdateEvent.senderID
        case .create(let conversationCreateEvent):
            return conversationCreateEvent.senderID
        case .delete(let conversationDeleteEvent):
            return conversationDeleteEvent.senderID
        case .memberJoin(let conversationMemberJoinEvent):
            return conversationMemberJoinEvent.senderID
        case .memberLeave(let conversationMemberLeaveEvent):
            return conversationMemberLeaveEvent.senderID
        case .memberUpdate(let conversationMemberUpdateEvent):
            return conversationMemberUpdateEvent.senderID
        case .messageTimerUpdate(let conversationMessageTimerUpdateEvent):
            return conversationMessageTimerUpdateEvent.senderID
        case .mlsMessageAdd(let conversationMLSMessageAddEvent):
            return conversationMLSMessageAddEvent.senderID
        case .mlsWelcome(let conversationMLSWelcomeEvent):
            return conversationMLSWelcomeEvent.senderID
        case .proteusMessageAdd(let conversationProteusMessageAddEvent):
            return conversationProteusMessageAddEvent.senderID
        case .protocolUpdate(let conversationProtocolUpdateEvent):
            return conversationProtocolUpdateEvent.senderID
        case .receiptModeUpdate(let conversationReceiptModeUpdateEvent):
            return conversationReceiptModeUpdateEvent.senderID
        case .rename(let conversationRenameEvent):
            return conversationRenameEvent.senderID
        case .typing(let conversationTypingEvent):
            return conversationTypingEvent.senderID
        }
    }
    
    var conversationID: WireAPI.QualifiedID {
        switch self {
        case .accessUpdate(let conversationAccessUpdateEvent):
            return conversationAccessUpdateEvent.conversationID
        case .codeUpdate(let conversationCodeUpdateEvent):
            return conversationCodeUpdateEvent.conversationID
        case .create(let conversationCreateEvent):
            return conversationCreateEvent.conversationID
        case .delete(let conversationDeleteEvent):
            return conversationDeleteEvent.conversationID
        case .memberJoin(let conversationMemberJoinEvent):
            return conversationMemberJoinEvent.conversationID
        case .memberLeave(let conversationMemberLeaveEvent):
            return conversationMemberLeaveEvent.conversationID
        case .memberUpdate(let conversationMemberUpdateEvent):
            return conversationMemberUpdateEvent.conversationID
        case .messageTimerUpdate(let conversationMessageTimerUpdateEvent):
            return conversationMessageTimerUpdateEvent.conversationID
        case .mlsMessageAdd(let conversationMLSMessageAddEvent):
            return conversationMLSMessageAddEvent.conversationID
        case .mlsWelcome(let conversationMLSWelcomeEvent):
            return conversationMLSWelcomeEvent.conversationID
        case .proteusMessageAdd(let conversationProteusMessageAddEvent):
            return conversationProteusMessageAddEvent.conversationID
        case .protocolUpdate(let conversationProtocolUpdateEvent):
            return conversationProtocolUpdateEvent.conversationID
        case .receiptModeUpdate(let conversationReceiptModeUpdateEvent):
            return conversationReceiptModeUpdateEvent.conversationID
        case .rename(let conversationRenameEvent):
            return conversationRenameEvent.conversationID
        case .typing(let conversationTypingEvent):
            return conversationTypingEvent.conversationID
        }
    }
    
    var timestamp: Date? {
        switch self {
        case .create(let conversationCreateEvent):
            return conversationCreateEvent.timestamp
        case .delete(let conversationDeleteEvent):
            return conversationDeleteEvent.timestamp
        case .memberJoin(let conversationMemberJoinEvent):
            return conversationMemberJoinEvent.timestamp
        case .memberLeave(let conversationMemberLeaveEvent):
            return conversationMemberLeaveEvent.timestamp
        case .memberUpdate(let conversationMemberUpdateEvent):
            return conversationMemberUpdateEvent.timestamp
        case .messageTimerUpdate(let conversationMessageTimerUpdateEvent):
            return conversationMessageTimerUpdateEvent.timestamp
        case .mlsMessageAdd(let conversationMLSMessageAddEvent):
            return conversationMLSMessageAddEvent.timestamp
        case .proteusMessageAdd(let conversationProteusMessageAddEvent):
            return conversationProteusMessageAddEvent.timestamp
        case .rename(let conversationRenameEvent):
            return conversationRenameEvent.timestamp
        default:
            return nil
        }
    }
}
