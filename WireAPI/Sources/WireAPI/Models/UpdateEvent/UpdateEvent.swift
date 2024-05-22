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

// TODO: document
public enum UpdateEvent {

    case conversationAssetAdd
    case conversationAccessUpdate(ConversationAccessUpdateEvent)
    case conversationClientMessageAdd(ConversationClientMessageAddEvent)
    case conversationCodeUpdate
    case conversationConnectRequest
    case conversationCreate
    case conversationDelete(ConversationDeleteEvent)
    case conversationKnock
    case conversationMemberJoin(ConversationMemberJoinEvent)
    case conversationMemberLeave(ConversationMemberLeaveEvent)
    case conversationMemberUpdate(ConversationMemberUpdateEvent)
    case conversationMessageAdd
    case conversationMessageTimerUpdate(ConversationMessageTimerUpdateEvent)
    case conversationMLSMessageAdd(ConversationMLSMessageAddEvent)
    case conversationMLSWelcome(ConversationMLSWelcomeEvent)
    case conversationOTRAssetAdd
    case conversationOTRMessageAdd(ConversationProteusMessageAddEvent)
    case conversationProtocolUpdate(ConversationProtocolUpdateEvent)
    case conversationReceiptModeUpdate(ConversationReceiptModeUpdateEvent)
    case conversationRename(ConversationRenameEvent)
    case conversationTyping(ConversationTypingEvent)
    case featureConfigUpdate
    case federationConnectionRemoved
    case federationDelete
    case userClientAdd
    case userClientRemove
    case userConnection
    case userContactJoin
    case userDelete
    case userNew
    case userLegalholdDisable
    case userLegalholdEnable
    case userLegalHoldRequest
    case userPropertiesSet
    case userPropertiesDelete
    case userPushRemove
    case userUpdate
    case teamConversationCreate
    case teamConversationDelete
    case teamCreate
    case teamDelete
    case teamMemberLeave
    case teamMemberUpdate
    case unknown(eventType: String)

}
