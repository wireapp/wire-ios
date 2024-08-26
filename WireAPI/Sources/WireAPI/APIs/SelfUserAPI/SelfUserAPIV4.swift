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

class SelfUserAPIV4: SelfUserAPIV3 {

    override var apiVersion: APIVersion {
        .v4
    }

    override func getSelfUser() async throws -> SelfUser {
        let request = HTTPRequest(
            path: "\(pathPrefix)/self",
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: SelfUserV4.self)
            .parse(response)
    }

}

struct SelfUserV4: Decodable, ToAPIModelConvertible {

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
    let supportedProtocols: Set<MessageProtocol>?
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
            supportedProtocols: supportedProtocols ?? [.proteus]
        )
    }
}
