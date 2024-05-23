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
            let event = try container.decodeConversationClientMessageAddEvent()
            self = .conversationClientMessageAdd(event)
        case "conversation.code-update":
            let event = try container.decodeConversationCodeUpdateEvent()
            self = .conversationCodeUpdate(event)
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
            let event = try container.decodeConversationProteusAssetAddEvent()
            self = .conversationOTRAssetAdd(event)
        case "conversation.otr-message-add":
            let event = try container.decodeConversationProteusMessageAddEvent()
            self = .conversationOTRMessageAdd(event)
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
            let event = try container.decodeFederationConnectionRemovedEvent()
            self = .federationConnectionRemoved(event)
        case "federation.delete":
            let event = try container.decodeFederationDeleteEvent()
            self = .federationDelete(event)
        case "user.client-add":
            let event = try container.decodeUserClientAddEvent()
            self = .userClientAdd(event)
        case "user.client-remove":
            let event = try container.decodeUserClientRemoveEvent()
            self = .userClientRemove(event)
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
    case clientPayload = "client"

}

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationID() throws -> ConversationID {
        try decode(ConversationID.self, forKey: .conversationQualifiedID)
    }

    func decodeSenderID() throws -> UserID {
        try decode(UserID.self, forKey: .senderQualifiedID)
    }

    func decodeTimestamp() throws -> Date {
        try decode(Date.self, forKey: .timestamp)
    }

    func decodeSubconversation() throws -> String? {
        try decodeIfPresent(String.self, forKey: .subconversation)
    }

    func decodePayload<T: Decodable>(_ type: T.Type) throws -> T {
        try decode(T.self, forKey: .payload)
    }

    func decodeClientPayload<T: Decodable>(_ type: T.Type) throws -> T {
        try decode(T.self, forKey: .clientPayload)
    }

}

// MARK: - Conversation access update

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationAccessUpdateEvent() throws -> ConversationAccessUpdateEvent {
        let payload = try decodePayload(ConversationAccessUpdateEventPayload.self)

        return try ConversationAccessUpdateEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            accessModes: payload.accessModes,
            accessRoles: payload.accessRoles ?? [],
            legacyAccessRole: payload.legacyAccessRole
        )
    }

    private struct ConversationAccessUpdateEventPayload: Decodable {

        let accessModes: Set<ConversationAccessMode>
        let legacyAccessRole: ConversationAccessRoleLegacy?
        let accessRoles: Set<ConversationAccessRole>?

        enum CodingKeys: String, CodingKey {

            case accessModes = "access"
            case legacyAccessRole = "access_role"
            case accessRoles = "access_role_v2"

        }

    }

}

// MARK: - Conversation client message add

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationClientMessageAddEvent() throws -> ConversationClientMessageAddEvent {
        try ConversationClientMessageAddEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            timestamp: decodeTimestamp(),
            protobufMessage: decodePayload(String.self)
        )
    }

}

// MARK: - Conversation code update

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationCodeUpdateEvent() throws -> ConversationCodeUpdateEvent {
        let payload = try decodePayload(ConversationCodeUpdateEventPayload.self)

        return try ConversationCodeUpdateEvent(
            conversationID: decodeConversationID(),
            key: payload.key,
            code: payload.code,
            uri: payload.uri,
            isPasswordProtected: payload.hasPassword
        )
    }

    private struct ConversationCodeUpdateEventPayload: Decodable {

        let key: String
        let code: String
        let uri: String?
        let hasPassword: Bool

        enum CodingKeys: String, CodingKey {

            case key
            case code
            case uri
            case hasPassword = "has_password"

        }

    }

}

// MARK: - Conversation delete

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationDeleteEvent() throws -> ConversationDeleteEvent {
        try ConversationDeleteEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            timestamp: decodeTimestamp()
        )
    }

}

