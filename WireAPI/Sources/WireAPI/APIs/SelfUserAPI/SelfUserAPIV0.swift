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

// MARK: - SelfUserAPIV0

class SelfUserAPIV0: SelfUserAPI, VersionedAPI {
    // MARK: Lifecycle

    init(httpClient: any HTTPClient) {
        self.httpClient = httpClient
    }

    // MARK: Internal

    let httpClient: any HTTPClient

    var apiVersion: APIVersion {
        .v0
    }

    func getSelfUser() async throws -> SelfUser {
        let request = HTTPRequest(
            path: "\(pathPrefix)/self",
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: SelfUserV0.self)
            .parse(response)
    }

    func pushSupportedProtocols(_: Set<MessageProtocol>) async throws {
        throw SelfUserAPIError.unsupportedEndpointForAPIVersion
    }
}

// MARK: - SelfUserV0

struct SelfUserV0: Decodable, ToAPIModelConvertible {
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
    }

    let accentID: Int
    let assets: [UserAsset]?
    let deleted: Bool?
    let email: String?
    let expiresAt: UTCTimeMillis?
    let handle: String?
    let id: UUID
    let locale: String
    let managedBy: ManagedByV0?
    let name: String
    let phone: String?
    let picture: [String]?
    let qualifiedID: UserID
    let service: ServiceResponseV0?
    let ssoID: SSOIDV0?
    let teamID: UUID?

    func toAPIModel() -> SelfUser {
        SelfUser(
            id: id,
            qualifiedID: qualifiedID,
            ssoID: ssoID?.toAPIModel(),
            name: name,
            handle: handle,
            teamID: teamID,
            phone: phone,
            accentID: accentID,
            managedBy: managedBy?.toAPIModel(),
            assets: assets,
            deleted: deleted,
            email: email,
            expiresAt: expiresAt?.date,
            service: service?.toAPIModel(),
            supportedProtocols: [.proteus] /// default to Proteus for api versions < v5
        )
    }
}

// MARK: - ManagedByV0

enum ManagedByV0: String, Decodable, ToAPIModelConvertible {
    case wire
    case scim

    // MARK: Internal

    func toAPIModel() -> ManagingSystem {
        switch self {
        case .wire:
            .wire
        case .scim:
            .scim
        }
    }
}

// MARK: - SSOIDV0

struct SSOIDV0: Decodable, ToAPIModelConvertible {
    enum CodingKeys: String, CodingKey {
        case scimExternalId = "scim_external_id"
        case subject, tenant
    }

    let scimExternalId: String
    let subject: String
    let tenant: String

    func toAPIModel() -> SSOID {
        SSOID(
            scimExternalId: scimExternalId,
            subject: subject,
            tenant: tenant
        )
    }
}
