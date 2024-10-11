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

class ClientAPIV0: ClientAPI, VersionedAPI {

    let httpClient: any HTTPClient

    init(httpClient: any HTTPClient) {
        self.httpClient = httpClient
    }

    var apiVersion: APIVersion {
        .v0
    }

    func getSelfClients() async throws -> [UserClient] {
        let request = HTTPRequest(
            path: "\(pathPrefix)/clients",
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: ListUserClientV0.self)
            .parse(response)
    }

    func getClients(for userIDs: Set<UserID>) async throws -> [UserClients] {
        let body = try JSONEncoder.defaultEncoder.encode(UserClientsRequestV0(qualifiedIDs: Array(userIDs)))
        let request = HTTPRequest(
            path: "/users/list-clients/v2", /// v2 suffix required for api version v0 and v1, suffix removed from next versions
            method: .post,
            body: body
        )

        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: UserClientsV0.self)
            .parse(response)
    }
}

struct ListUserClientV0: Decodable, ToAPIModelConvertible {

    let payload: [UserClientV0]

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let payload = try container.decode([UserClientV0].self)
        self.payload = payload
    }

    func toAPIModel() -> [UserClient] {
        payload.map { $0.toAPIModel() }
    }
}

struct UserClientV0: Decodable, ToAPIModelConvertible {

    let id: String
    let type: UserClientType
    let activationDate: UTCTimeMillis
    let label: String?
    let model: String?
    let deviceClass: DeviceClass?
    let lastActiveDate: UTCTime?
    let mlsPublicKeys: MLSPublicKeys?
    let cookie: String?
    let capabilities: CapabilitiesList?

    struct CapabilitiesList: Decodable {

        let capabilities: [UserClientCapability]

    }

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

    func toAPIModel() -> UserClient {
        UserClient(
            id: id,
            type: type,
            activationDate: activationDate.date,
            label: label,
            model: model,
            deviceClass: deviceClass,
            lastActiveDate: lastActiveDate?.date,
            mlsPublicKeys: mlsPublicKeys,
            cookie: cookie,
            capabilities: capabilities?.capabilities ?? []
        )
    }

}

struct UserClientsRequestV0: Encodable {

    let qualifiedIDs: [UserID]

    enum CodingKeys: String, CodingKey {
        case qualifiedIDs = "qualified_users"
    }

}

struct UserClientsV0: Decodable, ToAPIModelConvertible {
    typealias Domain = String
    typealias UserID = String

    let payload: [Domain: [UserID: [SimplifiedUserClient]]]

    enum CodingKeys: String, CodingKey {
        case qualifiedUserMap = "qualified_user_map"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let payload = try container.decode(
            [Domain: [UserID: [SimplifiedUserClient]]].self,
            forKey: .qualifiedUserMap
        )

        self.payload = payload
    }

    func toAPIModel() -> [UserClients] {
        let userClients = payload.reduce(into: [UserClients]()) { partialResult, dict in
            let domain = dict.key

            for (userID, userClients) in dict.value {
                let userClients = UserClients(
                    domain: domain,
                    userID: UUID(uuidString: userID)!,
                    clients: userClients
                )
                partialResult.append(userClients)
            }
        }

        return userClients
    }

}
