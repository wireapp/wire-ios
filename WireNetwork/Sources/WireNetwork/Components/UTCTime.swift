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

/// A timestamp that encodes to ISO8601 date without fractional
/// seconds and decodes from ISO8601 date with or without
/// fractional seconds, i.e yyyy-mm-ddThh:MM:ss.qqqZ or
/// yyyy-mm-ddThh:MM:ssZ

struct UTCTime: Codable {

    let date: Date

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        // Although the backend distinguishes between dates with and without
        // fractional seconds, it sometimes mixes up the formats, even with
        // the same model. So it's safest to try decode both formats in a
        // single time object.
        if let date = ISO8601DateFormatter.internetDateTime.date(from: string) {
            self.date = date
        } else if let date = ISO8601DateFormatter.fractionalInternetDateTime.date(from: string) {
            self.date = date
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected date string to be ISO8601-formatted either with or without fractional seconds"
            )
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        let string = ISO8601DateFormatter.internetDateTime.string(from: date)
        try container.encode(string)
    }

}
