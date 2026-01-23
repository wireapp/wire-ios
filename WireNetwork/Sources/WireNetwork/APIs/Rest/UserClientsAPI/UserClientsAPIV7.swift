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

class UserClientsAPIV7: UserClientsAPIV6 {

    override var apiVersion: APIVersion { .v7 }

    override func getSelfClients() async throws -> [SelfUserClient] {
        let path = "\(pathPrefix)/clients"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: ListUserClientV7.self)
            .parse(code: response.statusCode, data: data)
    }

    override func registerClient(newClient: NewClient) async throws -> SelfUserClient {
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
                type: SelfUserClientV7.self
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
}

// SelfUserClientV7.capabilities is now a list and not nested within another object anymore.

private struct ListUserClientV7: Decodable, ToAPIModelConvertible {

    let payload: [SelfUserClientV7]

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let payload = try container.decode([SelfUserClientV7].self)
        self.payload = payload
    }

    func toAPIModel() -> [SelfUserClient] {
        payload.map { $0.toAPIModel() }
    }
}

private struct SelfUserClientV7: Decodable, ToAPIModelConvertible {

    let id: String
    let type: UserClientTypeV0
    let activationDate: UTCTime?
    let label: String?
    let model: String?
    let deviceClass: DeviceClassV0?
    let lastActiveDate: UTCTime?
    let mlsPublicKeys: MLSPublicKeysV0?
    let cookie: String?
    let capabilities: [UserClientCapabilityV0]? // not of type `CapabilitiesList` anymore

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
            capabilities: capabilities?.map { $0.toAPIModel() } ?? []
        )
    }

}
