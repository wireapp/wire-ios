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

class UserClientsAPIV0: UserClientsAPI, VersionedAPI {

    let apiService: any APIServiceProtocol

    init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    var apiVersion: APIVersion {
        .v0
    }

    func registerClient(newClient: NewClient) async throws -> SelfUserClient {
        let body = try JSONEncoder.defaultEncoder.encode(newClient.toNetworkModel())

        let path = "\(pathPrefix)/clients"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(
                code: .created,
                type: SelfUserClientV0.self
            )
            .failure(
                code: .badRequest,
                error: UserClientsAPIError.invalidBody
            )
            .failure(
                code: .badRequest,
                label: "bad-request",
                error: UserClientsAPIError.malformedPrekeysUploaded
            )
            .failure(
                code: .forbidden,
                label: "code-authentication-required",
                error: UserClientsAPIError.codeAuthenticationRequired
            )
            .failure(
                code: .forbidden,
                label: "code-authentication-failed",
                error: UserClientsAPIError.codeAuthenticationFailed
            )
            .failure(
                code: .forbidden,
                label: "missing-auth",
                error: UserClientsAPIError.missingAuth
            )
            .failure(
                code: .forbidden,
                label: "too-many-clients",
                error: UserClientsAPIError.tooManyClients
            )
            .parse(
                code: response.statusCode,
                data: data
            )
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
            UserClientsRequestV0(qualifiedIDs: Array(userIDs.map { $0.toNetworkModel() }))
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

    func updateClient(id: UserClientID, clientUpdate: ClientUpdate) async throws {
        let body = try JSONEncoder.defaultEncoder.encode(clientUpdate.toNetworkModel())

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
    let type: UserClientTypeV0
    let activationDate: UTCTime?
    let label: String?
    let model: String?
    let deviceClass: DeviceClassV0?
    let lastActiveDate: UTCTime?
    let mlsPublicKeys: MLSPublicKeysV0?
    let cookie: String?
    let capabilities: CapabilitiesList?

    struct CapabilitiesList: Decodable {

        let capabilities: [UserClientCapabilityV0]

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
            type: type.toAPIModel(),
            activationDate: activationDate?.date,
            label: label,
            model: model,
            deviceClass: deviceClass?.toAPIModel(),
            lastActiveDate: lastActiveDate?.date,
            mlsPublicKeys: mlsPublicKeys?.toAPIModel(),
            cookie: cookie,
            capabilities: capabilities?.capabilities.map { $0.toAPIModel() } ?? []
        )
    }

}

struct UserClientsRequestV0: Encodable {

    let qualifiedIDs: [QualifiedIDV0]

    enum CodingKeys: String, CodingKey {
        case qualifiedIDs = "qualified_users"
    }

}

struct OtherUserClientV0: Decodable, ToAPIModelConvertible {

    let id: String
    let deviceClass: DeviceClassV0?

    enum CodingKeys: String, CodingKey {
        case id
        case deviceClass = "class"
    }

    func toAPIModel() -> OtherUserClient {
        OtherUserClient(id: id, deviceClass: deviceClass?.toAPIModel())
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
    let capabilities: [UserClientCapabilityV0]?

    /// A label describing the client.

    let label: String?

    /// The last resort Prekey

    let lastKey: PrekeyV0?

    /// The mls public keys for the client.

    let mlsPublicKeys: MLSPublicKeysV0?

    /// New prekeys for other clients to establish OTR sessions.

    let preKeys: [PrekeyV0]?
}

extension ClientUpdate {

    func toNetworkModel() -> ClientUpdateV0 {
        ClientUpdateV0(
            capabilities: capabilities?.map { $0.toNetworkModel() },
            label: label,
            lastKey: lastKey?.toNetworkModel(),
            mlsPublicKeys: mlsPublicKeys?.toNetworkModel(),
            preKeys: preKeys?.map { $0.toNetworkModel() }
        )
    }
}

struct NewClientV0: Equatable, Sendable, Encodable {

    enum CodingKeys: String, CodingKey {
        case prekeys
        case lastkey
        case type
        case capabilities
        case deviceClass = "class"
        case cookie
        case label
        case model
        case password
        case verificationCode = "verification_code"
        case mlsPublicKeys = "mls_public_keys"
    }

    let prekeys: [PrekeyV0]
    let lastkey: PrekeyV0
    let type: UserClientTypeV0
    let capabilities: [UserClientCapabilityV0]?
    let deviceClass: DeviceClassV0?
    let cookie: String?
    let label: String?
    let model: String?
    let password: String?
    let verificationCode: String?
    let mlsPublicKeys: MLSPublicKeysV0?

}

extension UserClientType: ToNetworkConvertible {

    func toNetworkModel() -> UserClientTypeV0 {
        switch self {
        case .permanent:
            .permanent
        case .temporary:
            .temporary
        case .legalhold:
            .legalhold
        }
    }

}

extension DeviceClass: ToNetworkConvertible {

    func toNetworkModel() -> DeviceClassV0 {
        switch self {
        case .phone:
            .phone
        case .tablet:
            .tablet
        case .desktop:
            .desktop
        case .legalhold:
            .legalhold
        }
    }

}

extension NewClient {

    func toNetworkModel() -> NewClientV0 {
        NewClientV0(
            prekeys: prekeys.map { $0.toNetworkModel() },
            lastkey: lastkey.toNetworkModel(),
            type: type.toNetworkModel(),
            capabilities: capabilities?.map { $0.toNetworkModel() },
            deviceClass: deviceClass?.toNetworkModel(),
            cookie: cookie,
            label: label,
            model: model,
            password: password,
            verificationCode: verificationCode,
            mlsPublicKeys: mlsPublicKeys?.toNetworkModel()
        )
    }

}
