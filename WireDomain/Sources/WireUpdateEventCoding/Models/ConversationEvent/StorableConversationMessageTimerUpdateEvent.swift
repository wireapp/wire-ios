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

import Foundation
import WireNetwork

struct StorableConversationMessageTimerUpdateEvent: Equatable, Codable, Sendable {

    private let conversationID: StorableQualifiedID
    private let senderID: StorableQualifiedID
    private let timestamp: Date
    private let newTimer: Int64?

    init(_ value: WireNetwork.ConversationMessageTimerUpdateEvent) {
        self.conversationID = StorableQualifiedID(value.conversationID)
        self.senderID = StorableQualifiedID(value.senderID)
        self.timestamp = value.timestamp
        self.newTimer = value.newTimer
    }

    func toAPIModel() -> WireNetwork.ConversationMessageTimerUpdateEvent {
        .init(
            conversationID: conversationID.toAPIModel(),
            senderID: senderID.toAPIModel(),
            timestamp: timestamp,
            newTimer: newTimer
        )
    }

}
