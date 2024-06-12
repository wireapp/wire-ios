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

extension UpdateEvent {

    init(
        eventType: ConversationEventType,
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(keyedBy: ConversationEventCodingKeys.self)

        switch eventType {
        case .accessUpdate:
            let event = try ConversationAccessUpdateEventDecoder().decode(from: container)
            self = .conversation(.accessUpdate(event))

        case .codeUpdate:
            let event = try ConversationCodeUpdateEventDecoder().decode(from: container)
            self = .conversation(.codeUpdate(event))

        case .create:
            let event = try ConversationCreateEventDecoder().decode(from: container)
            self = .conversation(.create(event))

        case .delete:
            let event = try ConversationDeleteEventDecoder().decode(from: container)
            self = .conversation(.delete(event))

        case .memberJoin:
            let event = try ConversationMemberJoinEventDecoder().decode(from: container)
            self = .conversation(.memberJoin(event))

        case .memberLeave:
            let event = try ConversationMemberLeaveEventDecoder().decode(from: container)
            self = .conversation(.memberLeave(event))

        case .memberUpdate:
            self = .conversation(.memberUpdate)

        case .messageAdd:
            self = .conversation(.messageAdd)

        case .messageTimerUpdate:
            self = .conversation(.messageTimerUpdate)

        case .mlsMessageAdd:
            self = .conversation(.mlsMessageAdd)

        case .mlsWelcome:
            self = .conversation(.mlsWelcome)

        case .otrAssetAdd:
            self = .conversation(.proteusAssetAdd)

        case .otrMessageAdd:
            self = .conversation(.proteusMessageAdd)

        case .protocolUpdate:
            self = .conversation(.protocolUpdate)

        case .receiptModeUpdate:
            self = .conversation(.receiptModeUpdate)

        case .rename:
            self = .conversation(.rename)

        case .typing:
            self = .conversation(.typing)
        }
    }

}
