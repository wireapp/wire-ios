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

struct TeamCreateEventDecoder {

    func decode(
        from container: KeyedDecodingContainer<TeamEventCodingKeys>
    ) throws -> TeamCreateEvent {
        let payload = try container.decode(
            Payload.self,
            forKey: .payload
        )

        return TeamCreateEvent(
            identifier: payload.identifier,
            name: payload.name,
            creator: payload.creator,
            icon: payload.icon,
            iconKey: payload.iconKey,
            splashScreen: payload.splashScreen
        )
    }

    private struct Payload: Decodable {

        let identifier: UUID
        let name: String
        let creator: UUID
        let icon: String
        let iconKey: String?
        let splashScreen: String?

        enum CodingKeys: String, CodingKey {

            case identifier = "id"
            case name
            case creator
            case icon
            case iconKey = "icon_key"
            case splashScreen = "splash_screen"

        }

    }

}
