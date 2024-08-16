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

struct UserUpdateEventDecoder {

    func decode(
        from container: KeyedDecodingContainer<UserEventCodingKeys>
    ) throws -> UserUpdateEvent {
        let payload = try container.decode(
            Payload.self,
            forKey: .user
        )

        return UserUpdateEvent(
            userID: payload.userID,
            accentColorID: payload.accentColorID,
            name: payload.name,
            handle: payload.handle,
            email: payload.email,
            isSSOIDDeleted: payload.isSSOIDDeleted,
            assets: payload.assets,
            supportedProtocols: payload.supportedProtocols
        )
    }

    private struct Payload: Decodable {

        let userID: UUID
        let accentColorID: Int?
        let name: String?
        let handle: String?
        let email: String?
        let isSSOIDDeleted: Bool?
        let assets: [UserAsset]?
        let supportedProtocols: Set<MessageProtocol>?

        enum CodingKeys: String, CodingKey {

            case userID = "id"
            case accentColorID = "accent_id"
            case name
            case handle
            case email
            case isSSOIDDeleted = "sso_id_deleted"
            case assets
            case supportedProtocols = "supported_protocols"

        }

    }

}
