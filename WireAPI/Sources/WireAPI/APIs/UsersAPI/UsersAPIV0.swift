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

class UsersAPIV0: UsersAPI, VersionedAPI {

    let apiService: any APIServiceProtocol

    init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    var apiVersion: APIVersion {
        .v0
    }

    // MARK: - Get team

    func getUser(for userID: UserID) async throws -> User {
        let components = URLComponents(string: "\(pathPrefix)/users/\(userID.domain)/\(userID.uuid.transportString())")

        guard let url = components?.url else {
            assertionFailure("generated an invalid url")
            throw UsersAPIError.invalidURL
        }

        let request = URLRequestBuilder(url: url)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: UserResponseV0.self)
            .failure(code: .notFound, label: "not-found", error: UsersAPIError.userNotFound)
            .parse(code: response.statusCode, data: data)
    }

    func getUsers(userIDs: [UserID]) async throws -> UserList {
        let body = try JSONEncoder.defaultEncoder.encode(ListUsersRequestV0(qualifiedIDs: userIDs))

        let components = URLComponents(string: "\(pathPrefix)/list-users")

        guard let url = components?.url else {
            assertionFailure("generated an invalid url")
            throw UsersAPIError.invalidURL
        }

        let request = URLRequestBuilder(url: url)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: ListUsersResponseV0.self)
            .parse(code: response.statusCode, data: data)
    }
}

struct UserResponseV0: Decodable, ToAPIModelConvertible {

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
            supportedProtocols: [.proteus],
            legalholdStatus: legalholdStatus.toAPIModel()
        )
    }
}

struct ListUsersRequestV0: Encodable {

    let qualifiedIDs: [QualifiedID]

    enum CodingKeys: String, CodingKey {

        case qualifiedIDs = "qualified_ids"

    }
}

typealias ListUsersResponseV0 = [UserResponseV0]

extension ListUsersResponseV0: ToAPIModelConvertible {
    func toAPIModel() -> UserList {
        UserList(found: map { $0.toAPIModel() }, failed: [])
    }
}

struct ServiceResponseV0: Decodable, ToAPIModelConvertible {

    let id: UUID
    let provider: UUID

    func toAPIModel() -> Service {
        Service(id: id, provider: provider)
    }
}
