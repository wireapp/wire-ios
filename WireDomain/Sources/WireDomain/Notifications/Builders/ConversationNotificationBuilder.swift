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

struct ConversationNotificationBuilder: NotificationBuilder {
    private let event: ConversationEvent
    private let builder: NotificationBuilder
    
    init(event: ConversationEvent) {
        self.event = event
        self.builder = switch event {
        case .mlsMessageAdd(let conversationMLSMessageAddEvent):
            fatalError()
        case .proteusMessageAdd(let conversationProteusMessageAddEvent):
            fatalError()
        default:
            fatalError() // TODO: Implement me
        }
    }
    
    func shouldBuildNotification() -> Bool {
        builder.shouldBuildNotification()
    }
    
    func buildContent() -> UNMutableNotificationContent {
        let notificationContent = builder.buildContent()
        
        return notificationContent
    }
    
}
