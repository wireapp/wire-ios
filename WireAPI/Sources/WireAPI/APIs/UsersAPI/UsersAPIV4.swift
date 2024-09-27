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

// MARK: - UsersAPIV4

class UsersAPIV4: UsersAPIV3 {
    override var apiVersion: APIVersion {
        .v4
    }

    override func getUser(for userID: UserID) async throws -> User {
        let request = HTTPRequest(
            path: "\(pathPrefix)/users/\(userID.domain)/\(userID.uuid.transportString())",
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: UserResponseV4.self)
            .failure(code: .notFound, label: "not-found", error: UsersAPIError.userNotFound)
            .parse(response)
    }

    override func getUsers(userIDs: [UserID]) async throws -> UserList {
        let body = try JSONEncoder.defaultEncoder.encode(ListUsersRequestV0(qualifiedIDs: userIDs))
        let request = HTTPRequest(
            path: "\(pathPrefix)/list-users",
            method: .post,
            body: body
        )

        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: UserListResponseV4.self)
            .parse(response)
    }
}

// MARK: - UserListResponseV4

struct UserListResponseV4: Decodable, ToAPIModelConvertible {
    /// List of users which were found and succesfully retrieved.

    let found: [UserResponseV4]

    /// List of user IDs for which a user couldn't be retrieved.
    ///
    let failed: [UserID]?

    func toAPIModel() -> UserList {
        UserList(found: found.map { $0.toAPIModel() }, failed: failed ?? [])
    }
}

// MARK: - UserResponseV4

struct UserResponseV4: Decodable, ToAPIModelConvertible {
    let id: UserID
    let name: String
    let handle: String?
    let teamID: UUID?
    let accentID: Int
    let assets: [UserAsset]
    let deleted: Bool?
    let email: String?
    let expiresAt: UTCTimeMillis?
    let service: ServiceResponseV0?
    let supportedProtocols: Set<MessageProtocol>?
    let legalholdStatus: LegalholdStatusV0

    enum CodingKeys: String, CodingKey {
        case id = "qualified_id"
        case name
        case handle
        case teamID = "team"
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
        User(
            id: id,
            name: name,
            handle: handle,
            teamID: teamID,
            accentID: accentID,
            assets: assets,
            deleted: deleted,
            email: email,
            expiresAt: expiresAt?.date,
            service: service?.toAPIModel(),
            supportedProtocols: supportedProtocols,
            legalholdStatus: legalholdStatus.toAPIModel()
        )
    }
}
