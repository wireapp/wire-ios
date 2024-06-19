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

extension JSONDecoder {

    /// The default decoder to use when parsing http response payloads.

    static var defaultDecoder: JSONDecoder {
        let decoder = JSONDecoder()

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let rawDate = try container.decode(String.self)

            // Date strings can be either with fractional seconds or without, even in the
            // same payload. To account for this, we try to decode both formats.
            if let date = ISO8601DateFormatter.fractionalInternetDateTime.date(from: rawDate) {
                return date
            } else if let date = ISO8601DateFormatter.internetDateTime.date(from: rawDate) {
                return date
            } else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Expected date string to be ISO8601-formatted with or without fractional seconds"
                )
            }
        }

        return decoder
    }

}
