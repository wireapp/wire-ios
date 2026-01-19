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

class SelfUserAPIV0: SelfUserAPI, VersionedAPI {

    let apiService: any APIServiceProtocol

    init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    var apiVersion: APIVersion {
        .v0
    }

    var resourcePath: String {
        "\(pathPrefix)/self"
    }

    func getSelfUser() async throws -> SelfUser {
        let request = try URLRequestBuilder(path: resourcePath)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: SelfUserV0.self)
            .parse(code: response.statusCode, data: data)
    }

    func pushSupportedProtocols(_: Set<MessageProtocol>) async throws {
        throw SelfUserAPIError.unsupportedEndpointForAPIVersion
    }

    func deleteSelf(password: String) async throws {
        let body = try JSONEncoder.defaultEncoder.encode(
            DeleteSelfRequestBodyV0(password: password)
        )

        let request = try URLRequestBuilder(path: resourcePath)
            .withMethod(.delete)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(request, requiringAccessToken: true)
        return try ResponseParser()
            .success(code: .ok)
            .parse(code: response.statusCode, data: data)

    }

    func deleteTeam(teamId: UUID, password: String, verificationCode: String) async throws {
        let body = try JSONEncoder.defaultEncoder.encode(
            DeleteTeamRequestBodyV0(password: password, verificationCode: verificationCode)
        )

        let request = try URLRequestBuilder(path: "\(pathPrefix)/teams/\(teamId)")
            .withMethod(.delete)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(request, requiringAccessToken: true)
        return try ResponseParser()
            .success(code: .accepted)
            .parse(code: response.statusCode, data: data)
    }

    func updateHandle(handle: String) async throws {
        let body = try JSONEncoder.defaultEncoder.encode(
            UpdateHandleRequestBodyV0(handle: handle)
        )

        let request = try URLRequestBuilder(path: "\(resourcePath)/handle")
            .withMethod(.put)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(request, requiringAccessToken: true)
        return try ResponseParser()
            .success(code: .ok)
            .parse(code: response.statusCode, data: data)
    }

}

struct SelfUserV0: Decodable, ToAPIModelConvertible {

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
    // removed picture from parsing because of wrong format - WPB-20534
    let qualifiedID: QualifiedIDV0
    let service: ServiceResponseV0?
    let ssoID: SSOIDV0?
    let teamID: UUID?

    enum CodingKeys: String, CodingKey {
        case accentID = "accent_id"
        case assets, deleted, email
        case expiresAt = "expires_at"
        case handle, id, locale
        case managedBy = "managed_by"
        case name, phone
        case qualifiedID = "qualified_id"
        case service
        case ssoID = "sso_id"
        case teamID = "team"
    }

    func toAPIModel() -> SelfUser {
        SelfUser(
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
            supportedProtocols: [.proteus] /// default to Proteus for api versions < v5
        )
    }
}

enum ManagedByV0: String, Decodable, ToAPIModelConvertible {
    case wire
    case scim

    func toAPIModel() -> ManagingSystem {
        switch self {
        case .wire:
            .wire
        case .scim:
            .scim
        }
    }
}

struct SSOIDV0: Decodable, ToAPIModelConvertible {

    let scimExternalId: String?
    let subject: String?
    let tenant: String?

    enum CodingKeys: String, CodingKey {
        case scimExternalId = "scim_external_id"
        case subject, tenant
    }

    func toAPIModel() -> SSOID {
        SSOID(
            scimExternalId: scimExternalId,
            subject: subject,
            tenant: tenant
        )
    }
}

private struct DeleteSelfRequestBodyV0: Encodable {
    var password: String
}

private struct UpdateHandleRequestBodyV0: Encodable {
    var handle: String
}

private struct DeleteTeamRequestBodyV0: Encodable {
    var password: String
    var verificationCode: String
}

private struct MigratePersonalToTeamBodyV0: Encodable {
    var icon: String
    var name: String
}
