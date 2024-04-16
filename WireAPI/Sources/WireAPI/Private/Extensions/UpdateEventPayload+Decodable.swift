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

extension UpdateEventPayload: Decodable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: UpdateEventPayloadCodingKeys.self)
        let eventType = try container.decode(String.self, forKey: .eventType)

        switch eventType {
        case "conversation.asset-add":
            self = .conversationAssetAdd
        case "conversation.access-update":
            self = .conversationAccessUpdate
        case "conversation.client-message-add":
            self = .conversationClientMessageAdd
        case "conversation.code-update":
            self = .conversationCodeUpdate
        case "conversation.connect-request":
            self = .conversationConnectRequest
        case "conversation.create":
            self = .conversationCreate
        case "conversation.delete":
            let event = try container.decodeConversationDeleteEvent()
            self = .conversationDelete(event)
        case "conversation.knock":
            self = .conversationKnock
        case "conversation.member-join":
            self = .conversationMemberJoin
        case "conversation.member-leave":
            self = .conversationMemberLeave
        case "conversation.member-update":
            self = .conversationMemberUpdate
        case "conversation.message-add":
            self = .conversationMessageAdd
        case "conversation.message-timer-update":
            self = .conversationMessageTimerUpdate
        case "conversation.mls-message-add":
            self = .conversationMLSMessageAdd
        case "conversation.mls-welcome":
            self = .conversationMLSWelcome
        case "conversation.otr-asset-add":
            self = .conversationOTRAssetAdd
        case "conversation.otr-message-add":
            self = .conversationOTRMessageAdd
        case "conversation.protocol-update":
            self = .conversationProtocolUpdate
        case "conversation.receipt-mode-update":
            self = .conversationReceiptModeUpdate
        case "conversation.rename":
            let event = try container.decodeConversationRenameEvent()
            self = .conversationRename(event)
        case "conversation.typing":
            self = .conversationTyping
        case "feature-config.update":
            self = .featureConfigUpdate
        case "federation.connectionRemoved":
            self = .federationConnectionRemoved
        case "federation.delete":
            self = .federationDelete
        case "user.client-add":
            self = .userClientAdd
        case "user.client-remove":
            self = .userClientRemove
        case "user.connection":
            self = .userConnection
        case "user.contact-join":
            self = .userContactJoin
        case "user.delete":
            self = .userDelete
        case "user.new":
            self = .userNew
        case "user.legalhold-disable":
            self = .userLegalholdDisable
        case "user.legalhold-enable":
            self = .userLegalholdEnable
        case "user.legalhold-request":
            self = .userLegalHoldRequest
        case "user.properties-set":
            self = .userPropertiesSet
        case "user.properties-delete":
            self = .userPropertiesDelete
        case "user.push-remove":
            self = .userPushRemove
        case "user.update":
            self = .userUpdate
        case "team.conversation-create":
            self = .teamConversationCreate
        case "team.conversation-delete":
            self = .teamConversationDelete
        case "team.create":
            self = .teamCreate
        case "team.delete":
            self = .teamDelete
        case "team.member-leave":
            self = .teamMemberLeave
        case "team.member-update":
            self = .teamMemberUpdate
        default:
            self = .unknown(eventType: eventType)
        }

    }

}

private enum UpdateEventPayloadCodingKeys: String, CodingKey {

    case eventType = "type"
    case conversationID = "conversation"
    case senderID = "from"
    case conversationQualifiedID = "qualified_conversation"
    case senderQualifiedID = "qualified_from"
    case timestamp = "time"
    case payload = "data"

}


private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationDeleteEvent() throws -> ConversationDeleteEvent {
        let conversationID = try decode(ConversationID.self, forKey: .conversationQualifiedID)
        let senderID = try decode(UserID.self, forKey: .senderQualifiedID)
        let timestamp = try decode(Date.self, forKey: .timestamp)

        return ConversationDeleteEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp
        )
    }

    func decodeConversationRenameEvent() throws -> ConversationRenameEvent {
        let conversationID = try decode(ConversationID.self, forKey: .conversationQualifiedID)
        let senderID = try decode(UserID.self, forKey: .senderQualifiedID)
        let timestamp = try decode(Date.self, forKey: .timestamp)
        let payload = try decode(ConversationRenameEventData.self, forKey: .payload)

        return ConversationRenameEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp,
            newName: payload.name
        )
    }

}

private struct ConversationRenameEventData: Decodable {

    let name: String

}
