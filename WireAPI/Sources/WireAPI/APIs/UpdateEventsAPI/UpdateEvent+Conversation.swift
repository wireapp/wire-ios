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
        case .assetAdd:
            self = .conversation(.assetAdd)

        case .accessUpdate:
            let event = try container.decodeAccessUpdateEvent()
            self = .conversation(.accessUpdate(event))

        case .clientMessageAdd:
            let event = try container.decodeClientMessageAddEvent()
            self = .conversation(.clientMessageAdd(event))

        case .codeUpdate:
            let event = try container.decodeCodeUpdateEvent()
            self = .conversation(.codeUpdate(event))

        case .connectRequest:
            self = .conversation(.connectRequest)

        case .create:
            self = .conversation(.create)

        case .delete:
            let event = try container.decodeDeleteEvent()
            self = .conversation(.delete(event))

        case .knock:
            self = .conversation(.knock)

        case .memberJoin:
            let event = try container.decodeMemberJoinEvent()
            self = .conversation(.memberJoin(event))

        case .memberLeave:
            let event = try container.decodeMemberLeaveEvent()
            self = .conversation(.memberLeave(event))

        case .memberUpdate:
            let event = try container.decodeMemberLeaveEvent()
            self = .conversation(.memberLeave(event))

        case .messageAdd:
            self = .conversation(.messageAdd)

        case .messageTimerUpdate:
            let event = try container.decodeMessageTimerUpdateEvent()
            self = .conversation(.messageTimerUpdate(event))

        case .mlsMessageAdd:
            let event = try container.decodeMLSMessageAddEvent()
            self = .conversation(.mlsMessageAdd(event))

        case .mlsWelcome:
            let event = try container.decodeMLSWelcomeEvent()
            self = .conversation(.mlsWelcome(event))

        case .otrAssetAdd:
            let event = try container.decodeProteusAssetAddEvent()
            self = .conversation(.proteusAssetAdd(event))

        case .otrMessageAdd:
            let event = try container.decodeProteusMessageAddEvent()
            self = .conversation(.proteusMessageAdd(event))

        case .protocolUpdate:
            let event = try container.decodeProtocolUpdateEvent()
            self = .conversation(.protocolUpdate(event))

        case .receiptModeUpdate:
            let event = try container.decodeReceiptModeUpdateEvent()
            self = .conversation(.receiptModeUpdate(event))

        case .rename:
            let event = try container.decodeRenameEvent()
            self = .conversation(.rename(event))

        case .typing:
            let event = try container.decodeTypingEvent()
            self = .conversation(.typing(event))
        }
    }

}

private enum ConversationEventCodingKeys: String, CodingKey {

    case eventType = "type"
    case conversationID = "conversation"
    case senderID = "from"
    case conversationQualifiedID = "qualified_conversation"
    case senderQualifiedID = "qualified_from"
    case subconversation = "subconv"
    case timestamp = "time"
    case payload = "data"

}

private extension KeyedDecodingContainer<ConversationEventCodingKeys> {

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

}

// MARK: - Conversation access update

private extension KeyedDecodingContainer<ConversationEventCodingKeys> {

    func decodeAccessUpdateEvent() throws -> ConversationAccessUpdateEvent {
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

private extension KeyedDecodingContainer<ConversationEventCodingKeys> {

    func decodeClientMessageAddEvent() throws -> ConversationClientMessageAddEvent {
        try ConversationClientMessageAddEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            timestamp: decodeTimestamp(),
            protobufMessage: decodePayload(String.self)
        )
    }

}

// MARK: - Conversation code update

private extension KeyedDecodingContainer<ConversationEventCodingKeys> {

    func decodeCodeUpdateEvent() throws -> ConversationCodeUpdateEvent {
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

private extension KeyedDecodingContainer<ConversationEventCodingKeys> {

    func decodeDeleteEvent() throws -> ConversationDeleteEvent {
        try ConversationDeleteEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            timestamp: decodeTimestamp()
        )
    }

}

// MARK: - Conversation member join

private extension KeyedDecodingContainer<ConversationEventCodingKeys> {

    func decodeMemberJoinEvent() throws -> ConversationMemberJoinEvent {
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

private extension KeyedDecodingContainer<ConversationEventCodingKeys> {

    func decodeMemberLeaveEvent() throws -> ConversationMemberLeaveEvent {
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

private extension KeyedDecodingContainer<ConversationEventCodingKeys> {

    func decodeMemberUpdateEvent() throws -> ConversationMemberUpdateEvent {
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

private extension KeyedDecodingContainer<ConversationEventCodingKeys> {

    func decodeMessageTimerUpdateEvent() throws -> ConversationMessageTimerUpdateEvent {
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

private extension KeyedDecodingContainer<ConversationEventCodingKeys> {

    func decodeMLSMessageAddEvent() throws -> ConversationMLSMessageAddEvent {
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

private extension KeyedDecodingContainer<ConversationEventCodingKeys> {

    func decodeMLSWelcomeEvent() throws -> ConversationMLSWelcomeEvent {
        try ConversationMLSWelcomeEvent(
            conversationID: decodeConversationID(),
            senderID: decodeSenderID(),
            welcomeMessage: decodePayload(String.self)
        )
    }

}

// MARK: - Conversation proteus asset add

private extension KeyedDecodingContainer<ConversationEventCodingKeys> {

    func decodeProteusAssetAddEvent() throws -> ConversationProteusAssetAddEvent {
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

private extension KeyedDecodingContainer<ConversationEventCodingKeys> {

    func decodeProteusMessageAddEvent() throws -> ConversationProteusMessageAddEvent {
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

private extension KeyedDecodingContainer<ConversationEventCodingKeys> {

    func decodeProtocolUpdateEvent() throws -> ConversationProtocolUpdateEvent {
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

private extension KeyedDecodingContainer<ConversationEventCodingKeys> {

    func decodeReceiptModeUpdateEvent() throws -> ConversationReceiptModeUpdateEvent {
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

private extension KeyedDecodingContainer<ConversationEventCodingKeys> {

    func decodeRenameEvent() throws -> ConversationRenameEvent {
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

private extension KeyedDecodingContainer<ConversationEventCodingKeys> {

    func decodeTypingEvent() throws -> ConversationTypingEvent {
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
