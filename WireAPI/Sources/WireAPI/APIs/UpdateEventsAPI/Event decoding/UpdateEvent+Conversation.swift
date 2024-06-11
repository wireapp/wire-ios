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
        from _: any Decoder
    ) throws {
        switch eventType {
        case .assetAdd:
            self = .conversation(.assetAdd)

        case .accessUpdate:
            self = .conversation(.accessUpdate)

        case .clientMessageAdd:
            self = .conversation(.clientMessageAdd)

        case .codeUpdate:
            self = .conversation(.codeUpdate)

        case .create:
            self = .conversation(.create)

        case .delete:
            self = .conversation(.delete)

        case .knock:
            self = .conversation(.knock)

        case .memberJoin:
            self = .conversation(.memberJoin)

        case .memberLeave:
            self = .conversation(.memberLeave)

        case .memberUpdate:
            self = .conversation(.memberLeave)

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
