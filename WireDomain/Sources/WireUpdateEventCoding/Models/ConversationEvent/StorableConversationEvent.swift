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
import WireAPI

enum StorableConversationEvent: Equatable, Codable, Sendable {

    case accessUpdate(StorableConversationAccessUpdateEvent)
    case codeUpdate(StorableConversationCodeUpdateEvent)
    case create(StorableConversationCreateEvent)
    case delete(StorableConversationDeleteEvent)
    case memberJoin(StorableConversationMemberJoinEvent)
    case memberLeave(StorableConversationMemberLeaveEvent)
    case memberUpdate(StorableConversationMemberUpdateEvent)
    case messageTimerUpdate(StorableConversationMessageTimerUpdateEvent)
    case mlsMessageAdd(StorableConversationMLSMessageAddEvent)
    case mlsWelcome(StorableConversationMLSWelcomeEvent)
    case proteusMessageAdd(StorableConversationProteusMessageAddEvent)
    case protocolUpdate(StorableConversationProtocolUpdateEvent)
    case receiptModeUpdate(StorableConversationReceiptModeUpdateEvent)
    case rename(StorableConversationRenameEvent)
    case typing(StorableConversationTypingEvent)
    case permissionUpdate(StorableConversationAddPermissionEvent)

    init(_ value: WireAPI.ConversationEvent) {
        switch value {
        case let .accessUpdate(event):
            self = .accessUpdate(StorableConversationAccessUpdateEvent(event))
        case let .codeUpdate(event):
            self = .codeUpdate(StorableConversationCodeUpdateEvent(event))
        case let .create(event):
            self = .create(StorableConversationCreateEvent(event))
        case let .delete(event):
            self = .delete(StorableConversationDeleteEvent(event))
        case let .memberJoin(event):
            self = .memberJoin(StorableConversationMemberJoinEvent(event))
        case let .memberLeave(event):
            self = .memberLeave(StorableConversationMemberLeaveEvent(event))
        case let .memberUpdate(event):
            self = .memberUpdate(StorableConversationMemberUpdateEvent(event))
        case let .messageTimerUpdate(event):
            self = .messageTimerUpdate(StorableConversationMessageTimerUpdateEvent(event))
        case let .mlsMessageAdd(event):
            self = .mlsMessageAdd(StorableConversationMLSMessageAddEvent(event))
        case let .mlsWelcome(event):
            self = .mlsWelcome(StorableConversationMLSWelcomeEvent(event))
        case let .proteusMessageAdd(event):
            self = .proteusMessageAdd(StorableConversationProteusMessageAddEvent(event))
        case let .protocolUpdate(event):
            self = .protocolUpdate(StorableConversationProtocolUpdateEvent(event))
        case let .receiptModeUpdate(event):
            self = .receiptModeUpdate(StorableConversationReceiptModeUpdateEvent(event))
        case let .rename(event):
            self = .rename(StorableConversationRenameEvent(event))
        case let .typing(event):
            self = .typing(StorableConversationTypingEvent(event))
        case let .permissionUpdate(event):
            self = .permissionUpdate(StorableConversationAddPermissionEvent(event))
        }
    }

    func toAPIModel() -> WireAPI.ConversationEvent {
        switch self {
        case let .accessUpdate(event):
            return .accessUpdate(event.toAPIModel())
        case let .codeUpdate(event):
            return .codeUpdate(event.toAPIModel())
        case let .create(event):
            return .create(event.toAPIModel())
        case let .delete(event):
            return .delete(event.toAPIModel())
        case let .memberJoin(event):
            return .memberJoin(event.toAPIModel())
        case let .memberLeave(event):
            return .memberLeave(event.toAPIModel())
        case let .memberUpdate(event):
            return .memberUpdate(event.toAPIModel())
        case let .messageTimerUpdate(event):
            return .messageTimerUpdate(event.toAPIModel())
        case let .mlsMessageAdd(event):
            return .mlsMessageAdd(event.toAPIModel())
        case let .mlsWelcome(event):
            return .mlsWelcome(event.toAPIModel())
        case let .proteusMessageAdd(event):
            return .proteusMessageAdd(event.toAPIModel())
        case let .protocolUpdate(event):
            return .protocolUpdate(event.toAPIModel())
        case let .receiptModeUpdate(event):
            return .receiptModeUpdate(event.toAPIModel())
        case let .rename(event):
            return .rename(event.toAPIModel())
        case let .typing(event):
            return .typing(event.toAPIModel())
        case let .permissionUpdate(event):
            return .permissionUpdate(event.toAPIModel())
        }
    }

}
