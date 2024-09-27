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

/// An integer used in the context of the Giphy API, which encodes numbers
/// as strings.

public struct ZiphyInt: Codable, ExpressibleByIntegerLiteral {
    // MARK: Lifecycle

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(integerLiteral value: Int) {
        self.rawValue = value
    }

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let stringValue = try decoder.singleValueContainer().decode(String.self)

        guard let rawValue = Int(stringValue) else {
            throw DecodingError.typeMismatch(
                Int.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected an integer convertible string, got \"\(stringValue)\""
                )
            )
        }

        self.rawValue = rawValue
    }

    // MARK: Public

    /// The integer value wrapped by the object
    public let rawValue: Int

    public var description: String {
        rawValue.description
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(rawValue))
    }
}
