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

extension UpdateEventDecodingProxy {
    init(
        eventType: ConversationEventType,
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(keyedBy: ConversationEventCodingKeys.self)

        switch eventType {
        case .accessUpdate:
            let event = try ConversationAccessUpdateEventDecoder().decode(from: container)
            updateEvent = .conversation(.accessUpdate(event))

        case .codeUpdate:
            let event = try ConversationCodeUpdateEventDecoder().decode(from: container)
            updateEvent = .conversation(.codeUpdate(event))

        case .create:
            let event = try ConversationCreateEventDecoder().decode(from: container)
            updateEvent = .conversation(.create(event))

        case .delete:
            let event = try ConversationDeleteEventDecoder().decode(from: container)
            updateEvent = .conversation(.delete(event))

        case .memberJoin:
            let event = try ConversationMemberJoinEventDecoder().decode(from: container)
            updateEvent = .conversation(.memberJoin(event))

        case .memberLeave:
            let event = try ConversationMemberLeaveEventDecoder().decode(from: container)
            updateEvent = .conversation(.memberLeave(event))

        case .memberUpdate:
            let event = try ConversationMemberUpdateEventDecoder().decode(from: container)
            updateEvent = .conversation(.memberUpdate(event))

        case .messageTimerUpdate:
            let event = try ConversationMessageTimerUpdateEventDecoder().decode(from: container)
            updateEvent = .conversation(.messageTimerUpdate(event))

        case .mlsMessageAdd:
            let event = try ConversationMLSMessageAddEventDecoder().decode(from: container)
            updateEvent = .conversation(.mlsMessageAdd(event))

        case .mlsWelcome:
            let event = try ConversationMLSWelcomeEventDecoder().decode(from: container)
            updateEvent = .conversation(.mlsWelcome(event))

        case .otrMessageAdd:
            let event = try ConversationProteusMessageAddEventDecoder().decode(from: container)
            updateEvent = .conversation(.proteusMessageAdd(event))

        case .protocolUpdate:
            let event = try ConversationProtocolUpdateEventDecoder().decode(from: container)
            updateEvent = .conversation(.protocolUpdate(event))

        case .receiptModeUpdate:
            let event = try ConversationReceiptModeUpdateEventDecoder().decode(from: container)
            updateEvent = .conversation(.receiptModeUpdate(event))

        case .rename:
            let event = try ConversationRenameEventDecoder().decode(from: container)
            updateEvent = .conversation(.rename(event))

        case .typing:
            let event = try ConversationTypingEventDecoder().decode(from: container)
            updateEvent = .conversation(.typing(event))
        }
    }
}
