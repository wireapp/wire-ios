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

class UserClientsAPIV0: UserClientsAPI, VersionedAPI {

    let apiService: any APIServiceProtocol

    init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    var apiVersion: APIVersion {
        .v0
    }

    func getSelfClients() async throws -> [SelfUserClient] {
        let path = "\(pathPrefix)/clients"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: ListUserClientV0.self)
            .parse(code: response.statusCode, data: data)
    }

    func getClients(for userIDs: Set<UserID>) async throws -> [OtherUserClients] {
        // v2 suffix required for api version v0 and v1, suffix. Removed from next versions.
        let path = "/users/list-clients/v2"

        let body = try JSONEncoder.defaultEncoder.encode(
            UserClientsRequestV0(qualifiedIDs: Array(userIDs))
        )

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: OtherUserClientsV0.self)
            .parse(code: response.statusCode, data: data)
    }

    func updateClient(id: UserClientID, payload: ClientUpdate) async throws {
        let body = try JSONEncoder.defaultEncoder.encode(payload.toAPIModel())

        let path = "\(pathPrefix)/clients/\(id)"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.put)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok)
            .failure(code: .badRequest, error: UserClientsAPIError.invalidBody)
            .failure(code: .badRequest, label: "bad-request", error: UserClientsAPIError.malformedPrekeysUploaded)
            .failure(code: .notFound, error: UserClientsAPIError.clientNotFound)
            .parse(code: response.statusCode, data: data)
    }
}

struct ListUserClientV0: Decodable, ToAPIModelConvertible {

    let payload: [SelfUserClientV0]

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let payload = try container.decode([SelfUserClientV0].self)
        self.payload = payload
    }

    func toAPIModel() -> [SelfUserClient] {
        payload.map { $0.toAPIModel() }
    }
}

struct SelfUserClientV0: Decodable, ToAPIModelConvertible {

    let id: String
    let type: UserClientType
    let activationDate: UTCTime?
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

    func toAPIModel() -> SelfUserClient {
        SelfUserClient(
            id: id,
            type: type,
            activationDate: activationDate?.date,
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

struct OtherUserClientV0: Decodable, ToAPIModelConvertible {

    let id: String
    let deviceClass: DeviceClass?

    enum CodingKeys: String, CodingKey {
        case id
        case deviceClass = "class"
    }

    func toAPIModel() -> OtherUserClient {
        OtherUserClient(id: id, deviceClass: deviceClass)
    }

}

struct OtherUserClientsV0: Decodable, ToAPIModelConvertible {
    typealias Domain = String
    typealias UserID = String

    let qualifiedUserMap: [Domain: [UserID: [OtherUserClientV0]]]

    enum CodingKeys: String, CodingKey {
        case qualifiedUserMap = "qualified_user_map"
    }

    func toAPIModel() -> [OtherUserClients] {
        qualifiedUserMap.reduce(into: [OtherUserClients]()) { partialResult, dictionary in
            let domain = dictionary.key

            for (userID, userClients) in dictionary.value {
                let userClients = OtherUserClients(
                    domain: domain,
                    userID: UUID(uuidString: userID)!,
                    clients: userClients.map { $0.toAPIModel() }
                )
                partialResult.append(userClients)
            }
        }
    }

}

struct ClientUpdateV0: Equatable, Sendable, Encodable {

    enum CodingKeys: String, CodingKey {
        case label
        case lastKey = "last_key"
        case preKeys = "prekeys"
        case mlsPublicKeys = "mls_public_keys"
        case capabilities

    }

    /// The capabilities of the client.
    /// - Note: capabilities cannot be removed once added to a client,
    ///  so once 1 capability added it must always be present
    let capabilities: [UserClientCapability]?

    /// A label describing the client.

    let label: String?

    /// The last resort Prekey

    let lastKey: Prekey?

    /// The mls public keys for the client.

    let mlsPublicKeys: MLSPublicKeys?

    /// New prekeys for other clients to establish OTR sessions.

    let preKeys: [Prekey]?
}

extension ClientUpdate: ToAPIModelConvertible {

    func toAPIModel() -> ClientUpdateV0 {
        ClientUpdateV0(
            capabilities: capabilities,
            label: label,
            lastKey: lastKey,
            mlsPublicKeys: mlsPublicKeys,
            preKeys: preKeys
        )
    }
}
