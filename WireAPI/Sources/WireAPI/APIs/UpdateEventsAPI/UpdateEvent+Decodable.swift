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

extension UpdateEvent: Decodable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: UpdateEventPayloadCodingKeys.self)
        let eventType = try container.decode(String.self, forKey: .eventType)

        switch eventType {
        case "conversation.asset-add":
            self = .conversationAssetAdd
        case "conversation.access-update":
            let event = try container.decodeConversationAccessUpdateEvent()
            self = .conversationAccessUpdate(event)
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
            let event = try container.decodeConversationMemberJoinEvent()
            self = .conversationMemberJoin(event)
        case "conversation.member-leave":
            let event = try container.decodeConversationMemberLeaveEvent()
            self = .conversationMemberLeave(event)
        case "conversation.member-update":
            let event = try container.decodeConversationMemberUpdateEvent()
            self = .conversationMemberUpdate(event)
        case "conversation.message-add":
            self = .conversationMessageAdd
        case "conversation.message-timer-update":
            let event = try container.decodeConversationMessageTimerUpdateEvent()
            self = .conversationMessageTimerUpdate(event)
        case "conversation.mls-message-add":
            let event = try container.decodeConversationMLSMessageAddEvent()
            self = .conversationMLSMessageAdd(event)
        case "conversation.mls-welcome":
            let event = try container.decodeConversationMLSWelcomeEvent()
            self = .conversationMLSWelcome(event)
        case "conversation.otr-asset-add":
            self = .conversationOTRAssetAdd
        case "conversation.otr-message-add":
            self = .conversationOTRMessageAdd
        case "conversation.protocol-update":
            let event = try container.decodeConversationProtocolUpdateEvent()
            self = .conversationProtocolUpdate(event)
        case "conversation.receipt-mode-update":
            let event = try container.decodeConversationRecieptModeUpdateEvent()
            self = .conversationReceiptModeUpdate(event)
        case "conversation.rename":
            let event = try container.decodeConversationRenameEvent()
            self = .conversationRename(event)
        case "conversation.typing":
            let event = try container.decodeConversationTypingEvent()
            self = .conversationTyping(event)
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
    case subconversation = "subconv"
    case timestamp = "time"
    case payload = "data"

}

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    private func decodeConversationID() throws -> ConversationID {
        try decode(ConversationID.self, forKey: .conversationQualifiedID)
    }

    private func decodeSenderID() throws -> UserID {
        try decode(UserID.self, forKey: .senderQualifiedID)
    }

    private func decodeTimestamp() throws -> Date {
        try decode(Date.self, forKey: .timestamp)
    }

    private func decodeSubconversation() throws -> String? {
        try decodeIfPresent(String.self, forKey: .subconversation)
    }

    private func decodePayload<T: Decodable>(_ type: T.Type) throws -> T {
        try decode(T.self, forKey: .payload)
    }

    func decodeConversationDeleteEvent() throws -> ConversationDeleteEvent {
        try ConversationDeleteEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            timestamp: decodeTimestamp()
        )
    }

    func decodeConversationMemberJoinEvent() throws -> ConversationMemberJoinEvent {
        let payload = try decodePayload(ConversationMemberJoinEventData.self)

        return try ConversationMemberJoinEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            timestamp: decodeTimestamp(),
            members: payload.users.map {
                ConversationMember(
                    id: $0.id,
                    roleName: $0.conversationRole,
                    service: $0.service.map {
                        ConversationService(
                            id: $0.id,
                            provider: $0.provider
                        )
                    }
                )
            }
        )
    }

    func decodeConversationMemberLeaveEvent() throws -> ConversationMemberLeaveEvent {
        let payload = try decodePayload(ConversationMemberLeaveEventData.self)

        return try ConversationMemberLeaveEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            timestamp: decodeTimestamp(),
            removedUserIDs: payload.qualified_user_ids,
            reason: payload.reason ?? .left
        )
    }

    func decodeConversationMemberUpdateEvent() throws -> ConversationMemberUpdateEvent {
        let payload = try decodePayload(ConversationMemberUpdateEventData.self)

        return try ConversationMemberUpdateEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            timestamp: decodeTimestamp(),
            memberChange: ConversationMemberChange(
                id: payload.qualified_target,
                newRoleName: payload.conversation_role,
                newMuteStatus: payload.otr_muted_status,
                muteStatusReferenceDate: payload.otr_muted_ref,
                newArchivedStatus: payload.otr_archived,
                archivedStatusReferenceDate: payload.otr_archived_ref
            )
        )
    }

    func decodeConversationMessageTimerUpdateEvent() throws -> ConversationMessageTimerUpdateEvent {
        let payload = try decodePayload(ConversationMessageTimerUpdateEventData.self)

        return try ConversationMessageTimerUpdateEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            timestamp: decodeTimestamp(),
            newTimer: payload.message_timer
        )
    }

    func decodeConversationMLSMessageAddEvent() throws -> ConversationMLSMessageAddEvent {
        try ConversationMLSMessageAddEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            subconversation: decodeSubconversation(),
            message: decodePayload(String.self)
        )
    }

    func decodeConversationMLSWelcomeEvent() throws -> ConversationMLSWelcomeEvent {
        try ConversationMLSWelcomeEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            welcomeMessage: decodePayload(String.self)
        )
    }

    func decodeConversationProtocolUpdateEvent() throws -> ConversationProtocolUpdateEvent {
        let payload = try decodePayload(ConversationProtocolEventData.self)

        return try ConversationProtocolUpdateEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            newProtocol: payload.protocol
        )
    }

    func decodeConversationRecieptModeUpdateEvent() throws -> ConversationReceiptModeUpdateEvent {
        let payload = try decodePayload(ConversationReceiptModeUpdateEventData.self)

        return try ConversationReceiptModeUpdateEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            newRecieptMode: payload.receipt_mode
        )
    }

    func decodeConversationRenameEvent() throws -> ConversationRenameEvent {
        let payload = try decodePayload(ConversationRenameEventData.self)

        return try ConversationRenameEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            timestamp: decodeTimestamp(),
            newName: payload.name
        )
    }

    func decodeConversationTypingEvent() throws -> ConversationTypingEvent {
        let payload = try decodePayload(ConversationTypingEventData.self)

        return try ConversationTypingEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            isTyping: payload.status == .started
        )
    }

    func decodeConversationAccessUpdateEvent() throws -> ConversationAccessUpdateEvent {
        let payload = try decodePayload(ConversationAccessUpdateEventData.self)

        return try ConversationAccessUpdateEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            accessModes: payload.access,
            accessRoles: payload.access_role_v2 ?? [],
            legacyAccessRole: payload.access_role
        )
    }

}

