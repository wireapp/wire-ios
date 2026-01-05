//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

class ConversationsAPIV5: ConversationsAPIV4 {
    override var apiVersion: APIVersion { .v5 }

    var oneToOneConversationsPath: String {
        "\(pathPrefix)\(basePath)/one2one"
    }

    override func getConversations(for identifiers: [QualifiedID]) async throws -> ConversationList {
        guard 1 ... 1000 ~= identifiers.count else {
            throw ConversationsAPIError.illegalArgument(
                message: "identifiers must contain between 1 and 1000 elements, got \(identifiers.count)"
            )
        }

        let parameters = GetConversationsParametersV0(qualifiedIdentifiers: identifiers.map { $0.toNetworkModel() })
        let body = try JSONEncoder.defaultEncoder.encode(parameters)
        let path = "\(pathPrefix)\(basePath)/list"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        // Removed in v5: remove handling of error code 400
        return try ResponseParser()
            .success(code: .ok, type: QualifiedConversationListV5.self)
            .parse(code: response.statusCode, data: data)
    }

    override func getMLSOneToOneConversation(
        userID: String,
        in domain: String
    ) async throws -> (Conversation, MLSPublicKeys?) {
        guard !userID.isEmpty, !domain.isEmpty else {
            throw ConversationsAPIError.userAndDomainShouldNotBeEmpty
        }

        let path = "\(oneToOneConversationsPath)/\(domain)/\(userID)"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        let conversation = try ResponseParser()
            .success(code: .ok, type: ConversationV5.self)
            .failure(code: .badRequest, label: "mls-not-enabled", error: ConversationsAPIError.mlsNotEnabled)
            .failure(code: .forbidden, label: "not-connected", error: ConversationsAPIError.usersNotConnected)
            .parse(code: response.statusCode, data: data)

        return (conversation, nil)
    }

    override func createGroupConversation(
        parameters: CreateGroupConversationParameters
    ) async throws -> Conversation {
        guard parameters.groupType != .channel else {
            throw ConversationsAPIError.unsupportedChannelCreationForAPIEndpoint
        }

        let input = CreateGroupConversationParametersV0(from: parameters)
        let body = try JSONEncoder.defaultEncoder.encode(input)
        let path = "\(pathPrefix)\(basePath)"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        do {
            return try ResponseParser()
                .success(code: .ok, type: ConversationV5.self)
                .success(code: .created, type: ConversationV5.self)
                .failure(code: .badRequest, label: "mls-not-enabled", error: ConversationsAPIError.mlsNotEnabled)
                .failure(
                    code: .badRequest,
                    label: "non-empty-member-list",
                    error: ConversationsAPIError.nonEmptyMemberList
                )
                .failure(code: .badRequest, error: ConversationsAPIError.invalidBody)
                .failure(
                    code: .forbidden,
                    label: "missing-legalhold-consent",
                    error: ConversationsAPIError.missingLegalHoldConsent
                )
                .failure(code: .forbidden, label: "operation-denied", error: ConversationsAPIError.operationDenied)
                .failure(code: .forbidden, label: "no-team-member", error: ConversationsAPIError.noTeamMember)
                .failure(code: .forbidden, label: "not-connected", error: ConversationsAPIError.notConnected)
                .failure(code: .forbidden, label: "access-denied", error: ConversationsAPIError.accessDenied)
                .failure(code: .conflict, decodableError: NonFederatingBackendErrorResponseV4.self)
                .failure(code: .unreachable, error: ConversationsAPIError.unreachableBackends)
                .parse(code: response.statusCode, data: data)
        } catch {
            if let nonFederatingDomains = error as? NonFederatingBackendErrorResponseV4 {
                throw ConversationsAPIError.nonFederatingBackends(
                    nonFederatingDomains.nonFederatingBackends
                )
            } else {
                throw error
            }
        }
    }

