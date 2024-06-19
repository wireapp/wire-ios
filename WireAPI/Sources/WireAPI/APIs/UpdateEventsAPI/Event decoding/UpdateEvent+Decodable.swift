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

extension UpdateEvent: Decodable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let eventType = try container.decode(String.self, forKey: .eventType)

        do {
            switch UpdateEventType(eventType) {
            case .conversation(let eventType):
                try self.init(eventType: eventType, from: decoder)

            case .featureConfig(let eventType):
                try self.init(eventType: eventType, from: decoder)

            case .federation(let eventType):
                try self.init(eventType: eventType, from: decoder)

            case .user(let eventType):
                try self.init(eventType: eventType, from: decoder)

            case .team(let eventType):
                try self.init(eventType: eventType, from: decoder)

            case .unknown(let eventType):
                self = .unknown(eventType: eventType)
            }
        } catch {
            throw UpdateEventDecodingError(
                eventType: eventType,
                decodingError: error
            )
        }
    }

    private enum CodingKeys: String, CodingKey {

        case eventType = "type"

    }

}