// MARK: - Conversation member join

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationMemberJoinEvent() throws -> ConversationMemberJoinEvent {
        let payload = try decodePayload(ConversationMemberJoinEventPayload.self)

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

    private struct ConversationMemberJoinEventPayload: Decodable {

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

}

// MARK: - Conversation member leave

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationMemberLeaveEvent() throws -> ConversationMemberLeaveEvent {
        let payload = try decodePayload(ConversationMemberLeaveEventPayload.self)

        return try ConversationMemberLeaveEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            timestamp: decodeTimestamp(),
            removedUserIDs: payload.userIDs,
            reason: payload.reason ?? .left
        )
    }

    private struct ConversationMemberLeaveEventPayload: Decodable {

        let userIDs: Set<UserID>
        let reason: ConversationMemberLeaveReason?

        enum CodingKeys: String, CodingKey {

            case userIDs = "qualified_user_ids"
            case reason

        }

    }

}

// MARK: - Conversation member update

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationMemberUpdateEvent() throws -> ConversationMemberUpdateEvent {
        let payload = try decodePayload(ConversationMemberUpdateEventPayload.self)

        return try ConversationMemberUpdateEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            timestamp: decodeTimestamp(),
            memberChange: ConversationMemberChange(
                id: payload.userID,
                newRoleName: payload.role,
                newMuteStatus: payload.muteStatus,
                muteStatusReferenceDate: payload.muteStatusReference,
                newArchivedStatus: payload.archivedStatus,
                archivedStatusReferenceDate: payload.archivedStatusReference
            )
        )
    }

    private struct ConversationMemberUpdateEventPayload: Decodable {

        let userID: UserID
        let role: String?
        let muteStatus: Int?
        let muteStatusReference: Date?
        let archivedStatus: Bool?
        let archivedStatusReference: Date?

        enum CodingKeys: String, CodingKey {

            case userID = "qualified_target"
            case role = "conversation_role"
            case muteStatus = "otr_muted_status"
            case muteStatusReference = "otr_muted_ref"
            case archivedStatus = "otr_archived"
            case archivedStatusReference = "otr_archived_ref"

        }

    }

}

// MARK: - Conversation message timer update

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationMessageTimerUpdateEvent() throws -> ConversationMessageTimerUpdateEvent {
        let payload = try decodePayload(ConversationMessageTimerUpdateEventPayload.self)

        return try ConversationMessageTimerUpdateEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            timestamp: decodeTimestamp(),
            newTimer: payload.messageTimer
        )
    }

    private struct ConversationMessageTimerUpdateEventPayload: Decodable {

        let messageTimer: Int64?

        enum CodingKeys: String, CodingKey {

            case messageTimer = "message_timer"

        }

    }

}

// MARK: - Conversation mls message add

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationMLSMessageAddEvent() throws -> ConversationMLSMessageAddEvent {
        let payload = try decodePayload(ConversationMLSMessageAddEventPayload.self)

        return try ConversationMLSMessageAddEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            subconversation: decodeSubconversation(),
            message: payload.text
        )
    }

    private struct ConversationMLSMessageAddEventPayload: Decodable {

        let text: String

    }

}

// MARK: - Conversation mls welcome

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationMLSWelcomeEvent() throws -> ConversationMLSWelcomeEvent {
        try ConversationMLSWelcomeEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            welcomeMessage: decodePayload(String.self)
        )
    }

}

// MARK: - Conversation proteus asset add

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationProteusAssetAddEvent() throws -> ConversationProteusAssetAddEvent {
        let payload = try decodePayload(ConversationProteusAssetAddEventPayload.self)

        return try ConversationProteusAssetAddEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            timestamp: decodeTimestamp(),
            encryptedProtobufMessage: payload.info
        )
    }

    private struct ConversationProteusAssetAddEventPayload: Decodable {

        let info: String

    }

}

// MARK: - Conversation proteus message add

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationProteusMessageAddEvent() throws -> ConversationProteusMessageAddEvent {
        let payload = try decodePayload(ConversationProteusMessageAddEventPayload.self)

        return try ConversationProteusMessageAddEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            timestamp: decodeTimestamp(),
            encryptedProtobufMessage: payload.text
        )
    }

    private struct ConversationProteusMessageAddEventPayload: Decodable {

        let text: String

    }

}

