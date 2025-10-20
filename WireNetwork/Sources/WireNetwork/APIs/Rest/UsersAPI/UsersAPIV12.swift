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

final class UsersAPIV12: UsersAPIV11 {
    override var apiVersion: APIVersion { .v12 }
}

struct UserResponseV12: Decodable, ToAPIModelConvertible {

    let id: QualifiedIDV0
    let name: String
    let handle: String?
    let teamID: UUID?
    let type: UserTypeV12?
    let accentID: Int
    let assets: [UserAssetV0]
    let deleted: Bool?
    let email: String?
    let expiresAt: UTCTime?
    let service: ServiceResponseV0?
    let legalholdStatus: LegalholdStatusV0

    enum CodingKeys: String, CodingKey {

        case id = "qualified_id"
        case name
        case handle
        case teamID = "team"
        case type
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
            id: id.toAPIModel(),
            name: name,
            handle: handle,
            teamID: teamID,
            accentID: accentID,
            type: type,
            assets: assets.map { $0.toAPIModel() },
            deleted: deleted,
            email: email,
            expiresAt: expiresAt?.date,
            service: service?.toAPIModel(),
            supportedProtocols: [.proteus],
            legalholdStatus: legalholdStatus.toAPIModel()
        )
    }

}
