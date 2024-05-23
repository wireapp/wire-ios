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

    case conversation(ConversationEvent)
    case featureConfig(FeatureConfigEvent)
    case federation(FederationEvent)
    case user(UserEvent)
    case team(TeamEvent)
    case unknown(eventType: String)

}

public enum ConversationEvent {

    case assetAdd
    case accessUpdate(ConversationAccessUpdateEvent)
    case clientMessageAdd(ConversationClientMessageAddEvent)
    case codeUpdate(ConversationCodeUpdateEvent)
    case connectRequest // deprecated?
    case create // TODO
    case delete(ConversationDeleteEvent)
    case knock // deprecated?
    case memberJoin(ConversationMemberJoinEvent)
    case memberLeave(ConversationMemberLeaveEvent)
    case memberUpdate(ConversationMemberUpdateEvent)
    case messageAdd // deprecated?
    case messageTimerUpdate(ConversationMessageTimerUpdateEvent)
    case mlsMessageAdd(ConversationMLSMessageAddEvent)
    case mlsWelcome(ConversationMLSWelcomeEvent)
    case proteusAssetAdd(ConversationProteusAssetAddEvent)
    case proteusMessageAdd(ConversationProteusMessageAddEvent)
    case protocolUpdate(ConversationProtocolUpdateEvent)
    case receiptModeUpdate(ConversationReceiptModeUpdateEvent)
    case rename(ConversationRenameEvent)
    case typing(ConversationTypingEvent)

}

public enum FeatureConfigEvent {

    case update

}

public enum FederationEvent {

    case connectionRemoved(FederationConnectionRemovedEvent)
    case delete(FederationDeleteEvent)

}

public enum UserEvent {

    case clientAdd(UserClientAddEvent)
    case clientRemove(UserClientRemoveEvent)
    case connection
    case contactJoin
    case delete(UserDeleteEvent)
    case new
    case legalholdDisable
    case legalholdEnable
    case legalholdRequest
    case propertiesSet
    case propertiesDelete
    case pushRemove
    case update

}

public enum TeamEvent {

    case conversationCreate
    case conversationDelete
    case create
    case delete
    case memberLeave
    case memberUpdate

}
