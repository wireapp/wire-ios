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

/// A timestamp that encodes to and decodes from ISO8601 date with
/// fractional secconds, i.e yyyy-mm-ddThh:MM:ss.qqqZ
///
/// See `UTCTime` if encoding and decoding without fractional seconds
/// is required.

struct UTCTimeMillis: Codable {
    // MARK: Lifecycle

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        if let date = ISO8601DateFormatter.fractionalInternetDateTime.date(from: string) {
            self.date = date
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected date string to be ISO8601-formatted with fractional seconds"
            )
        }
    }

    // MARK: Internal

    let date: Date

    func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        let string = ISO8601DateFormatter.fractionalInternetDateTime.string(from: date)
        try container.encode(string)
    }
}
