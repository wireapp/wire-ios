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

extension ConversationEvent {
    var senderID: UserID {
        switch self {
        case let .accessUpdate(event):
            event.senderID
        case let .codeUpdate(event):
            event.senderID
        case let .create(event):
            event.senderID
        case let .delete(event):
            event.senderID
        case let .memberJoin(event):
            event.senderID
        case let .memberLeave(event):
            event.senderID
        case let .memberUpdate(event):
            event.senderID
        case let .messageTimerUpdate(event):
            event.senderID
        case let .mlsMessageAdd(event):
            event.senderID
        case let .mlsWelcome(event):
            event.senderID
        case let .proteusMessageAdd(event):
            event.senderID
        case let .protocolUpdate(event):
            event.senderID
        case let .receiptModeUpdate(event):
            event.senderID
        case let .rename(event):
            event.senderID
        case let .typing(event):
            event.senderID
        case let .permissionUpdate(event):
            event.senderID
        case let .mlsReset(event):
            event.senderID
        }
    }

    var conversationID: WireNetwork.QualifiedID {
        switch self {
        case let .accessUpdate(event):
            event.conversationID
        case let .codeUpdate(event):
            event.conversationID
        case let .create(event):
            event.conversationID
        case let .delete(event):
            event.conversationID
        case let .memberJoin(event):
            event.conversationID
        case let .memberLeave(event):
            event.conversationID
        case let .memberUpdate(event):
            event.conversationID
        case let .messageTimerUpdate(event):
            event.conversationID
        case let .mlsMessageAdd(event):
            event.conversationID
        case let .mlsWelcome(event):
            event.conversationID
        case let .proteusMessageAdd(event):
            event.conversationID
        case let .protocolUpdate(event):
            event.conversationID
        case let .receiptModeUpdate(event):
            event.conversationID
        case let .rename(event):
            event.conversationID
        case let .typing(event):
            event.conversationID
        case let .permissionUpdate(event):
            event.conversationID
        case let .mlsReset(event):
            event.conversationID
        }
    }

    var timestamp: Date? {
        switch self {
        case let .create(event):
            event.timestamp
        case let .delete(event):
            event.timestamp
        case let .memberJoin(event):
            event.timestamp
        case let .memberLeave(event):
            event.timestamp
        case let .memberUpdate(event):
            event.timestamp
        case let .messageTimerUpdate(event):
            event.timestamp
        case let .mlsMessageAdd(event):
            event.timestamp
        case let .proteusMessageAdd(event):
            event.timestamp
        case let .rename(event):
            event.timestamp
        default:
            nil
        }
    }
}
