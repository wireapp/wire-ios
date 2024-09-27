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

struct UserLegalholdRequestEventDecoder {
    // MARK: Internal

    func decode(
        from container: KeyedDecodingContainer<UserEventCodingKeys>
    ) throws -> UserLegalholdRequestEvent {
        let userID = try container.decode(
            UUID.self,
            forKey: .id
        )

        let client = try container.decode(
            ClientPayload.self,
            forKey: .client
        )

        let lastPrekey = try container.decode(
            PrekeyPayload.self,
            forKey: .lastPrekey
        )

        return UserLegalholdRequestEvent(
            userID: userID,
            clientID: client.id,
            lastPrekey: Prekey(
                id: lastPrekey.id,
                base64EncodedKey: lastPrekey.key
            )
        )
    }

    // MARK: Private

    private struct ClientPayload: Decodable {
        let id: String
    }

    private struct PrekeyPayload: Decodable {
        let id: Int
        let key: String
    }
}
