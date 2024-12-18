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
import UserNotifications

struct ConversationNotificationBuilder {
    let event: ConversationEvent
    
    init(event: ConversationEvent) {
        self.event = event
    }
    
    func build() -> UNMutableNotificationContent {
        switch event {
        case .mlsMessageAdd(let conversationMLSMessageAddEvent):
            
        case .proteusMessageAdd(let conversationProteusMessageAddEvent):
            
        case .accessUpdate(let conversationAccessUpdateEvent):
            UNMutableNotificationContent()
        case .codeUpdate(let conversationCodeUpdateEvent):
            UNMutableNotificationContent()
        case .create(let conversationCreateEvent):
            UNMutableNotificationContent()
        case .delete(let conversationDeleteEvent):
            UNMutableNotificationContent()
        case .memberJoin(let conversationMemberJoinEvent):
            UNMutableNotificationContent()
        case .memberLeave(let conversationMemberLeaveEvent):
            UNMutableNotificationContent()
        case .memberUpdate(let conversationMemberUpdateEvent):
            UNMutableNotificationContent()
        case .messageTimerUpdate(let conversationMessageTimerUpdateEvent):
            UNMutableNotificationContent()
        case .mlsWelcome(let conversationMLSWelcomeEvent):
            UNMutableNotificationContent()
        case .protocolUpdate(let conversationProtocolUpdateEvent):
            UNMutableNotificationContent()
        case .receiptModeUpdate(let conversationReceiptModeUpdateEvent):
            UNMutableNotificationContent()
        case .rename(let conversationRenameEvent):
            UNMutableNotificationContent()
        case .typing(let conversationTypingEvent):
            UNMutableNotificationContent()
        }
    }
    
}
