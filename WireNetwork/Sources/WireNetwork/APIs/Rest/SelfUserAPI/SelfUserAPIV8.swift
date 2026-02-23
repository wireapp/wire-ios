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

class SelfUserAPIV8: SelfUserAPIV7 {
    override var apiVersion: APIVersion { .v8 }

    override func pushSupportedProtocols(_ supportedProtocols: Set<MessageProtocol>) async throws {
        let encoder = JSONEncoder.defaultEncoder
        let payload =
            SupportedProtocolsPayloadV5(supportedProtocols: Set(supportedProtocols.map { $0.toNetworkModel() }))
        let body = try encoder.encode(payload)
        let path = resourcePath + "/supported-protocols"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.put)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        do {
            try ResponseParser()
                .success(code: .ok)
                .failure(code: .conflict, decodableError: FailureResponseV0.self)
                .parse(code: response.statusCode, data: data)
        } catch {
            if let failureResponse = error as? FailureResponseV0,
               failureResponse.label == "mls-protocol-error",
               failureResponse.code == HTTPStatusCode.conflict.rawValue {
                throw SelfUserAPIError.mlsProtocolError(failureResponse.message)
            } else {
                throw error
            }
        }
    }

    override func getSelfUser() async throws -> SelfUser {
        let request = try URLRequestBuilder(path: resourcePath)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: SelfUserV8.self)
            .parse(code: response.statusCode, data: data)
    }
}

struct SelfUserV8: Decodable, ToAPIModelConvertible {

    let accentID: Int
    let assets: [UserAssetV0]?
    let deleted: Bool?
    let email: String?
    let expiresAt: UTCTime?
    let handle: String?
    let id: UUID
    let locale: String
    let managedBy: ManagedByV0?
    let name: String
    let phone: String?
    let picture: [String]?
    let qualifiedID: QualifiedIDV0
    let service: ServiceResponseV0?
    let ssoID: SSOIDV0?
    let supportedProtocols: Set<MessageProtocolV0>?
    let teamID: UUID?

    enum CodingKeys: String, CodingKey {
        case accentID = "accent_id"
        case assets, deleted, email
        case expiresAt = "expires_at"
        case handle, id, locale
        case managedBy = "managed_by"
        case name, phone, picture
        case qualifiedID = "qualified_id"
        case service
        case ssoID = "sso_id"
        case teamID = "team"
        case supportedProtocols = "supported_protocols"
    }

    func toAPIModel() -> SelfUser {
        let supportedProtocols = supportedProtocols?.map { $0.toAPIModel() } ?? [.proteus]
        return SelfUser(
            id: id,
            qualifiedID: qualifiedID.toAPIModel(),
            ssoID: ssoID?.toAPIModel(),
            name: name,
            handle: handle,
            teamID: teamID,
            phone: phone,
            accentID: accentID,
            managedBy: managedBy?.toAPIModel(),
            assets: assets?.map { $0.toAPIModel() },
            deleted: deleted,
            email: email,
            expiresAt: expiresAt?.date,
            service: service?.toAPIModel(),
            supportedProtocols: Set(supportedProtocols)
        )
    }
}
