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

enum ConversationEventType: String {

    case accessUpdate = "conversation.access-update"
    case codeUpdate = "conversation.code-update"
    case create = "conversation.create"
    case delete = "conversation.delete"
    case memberJoin = "conversation.member-join"
    case memberLeave = "conversation.member-leave"
    case memberUpdate = "conversation.member-update"
    case messageTimerUpdate = "conversation.message-timer-update"
    case mlsMessageAdd = "conversation.mls-message-add"
    case mlsWelcome = "conversation.mls-welcome"
    case otrAssetAdd = "conversation.otr-asset-add"
    case otrMessageAdd = "conversation.otr-message-add"
    case protocolUpdate = "conversation.protocol-update"
    case receiptModeUpdate = "conversation.receipt-mode-update"
    case rename = "conversation.rename"
    case typing = "conversation.typing"

}
