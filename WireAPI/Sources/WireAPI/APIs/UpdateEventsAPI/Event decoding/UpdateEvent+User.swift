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
        eventType: UserEventType,
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(keyedBy: UserEventCodingKeys.self)

        switch eventType {
        case .clientAdd:
            let event = try container.decodeClientAddEvent()
            self = .user(.clientAdd(event))

        case .clientRemove:
            let event = try container.decodeClientRemoveEvent()
            self = .user(.clientRemove(event))

        case .connection:
            let event = try container.decodeConnectionEvent()
            self = .user(.connection(event))

        case .contactJoin:
            let event = try container.decodeContactJoinEvent()
            self = .user(.contactJoin(event))

        case .delete:
            let event = try container.decodeDeleteEvent()
            self = .user(.delete(event))

        case .legalholdDisable:
            let event = try container.decodeLegalholdDisableEvent()
            self = .user(.legalholdDisable(event))

        case .legalholdEnable:
            let event = try container.decodeLegalholdEnableEvent()
            self = .user(.legalholdEnable(event))

        case .legalholdRequest:
            self = .user(.legalholdRequest)

        case .propertiesSet:
            self = .user(.propertiesSet)

        case .propertiesDelete:
            self = .user(.propertiesDelete)

        case .pushRemove:
            self = .user(.pushRemove)

        case .update:
            self = .user(.update)
        }
    }

}

private enum UserEventCodingKeys: String, CodingKey {

    case client = "client"
    case user = "user"
    case id = "id"
    case qualifiedID = "qualified_id"
    case connection = "connection"

}

// MARK: - User client add

private extension KeyedDecodingContainer<UserEventCodingKeys> {

    func decodeClientAddEvent() throws -> UserClientAddEvent {
        let payload = try decode(UserClientAddEventPayload.self, forKey: .client)

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

private extension KeyedDecodingContainer<UserEventCodingKeys> {

    func decodeClientRemoveEvent() throws -> UserClientRemoveEvent {
        let payload = try decode(UserClientRemoveEventPayload.self, forKey: .client)
        return UserClientRemoveEvent(clientID: payload.id)
    }

    private struct UserClientRemoveEventPayload: Decodable {

        let id: String

    }

}

// MARK: - User connection event

private extension KeyedDecodingContainer<UserEventCodingKeys> {

    func decodeConnectionEvent() throws -> UserConnectionEvent {
        let user = try decode(UserPayload.self, forKey: .user)
        let connection = try decode(ConnectionPayload.self, forKey: .connection)
        
        return UserConnectionEvent(
            userName: user.name,
            connection: Connection(
                senderId: connection.from,
                receiverId: connection.to,
                receiverQualifiedId: connection.qualifiedTo,
                conversationId: connection.conversationID,
                qualifiedConversationId: connection.qualifiedConversationID,
                lastUpdate: connection.lastUpdate,
                status: connection.status
            )
        )
    }

    private struct UserPayload: Decodable {

        let name: String

    }

    private struct ConnectionPayload: Decodable {

        let from: UUID?
        let to: UUID?
        let qualifiedTo: QualifiedID?
        let conversationID: UUID?
        let qualifiedConversationID: QualifiedID?
        let lastUpdate: Date
        let status: ConnectionStatus

        enum CodingKeys: String, CodingKey {
            case from
            case to
            case qualifiedTo = "qualified_to"
            case conversationID = "conversation"
            case qualifiedConversationID = "qualified_conversation"
            case lastUpdate = "last_update"
            case status
        }

    }

}

// MARK: - User contact join event

private extension KeyedDecodingContainer<UserEventCodingKeys> {

    func decodeContactJoinEvent() throws -> UserContactJoinEvent {
        let user = try decode(UserPayload.self, forKey: .user)
        return UserContactJoinEvent(name: user.name)
    }

}

// MARK: - User delete event

private extension KeyedDecodingContainer<UserEventCodingKeys> {

    func decodeDeleteEvent() throws -> UserDeleteEvent {
        let userID = try decode(UUID.self, forKey: .id)
        let qualifiedUserID = try decode(QualifiedID.self, forKey: .qualifiedID)

        return UserDeleteEvent(
            userID: userID,
            qualifiedUserID: qualifiedUserID
        )
    }

}

// MARK: - User legalhold disable event

private extension KeyedDecodingContainer<UserEventCodingKeys> {

    func decodeLegalholdDisableEvent() throws -> UserLegalholdDisableEvent {
        let userID = try decode(UUID.self, forKey: .id)
        return UserLegalholdDisableEvent(userID: userID)
    }

}

// MARK: - User legalhold enable event

private extension KeyedDecodingContainer<UserEventCodingKeys> {

    func decodeLegalholdEnableEvent() throws -> UserLegalholdEnableEvent {
        let userID = try decode(UUID.self, forKey: .id)
        return UserLegalholdEnableEvent(userID: userID)
    }

}