private struct ConversationMemberJoinEventData: Decodable {

    let users: [OtherConversationMember]

}

private struct OtherConversationMember: Decodable {

    let id: UserID
    let conversationRole: String
    let service: ServiceReference?

    enum CodingKeys: String, CodingKey {

        case id = "qualified_id"
        case conversationRole = "conversation_role"
        case service = "service"

    }

}

private struct ServiceReference: Decodable {

    let id: UUID
    let provider: UUID

}


private struct ConversationMemberLeaveEventData: Decodable {

    let qualified_user_ids: Set<UserID>
    let reason: ConversationMemberLeaveReason?

}

private struct ConversationMemberUpdateEventData: Decodable {

    let qualified_target: UserID
    let conversation_role: String?
    let otr_muted_status: Int?
    let otr_muted_ref: Date?
    let otr_archived: Bool?
    let otr_archived_ref: Date?

}


private struct ConversationMessageTimerUpdateEventData: Decodable {

    let message_timer: Int64?

}

private struct ConversationProtocolEventData: Decodable {

    let `protocol`: ConversationProtocol

}


private struct ConversationReceiptModeUpdateEventData: Decodable {

    let receipt_mode: Int

}

private struct ConversationRenameEventData: Decodable {

    let name: String

}

private struct ConversationTypingEventData: Decodable {

    let status: TypingStatus

    enum TypingStatus: String, Decodable {

        case started
        case stopped

    }

}

private struct ConversationAccessUpdateEventData: Decodable {

    let access: Set<ConversationAccessMode>
    let access_role: ConversationAccessRoleLegacy?
    let access_role_v2: Set<ConversationAccessRole>?

}
