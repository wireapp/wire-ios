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
import WireDataModel

public enum Payload {

    public typealias UserClients = [Payload.UserClient]
    public typealias UserClientByUserID = [String: UserClients]
    public typealias UserClientByDomain = [String: UserClientByUserID]
    public typealias PrekeyByClientID = [String: Prekey?]
    public typealias PrekeyByUserID = [String: PrekeyByClientID]
    public typealias PrekeyByQualifiedUserID = [String: PrekeyByUserID]
    public typealias ClientList = [String]
    public typealias ClientListByUserID = [String: ClientList]
    public typealias ClientListByQualifiedUserID = [String: ClientListByUserID]
    public typealias ClientListByUser = [ZMUser: ClientList]
    public typealias UserProfiles = [Payload.UserProfile]

    struct EventContainer<T: Codable>: Codable {
        enum CodingKeys: String, CodingKey {
            case event
        }

        let event: T
    }

    struct QualifiedUserIDList: Codable, Hashable {

        enum CodingKeys: String, CodingKey {
            case qualifiedIDs = "qualified_ids"
        }

        var qualifiedIDs: [QualifiedID]
    }

    public struct Prekey: Codable {
        let key: String
        let id: Int?

        public init(key: String, id: Int?) {
            self.key = key
            self.id = id
        }
    }

    struct PrekeyByQualifiedUserIDV4: Codable {

        enum CodingKeys: String, CodingKey {
            case prekeyByQualifiedUserID = "qualified_user_client_prekeys"
            case failed = "failed_to_list"
        }

        let prekeyByQualifiedUserID: Payload.PrekeyByQualifiedUserID
        let failed: [QualifiedID]?

    }

    struct Location: Codable, Equatable {

        enum CodingKeys: String, CodingKey {
            case longitude = "lon"
            case latitide = "lat"
        }

        let longitude: Double
        let latitide: Double
    }

    public struct UserClient: Codable, Equatable {

        enum CodingKeys: String, CodingKey {
            case id
            case type
            case creationDate = "time"
            case label
            case location
            case deviceClass = "class"
            case deviceModel = "model"
        }

        let id: String
        let type: String?
        let creationDate: Date?
        let label: String?
        let location: Location?
        let deviceClass: String?
        let deviceModel: String?

        init(id: String,
             deviceClass: String? = nil,
             type: String? = nil,
             creationDate: Date? = nil,
             label: String? = nil,
             location: Location? = nil,
             deviceModel: String? = nil) {
            self.id = id
            self.type = type
            self.creationDate = creationDate
            self.label = label
            self.location = location
            self.deviceClass = deviceClass
            self.deviceModel = deviceModel
        }

    }

    struct Asset: Codable {

        enum AssetSize: String, Codable {
            case preview
            case complete
        }

        enum AssetType: String, Codable {
            case image
        }

        let key: String
        let size: AssetSize
        let type: AssetType
    }

    struct ServiceID: Codable {
        let id: UUID
        let provider: UUID
    }

    struct SSOID: Codable {

        enum CodingKeys: String, CodingKey {
            case tenant
            case subject
            case scimExternalID = "scim_external_id"
        }

        let tenant: String?
        let subject: String?
        let scimExternalID: String?
    }

    enum LegalholdStatus: String, Codable {
        case enabled
        case pending
        case disabled
        case noConsent = "no_consent"
    }

    struct UserProfilesV4: Codable {

        enum CodingKeys: String, CodingKey {
            case found
            case failed
        }

        let found: [Payload.UserProfile]
        let failed: [QualifiedID]?

    }

    public struct UserProfile: Codable {

        enum MessageProtocol: String, Codable {

            case proteus
            case mls

        }

        enum CodingKeys: String, CodingKey, CaseIterable {
            case id
            case qualifiedID = "qualified_id"
            case teamID = "team"
            case serviceID = "service"
            case SSOID = "sso_id"
            case name
            case handle
            case phone
            case email
            case assets
            case managedBy = "managed_by"
            case accentColor = "accent_id"
            case isDeleted = "deleted"
            case expiresAt = "expires_at"
            case legalholdStatus = "legalhold_status"
            case supportedProtocols = "supported_protocols"
        }

        let id: UUID?
        let qualifiedID: QualifiedID?
        let teamID: UUID?
        let serviceID: ServiceID?
        let SSOID: SSOID?
        let name: String?
        let handle: String?
        let phone: String?
        let email: String?
        let assets: [Asset]?
        let managedBy: String?
        let accentColor: Int?
        let isDeleted: Bool?
        let expiresAt: Date?
        let legalholdStatus: LegalholdStatus?
        let supportedProtocols: Set<MessageProtocol>?

