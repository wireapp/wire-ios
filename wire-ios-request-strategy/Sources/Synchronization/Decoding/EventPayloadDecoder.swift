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

// MARK: - EventPayloadDecoderError

enum EventPayloadDecoderError: Error {
    case invalidSerializationJSONObject
}

// MARK: - EventPayloadDecoder

struct EventPayloadDecoder {
    private let decoder: JSONDecoder

    init(decoder: JSONDecoder = .defaultDecoder) {
        self.decoder = decoder
    }

    func decode<T>(
        _ type: T.Type,
        from eventPayload: [AnyHashable: Any]
    ) throws -> T where T: Decodable {
        // .isValidJSONObject(:) is required before calling .data(withJSONObject:options:)
        guard JSONSerialization.isValidJSONObject(eventPayload) else {
            throw EventPayloadDecoderError.invalidSerializationJSONObject
        }

        let data: Data

        do {
            data = try JSONSerialization.data(withJSONObject: eventPayload, options: [])
        } catch {
            Logging.network.warn("Failed to JSONSerialization data from event payload: \(error)!")
            throw error
        }

        return try decode(type, from: data)
    }

    func decode<T>(
        _ type: T.Type,
        from eventPayload: Data
    ) throws -> T where T: Decodable {
        do {
            return try decoder.decode(type, from: eventPayload)
        } catch {
            Logging.network.warn("Failed to json decode \(type) from event payload: \(error)")
            throw error
        }
    }
}