    override func updateConversationAccess(
        conversationID: QualifiedID,
        allowGuests: Bool,
        allowApps: Bool
    ) async throws {

        // Build access roles based on allowGuests and allowApps
        var accessRoles: Set<ConversationAccessRole> = [.teamMember]
        if allowGuests {
            accessRoles.insert(.guest)
            accessRoles.insert(.nonTeamMember)
        }
        if allowApps {
            accessRoles.insert(.app)
        }

        // Build access modes based on allowGuests
        var accessModes = Set<ConversationAccessMode>()
        if allowGuests {
            accessModes = [.invite, .code]
        }

        let parameters = UpdateConversationAccessParametersV0(
            accessModes: accessModes.map { $0.toNetworkModel() },
            accessRoles: accessRoles.map { $0.toNetworkModel() }
        )
        let body = try JSONEncoder.defaultEncoder.encode(parameters)
        let path = "\(pathPrefix)\(basePath)/\(conversationID.domain)/\(conversationID.id)/access"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.put)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        try ResponseParser()
            .success(code: .ok)
            .success(code: .noContent)
            .failure(code: .forbidden, label: "invalid-op", error: ConversationsAPIError.invalidOperation)
            .failure(code: .forbidden, label: "access-denied", error: ConversationsAPIError.accessDenied)
            .failure(code: .forbidden, label: "action-denied", error: ConversationsAPIError.insufficienAuthorization)
            .failure(code: .notFound, label: "no-conversation", error: ConversationsAPIError.conversationNotFound)
            .parse(code: response.statusCode, data: data)
    }

}

// MARK: Decodables

private struct QualifiedConversationListV5: Decodable, ToAPIModelConvertible {
    enum CodingKeys: String, CodingKey {
        case found
        case notFound = "not_found"
        case failed
    }

    let found: [ConversationV5]
    let notFound: [QualifiedIDV0]
    let failed: [QualifiedIDV0]

    func toAPIModel() -> ConversationList {
        ConversationList(
            found: found.map { $0.toAPIModel() },
            notFound: notFound.map { $0.toAPIModel() },
            failed: failed.map { $0.toAPIModel() }
        )
    }
}

struct ConversationV5: Decodable, ToAPIModelConvertible, DecodableConversation {
    enum CodingKeys: String, CodingKey {
        case access
        case accessRoles = "access_role"
        case cipherSuite = "cipher_suite"
        case creator
        case epoch
        case epochTimestamp = "epoch_timestamp"
        case id
        case lastEvent = "last_event"
        case lastEventTime = "last_event_time"
        case members
        case messageProtocol = "protocol"
        case messageTimer = "message_timer"
        case mlsGroupID = "group_id"
        case name
        case qualifiedID = "qualified_id"
        case readReceiptMode = "receipt_mode"
        case teamID = "team"
        case type
    }

    var access: Set<ConversationAccessModeV0>?
    var accessRoles: Set<ConversationAccessRoleV0>?
    var cipherSuite: MLSCipherSuiteV0? // New field
    var creator: UUID?
    var epoch: UInt?
    var epochTimestamp: UTCTime? // New field
    var id: UUID?
    var lastEvent: String?
    var lastEventTime: UTCTime?
    var members: QualifiedConversationMembersV0?
    var messageProtocol: ConversationMessageProtocolV0?
    var messageTimer: TimeInterval?
    var mlsGroupID: String?
    var name: String?
    var qualifiedID: QualifiedIDV0?
    var readReceiptMode: Int?
    var teamID: UUID?
    var type: ConversationTypeV0?

    func toAPIModel() -> Conversation {
        let access = access?.map { $0.toAPIModel() }
        let accessRoles = accessRoles?.map { $0.toAPIModel() }
        return Conversation(
            id: id,
            qualifiedID: qualifiedID?.toAPIModel(),
            teamID: teamID,
            type: type?.toAPIModel(),
            messageProtocol: messageProtocol?.toAPIModel(),
            mlsGroupID: mlsGroupID,
            cipherSuite: cipherSuite?.toAPIModel(),
            epoch: epoch,
            epochTimestamp: epochTimestamp?.date,
            creator: creator,
            members: members.map { $0.toAPIModel() },
            name: name,
            messageTimer: messageTimer,
            readReceiptMode: readReceiptMode,
            access: access.flatMap { Set($0) },
            accessRoles: accessRoles.flatMap { Set($0) },
            legacyAccessRole: nil,
            lastEvent: lastEvent,
            lastEventTime: lastEventTime?.date
        )
    }
}

private struct UpdateConversationAccessParametersV0: Encodable {
    let accessModes: [ConversationAccessModeV0]
    let accessRoles: [ConversationAccessRoleV0]

    enum CodingKeys: String, CodingKey {
        case accessModes = "access"
        case accessRoles = "access_role"
    }
}
