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

enum RequestBodyEncoderError: Error {

    case failedToEncodeToJSON(Error)
    case failedToEncodeToString

}

/// An object responsible for encoding an api model into a json string.

struct RequestBodyEncoder {

    let encoder: JSONEncoder

    /// Encode the given api model into a json string.

    func encodeBody<T: Encodable>(_ body: T) throws -> String {
        let data: Data
        do {
            data = try encoder.encode(body)
        } catch {
            throw RequestBodyEncoderError.failedToEncodeToJSON(error)
        }

        guard let string = String(
            data: data,
            encoding: .utf8
        ) else {
            throw RequestBodyEncoderError.failedToEncodeToString
        }

        return string
    }

}
