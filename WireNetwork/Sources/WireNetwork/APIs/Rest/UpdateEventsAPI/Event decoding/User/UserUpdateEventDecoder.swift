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

struct UserUpdateEventDecoder {

    func decode(
        from container: KeyedDecodingContainer<UserEventCodingKeys>
    ) throws -> UserUpdateEvent {
        let payload = try container.decode(
            Payload.self,
            forKey: .user
        )

        let supportedProtocols = payload.supportedProtocols?.map { $0.toAPIModel() }
        return UserUpdateEvent(
            userID: payload.userID,
            accentColorID: payload.accentColorID,
            name: payload.name,
            handle: payload.handle,
            email: payload.email,
            isSSOIDDeleted: payload.isSSOIDDeleted,
            assets: payload.assets?.map { $0.toAPIModel() },
            supportedProtocols: supportedProtocols.flatMap { Set($0) },
            textStatus: payload.textStatus,
            isTextStatusPresent: payload.isTextStatusPresent
        )
    }

    private struct Payload: Decodable {

        let userID: UUID
        let accentColorID: Int?
        let name: String?
        let handle: String?
        let email: String?
        let isSSOIDDeleted: Bool?
        let assets: [UserAssetV0]?
        let supportedProtocols: Set<MessageProtocolV0>?
        let textStatus: String?
        let isTextStatusPresent: Bool

        enum CodingKeys: String, CodingKey {

            case userID = "id"
            case accentColorID = "accent_id"
            case name
            case handle
            case email
            case isSSOIDDeleted = "sso_id_deleted"
            case assets
            case supportedProtocols = "supported_protocols"
            case textStatus = "text_status"

        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            userID = try container.decode(UUID.self, forKey: .userID)
            accentColorID = try container.decodeIfPresent(Int.self, forKey: .accentColorID)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            handle = try container.decodeIfPresent(String.self, forKey: .handle)
            email = try container.decodeIfPresent(String.self, forKey: .email)
            isSSOIDDeleted = try container.decodeIfPresent(Bool.self, forKey: .isSSOIDDeleted)
            assets = try container.decodeIfPresent([UserAssetV0].self, forKey: .assets)
            supportedProtocols = try container.decodeIfPresent(Set<MessageProtocolV0>.self, forKey: .supportedProtocols)
            isTextStatusPresent = container.contains(.textStatus)
            textStatus = try container.decodeIfPresent(String.self, forKey: .textStatus)
        }

    }

}
