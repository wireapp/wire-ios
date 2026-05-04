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
    case mlsReset(StorableConversationMLSResetEvent)

    init(_ value: WireNetwork.ConversationEvent) {
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
        case let .mlsReset(event):
            self = .mlsReset(StorableConversationMLSResetEvent(event))
        }
    }

    func toAPIModel() -> WireNetwork.ConversationEvent {
        switch self {
        case let .accessUpdate(event):
            .accessUpdate(event.toAPIModel())
        case let .codeUpdate(event):
            .codeUpdate(event.toAPIModel())
        case let .create(event):
            .create(event.toAPIModel())
        case let .delete(event):
            .delete(event.toAPIModel())
        case let .memberJoin(event):
            .memberJoin(event.toAPIModel())
        case let .memberLeave(event):
            .memberLeave(event.toAPIModel())
        case let .memberUpdate(event):
            .memberUpdate(event.toAPIModel())
        case let .messageTimerUpdate(event):
            .messageTimerUpdate(event.toAPIModel())
        case let .mlsMessageAdd(event):
            .mlsMessageAdd(event.toAPIModel())
        case let .mlsWelcome(event):
            .mlsWelcome(event.toAPIModel())
        case let .proteusMessageAdd(event):
            .proteusMessageAdd(event.toAPIModel())
        case let .protocolUpdate(event):
            .protocolUpdate(event.toAPIModel())
        case let .receiptModeUpdate(event):
            .receiptModeUpdate(event.toAPIModel())
        case let .rename(event):
            .rename(event.toAPIModel())
        case let .typing(event):
            .typing(event.toAPIModel())
        case let .permissionUpdate(event):
            .permissionUpdate(event.toAPIModel())
        case let .mlsReset(event):
            .mlsReset(event.toAPIModel())
        }
    }

}