        /// All keys which were present in the original payload even if they
        /// contained a null value.
        ///
        /// This is used to distinguish when a delta user profile update does not
        /// contain a field from when it sets the field to nil.
        let updatedKeys: Set<CodingKeys>

        init(id: UUID? = nil,
             qualifiedID: QualifiedID? = nil,
             teamID: UUID? = nil,
             serviceID: ServiceID? = nil,
             SSOID: SSOID? = nil,
             name: String? = nil,
             handle: String? = nil,
             phone: String? = nil,
             email: String? = nil,
             assets: [Asset] = [],
             managedBy: String? = nil,
             accentColor: Int? = nil,
             isDeleted: Bool? = nil,
             expiresAt: Date? = nil,
             legalholdStatus: LegalholdStatus? = nil,
             supportedProtocols: Set<MessageProtocol>? = nil,
             updatedKeys: Set<CodingKeys>? = nil) {

            self.id = id
            self.qualifiedID = qualifiedID
            self.teamID = teamID
            self.serviceID = serviceID
            self.SSOID = SSOID
            self.name = name
            self.handle = handle
            self.phone = phone
            self.email = email
            self.assets = assets
            self.managedBy = managedBy
            self.accentColor = accentColor
            self.isDeleted = isDeleted
            self.expiresAt = expiresAt
            self.legalholdStatus = legalholdStatus
            self.supportedProtocols = supportedProtocols
            self.updatedKeys = updatedKeys ?? Set(CodingKeys.allCases)
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeIfPresent(UUID.self, forKey: .id)
            self.qualifiedID = try container.decodeIfPresent(QualifiedID.self, forKey: .qualifiedID)
            self.teamID = try container.decodeIfPresent(UUID.self, forKey: .teamID)
            self.serviceID = try container.decodeIfPresent(ServiceID.self, forKey: .serviceID)
            self.SSOID = try container.decodeIfPresent(Payload.SSOID.self, forKey: .SSOID)
            self.name = try container.decodeIfPresent(String.self, forKey: .name)
            self.handle = try container.decodeIfPresent(String.self, forKey: .handle)
            self.phone = try container.decodeIfPresent(String.self, forKey: .phone)
            self.email = try container.decodeIfPresent(String.self, forKey: .email)
            self.assets = try container.decodeIfPresent([Payload.Asset].self, forKey: .assets)
            self.managedBy = try container.decodeIfPresent(String.self, forKey: .managedBy)
            self.accentColor = try container.decodeIfPresent(Int.self, forKey: .accentColor)
            self.isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted)
            self.expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
            self.legalholdStatus = try container.decodeIfPresent(LegalholdStatus.self, forKey: .legalholdStatus)
            self.supportedProtocols = try container.decodeIfPresent(Set<MessageProtocol>.self, forKey: .supportedProtocols)
            self.updatedKeys = Set(container.allKeys)
        }
    }

    public struct ResponseFailure: Codable, Equatable {

        /// Endpoints involving federated calls to other domains can return some extra failure responses.
        /// The error response contains the following extra fields:
        public struct FederationFailure: Codable, Equatable {

            public enum FailureType: String, Codable, Equatable {
                case federation
                case unknown
            }

            public init(domain: String, path: String, type: FailureType) {
                self.domain = domain
                self.path = path
                self.type = type
            }

            let domain: String
            let path: String
            let type: FailureType

        }

        public enum Label: String, Codable, Equatable {
            case notFound = "not-found"
            case noEndpoint = "no-endpoint"
            case noIdentity = "no-identity"
            case unknownClient = "unknown-client"
            case missingLegalholdConsent = "missing-legalhold-consent"
            case notConnected = "not-connected"
            case connectionLimit = "connection-limit"
            case federationDenied = "federation-denied"
            case federationRemoteError = "federation-remote-error"
            case mlsStaleMessage = "mls-stale-message"
            case clientNotFound = "client-not-found"
            case invalidCredentials = "invalid-credentials"
            case missingAuth = "missing-auth"
            case badRequest = "bad-request"
            case unknown

            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let label = try container.decode(String.self)
                self = Label(rawValue: label) ?? .unknown
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(self.rawValue)
            }
        }

        public init(code: Int, label: Label, message: String, data: FederationFailure?) {
            self.code = code
            self.label = label
            self.message = message
            self.data = data
        }

        public let code: Int
        public let label: Label
        public let message: String
        public let data: FederationFailure?

    }

    public struct MessageSendingStatusV0: Codable {

        enum CodingKeys: String, CodingKey {
            case time
            case missing
            case redundant
            case deleted
        }

        /// Time of sending message.
        let time: Date

        /// Clients that the message should have been encrypted for, but wasn't.
        let missing: ClientListByUserID

        /// Clients that the message was encrypted for, but isn't necessary. For
        /// example for a client who's user has been removed from the conversation.
        let redundant: ClientListByUserID

        /// Clients that the message was encrypted for, but has since been deleted.
        let deleted: ClientListByUserID
    }

    public struct MessageSendingStatusV1: Codable, Equatable {

        enum CodingKeys: String, CodingKey {
            case time
            case missing
            case redundant
            case deleted
            case failedToSend = "failed_to_send"
        }

        /// Time of sending message.
        let time: Date

        /// Clients that the message should have been encrypted for, but wasn't.
        let missing: ClientListByQualifiedUserID

        /// Clients that the message was encrypted for, but isn't necessary. For
        /// example for a client who's user has been removed from the conversation.
        let redundant: ClientListByQualifiedUserID

        /// Clients that the message was encrypted for, but has since been deleted.
        let deleted: ClientListByQualifiedUserID

        /// When a message is partially sent contains the list of clients which
        /// didn't receive the message.
        let failedToSend: ClientListByQualifiedUserID

        func toAPIModel() -> MessageSendingStatus {
            MessageSendingStatus(
                time: time,
                missing: missing,
                redundant: redundant,
                deleted: deleted,
                failedToSend: failedToSend,
                failedToConfirm: [:]
            )
        }

    }

    public struct MessageSendingStatusV4: Codable, Equatable {

        enum CodingKeys: String, CodingKey {
            case time
            case missing
            case redundant
            case deleted
            case failedToSend = "failed_to_send"
            case failedToConfirm = "failed_to_confirm_clients"
        }

        /// Time of sending message.
        let time: Date

        /// Clients that the message should have been encrypted for, but wasn't.
        let missing: ClientListByQualifiedUserID

        /// Clients that the message was encrypted for, but isn't necessary. For
        /// example for a client who's user has been removed from the conversation.
        let redundant: ClientListByQualifiedUserID

        /// Clients that the message was encrypted for, but has since been deleted.
        let deleted: ClientListByQualifiedUserID

        /// When a message is partially sent contains the list of clients which
        /// didn't receive the message.
        let failedToSend: ClientListByQualifiedUserID

        /// The lists the users for which the client verification could not be performed.
        let failedToConfirm: ClientListByQualifiedUserID

        func toAPIModel() -> MessageSendingStatus {
            MessageSendingStatus(
                time: time,
                missing: missing,
                redundant: redundant,
                deleted: deleted,
                failedToSend: failedToSend,
                failedToConfirm: failedToConfirm
            )
        }
    }

    public struct MessageSendingStatus: Equatable {

        public init(
            time: Date,
            missing: ClientListByQualifiedUserID,
            redundant: ClientListByQualifiedUserID,
            deleted: ClientListByQualifiedUserID,
            failedToSend: ClientListByQualifiedUserID,
            failedToConfirm: ClientListByQualifiedUserID
        ) {
            self.time = time
            self.missing = missing
            self.redundant = redundant
            self.deleted = deleted
            self.failedToSend = failedToSend
            self.failedToConfirm = failedToConfirm
        }

        /// Time of sending message.
        let time: Date

        /// Clients that the message should have been encrypted for, but wasn't.
        let missing: ClientListByQualifiedUserID

        /// Clients that the message was encrypted for, but isn't necessary. For
        /// example for a client who's user has been removed from the conversation.
        let redundant: ClientListByQualifiedUserID

        /// Clients that the message was encrypted for, but has since been deleted.
        let deleted: ClientListByQualifiedUserID

        /// When a message is partially sent contains the list of clients which
        /// didn't receive the message.
        let failedToSend: ClientListByQualifiedUserID

        /// The lists the users for which the client verification could not be performed.
        let failedToConfirm: ClientListByQualifiedUserID
    }

    public struct MLSMessageSendingStatus: Codable {

        enum CodingKeys: String, CodingKey {
            case time
            case events
            case failedToSend = "failed_to_send"
        }

        public init(time: Date, events: [Data], failedToSend: [QualifiedID]?) {
            self.time = time
            self.events = events
            self.failedToSend = failedToSend
        }

        /// Time of sending message.
        let time: Date

        /// A list of events caused by sending the message.
        let events: [Data]

        /// List of federated users who could not be reached and did not receive the message.
        let failedToSend: [QualifiedID]?

    }

    struct PaginationStatus: Codable {

        enum CodingKeys: String, CodingKey {
            case pagingState = "paging_state"
            case size
        }

        let pagingState: String?
        let size: Int?

        init(pagingState: String?, size: Int) {
            self.pagingState = pagingState?.isEmpty == true ? nil : pagingState
            self.size = size
        }
    }

}

extension Payload.ResponseFailure {

    func updateExpirationReason(for message: OTREntity, with reason: MessageSendFailure) {
        message.expirationReasonCode = NSNumber(value: reason.rawValue)
    }

}
