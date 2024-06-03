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

enum UpdateEventType {

    case conversation(ConversationEventType)
    case featureConfig(FeatureConfigEventType)
    case federation(FederationEventType)
    case user(UserEventType)
    case team(TeamEventType)
    case unknown(String)

    init(_ string: String) {
        if let eventType = ConversationEventType(rawValue: string) {
            self = .conversation(eventType)
        } else if let eventType = FeatureConfigEventType(rawValue: string) {
            self = .featureConfig(eventType)
        } else if let eventType = FederationEventType(rawValue: string) {
            self = .federation(eventType)
        } else if let eventType = UserEventType(rawValue: string) {
            self = .user(eventType)
        } else if let eventType = TeamEventType(rawValue: string) {
            self = .team(eventType)
        } else {
            self = .unknown(string)
        }
    }

}

enum ConversationEventType: String {

    case assetAdd = "conversation.asset-add"
    case accessUpdate = "conversation.access-update"
    case clientMessageAdd = "conversation.client-message-add"
    case codeUpdate = "conversation.code-update"
    case create = "conversation.create"
    case delete = "conversation.delete"
    case knock = "conversation.knock"
    case memberJoin = "conversation.member-join"
    case memberLeave = "conversation.member-leave"
    case memberUpdate = "conversation.member-update"
    case messageAdd = "conversation.message-add"
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

enum FeatureConfigEventType: String {

    case update = "feature-config.update"

}

enum FederationEventType: String {

    case connectionRemoved = "federation.connectionRemoved"
    case delete = "federation.delete"

}

enum UserEventType: String {

    case clientAdd = "user.client-add"
    case clientRemove = "user.client-remove"
    case connection = "user.connection"
    case contactJoin = "user.contact-join"
    case delete = "user.delete"
    case legalholdDisable = "user.legalhold-disable"
    case legalholdEnable = "user.legalhold-enable"
    case legalholdRequest = "user.legalhold-request"
    case propertiesSet = "user.properties-set"
    case propertiesDelete = "user.properties-delete"
    case pushRemove = "user.push-remove"
    case update = "user.update"

}

enum TeamEventType: String {

    case conversationCreate = "team.conversation-create"
    case conversationDelete = "team.conversation-delete"
    case delete = "team.delete"
    case memberLeave = "team.member-leave"
    case memberUpdate = "team.member-update"

}
