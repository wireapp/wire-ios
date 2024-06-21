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

extension UpdateEventEnvelope: Decodable {

    enum CodingKeys: String, CodingKey {

        case id
        case events = "payload"
        case isTransient = "transient"

    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        let eventWrappers = try container.decodeIfPresent([UpdateEventDecodingProxy].self, forKey: .events) ?? []
        self.events = eventWrappers.map(\.updateEvent)
        self.isTransient = try container.decodeIfPresent(Bool.self, forKey: .isTransient) ?? false
    }

}
