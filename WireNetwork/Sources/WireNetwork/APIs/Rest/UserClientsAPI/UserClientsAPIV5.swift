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

class UserClientsAPIV5: UserClientsAPIV4 {

    override var apiVersion: APIVersion {
        .v5
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
                type: SelfUserClientV5.self
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

struct SelfUserClientV5: Decodable, ToAPIModelConvertible {

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

struct NewClientV5: Equatable, Sendable, Encodable {

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

    func toNetworkModel() -> NewClientV5 {
        NewClientV5(
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