// MARK: - Conversation protocol update

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationProtocolUpdateEvent() throws -> ConversationProtocolUpdateEvent {
        let payload = try decodePayload(ConversationProtocolEventPayload.self)

        return try ConversationProtocolUpdateEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            newProtocol: payload.protocol
        )
    }

    private struct ConversationProtocolEventPayload: Decodable {

        let `protocol`: ConversationProtocol

    }

}

// MARK: - Conversation receipt mode update

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationRecieptModeUpdateEvent() throws -> ConversationReceiptModeUpdateEvent {
        let payload = try decodePayload(ConversationReceiptModeUpdateEventPayload.self)

        return try ConversationReceiptModeUpdateEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            newRecieptMode: payload.receiptMode
        )
    }

    private struct ConversationReceiptModeUpdateEventPayload: Decodable {

        let receiptMode: Int

        enum CodingKeys: String, CodingKey {

            case receiptMode = "receipt_mode"

        }

    }

}

// MARK: - Conversation rename

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationRenameEvent() throws -> ConversationRenameEvent {
        let payload = try decodePayload(ConversationRenameEventPayload.self)

        return try ConversationRenameEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            timestamp: decodeTimestamp(),
            newName: payload.name
        )
    }

    private struct ConversationRenameEventPayload: Decodable {

        let name: String

    }

}

// MARK: - Conversation typing

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeConversationTypingEvent() throws -> ConversationTypingEvent {
        let payload = try decodePayload(ConversationTypingEventPayload.self)

        return try ConversationTypingEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            isTyping: payload.status == .started
        )
    }

    private struct ConversationTypingEventPayload: Decodable {

        let status: TypingStatus

    }

    private enum TypingStatus: String, Decodable {

        case started
        case stopped

    }

}

// MARK: - Federation connection removed

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeFederationConnectionRemovedEvent() throws -> FederationConnectionRemovedEvent {
        let payload = try decodePayload(FederationConnectionRemovedEventPayload.self)
        return FederationConnectionRemovedEvent(domains: payload.domains)
    }

    private struct FederationConnectionRemovedEventPayload: Decodable {

        let domains: Set<String>

    }

}

// MARK: - Federation delete

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeFederationDeleteEvent() throws -> FederationDeleteEvent {
        let payload = try decodePayload(FederationDeleteEventPayload.self)
        return FederationDeleteEvent(domain: payload.domain)
    }

    private struct FederationDeleteEventPayload: Decodable {

        let domain: String

    }

}

// MARK: - User client add

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeUserClientAddEvent() throws -> UserClientAddEvent {
        let payload = try decodeClientPayload(UserClientAddEventPayload.self)

        return UserClientAddEvent(
            client:UserClient(
                id: payload.id,
                type: payload.type,
                activationDate: payload.activationDate,
                label: payload.label,
                model: payload.model,
                deviceClass: payload.deviceClass,
                lastActiveDate: payload.lastActiveDate,
                mlsPublicKeys: payload.mlsPublicKeys,
                cookie: payload.cookie,
                capabilities: payload.capabilities?.capabilities ?? []
            )
        )
    }

    private struct UserClientAddEventPayload: Decodable {

        let id: String
        let type: UserClientType
        let activationDate: Date
        let label: String?
        let model: String?
        let deviceClass: DeviceClass?
        let lastActiveDate: Date?
        let mlsPublicKeys: MLSPublicKeys?
        let cookie: String?
        let capabilities: CapabilitiesList?

        enum CodingKeys: String, CodingKey {

            case id
            case type
            case activationDate = "time"
            case label
            case model
            case deviceClass = "class"
            case lastActiveDate = "last_active"
            case mlsPublicKeys = "mls_public_keys"
            case cookie
            case capabilities

        }

    }

    private struct CapabilitiesList: Decodable {

        let capabilities: [UserClientCapability]

    }


}

// MARK: - User client remove

private extension KeyedDecodingContainer<UpdateEventPayloadCodingKeys> {

    func decodeUserClientRemoveEvent() throws -> UserClientRemoveEvent {
        let payload = try decodeClientPayload(UserClientRemoveEventPayload.self)
        return UserClientRemoveEvent(clientID: payload.id)
    }

    private struct UserClientRemoveEventPayload: Decodable {

        let id: String

    }

}
