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

/// A wrapper that provides custom decoding of update events from
/// JSON payloads received from the backend.
///
/// The need for this wrapper arises from another need to persist
/// update events in a database: to persist an update event we
/// persist its encoded data, from which we need to decode it after
/// fetching it from the database. This coding and decoding needs
/// to be symmetric and for this we rely on the automatic conformance
/// of `UpdateEvent`.
///
/// However, we still need to decode the update events from the JSON
/// payloads we receive from the backend. This additional and manual
/// decoding is provided by `UpdateEventDecodingProxy`.

struct UpdateEventDecodingProxy: Decodable {
    // MARK: Lifecycle

    init(updateEvent: UpdateEvent) {
        self.updateEvent = updateEvent
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let eventType = try container.decode(String.self, forKey: .eventType)

        do {
            switch UpdateEventType(eventType) {
            case let .conversation(eventType):
                try self.init(eventType: eventType, from: decoder)

            case let .featureConfig(eventType):
                try self.init(eventType: eventType, from: decoder)

            case let .federation(eventType):
                try self.init(eventType: eventType, from: decoder)

            case let .user(eventType):
                try self.init(eventType: eventType, from: decoder)

            case let .team(eventType):
                try self.init(eventType: eventType, from: decoder)

            case let .unknown(eventType):
                self.init(updateEvent: .unknown(eventType: eventType))
            }
        } catch {
            throw UpdateEventDecodingProxyError(
                eventType: eventType,
                decodingError: error
            )
        }
    }

    // MARK: Internal

    let updateEvent: UpdateEvent

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case eventType = "type"
    }
}
