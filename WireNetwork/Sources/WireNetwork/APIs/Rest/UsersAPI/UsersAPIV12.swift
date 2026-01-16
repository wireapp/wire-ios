//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

class UsersAPIV12: UsersAPIV11 {

    override var apiVersion: APIVersion {
        .v12
    }

    override func getUser(for userID: UserID) async throws -> User {
        let path = "\(pathPrefix)/users/\(userID.domain)/\(userID.id.transportString())"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: UserResponseV12.self)
            .failure(code: .notFound, label: "not-found", error: UsersAPIError.userNotFound)
            .parse(code: response.statusCode, data: data)
    }

    override func getUsers(userIDs: [UserID]) async throws -> UserList {
        let body = try JSONEncoder.defaultEncoder
            .encode(ListUsersRequestV0(qualifiedIDs: userIDs.map { $0.toNetworkModel() }))
        let path = "\(pathPrefix)/list-users"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: UserListResponseV12.self)
            .parse(code: response.statusCode, data: data)
    }
}

struct UserListResponseV12: Decodable, ToAPIModelConvertible {

    /// List of users which were found and successfully retrieved.

    let found: [UserResponseV12]

    /// List of user IDs for which a user couldn't be retrieved.

    let failed: [QualifiedIDV0]?

    func toAPIModel() -> UserList {
        UserList(
            found: found.map { $0.toAPIModel() },
            failed: failed?.map { $0.toAPIModel() } ?? []
        )
    }
}

struct UserResponseV12: Decodable, ToAPIModelConvertible {

    let id: QualifiedIDV0
    let name: String
    let handle: String?
    let teamID: UUID?
    let type: UserTypeV12? // introduced in v12
    let accentID: Int
    let assets: [UserAssetV0]
    let deleted: Bool?
    let email: String?
    let expiresAt: UTCTime?
    let service: ServiceResponseV0?
    let supportedProtocols: Set<MessageProtocolV0>?
    let legalholdStatus: LegalholdStatusV0

    enum CodingKeys: String, CodingKey {

        case id = "qualified_id"
        case name
        case handle
        case teamID = "team"
        case type
        case accentID = "accent_id"
        case assets
        case deleted
        case email
        case expiresAt = "expires_at"
        case service
        case supportedProtocols = "supported_protocols"
        case legalholdStatus = "legalhold_status"

    }

    func toAPIModel() -> User {
        let supportedProtocols = supportedProtocols?.map { $0.toAPIModel() }
        return User(
            id: id.toAPIModel(),
            name: name,
            handle: handle,
            teamID: teamID,
            type: type?.toAPIModel(),
            accentID: accentID,
            assets: assets.map { $0.toAPIModel() },
            deleted: deleted,
            email: email,
            expiresAt: expiresAt?.date,
            service: service?.toAPIModel(),
            supportedProtocols: supportedProtocols.flatMap { Set($0) },
            legalholdStatus: legalholdStatus.toAPIModel()
        )
    }

}

enum UserTypeV12: String, Decodable {

    case regular
    case app
    case bot

    func toAPIModel() -> UserType {
        switch self {
        case .regular:
            .regular
        case .app:
            .app
        case .bot:
            .bot
        }
    }

}
