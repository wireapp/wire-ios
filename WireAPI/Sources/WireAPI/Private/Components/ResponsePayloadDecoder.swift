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

enum ResponsePayloadDecoderError: Error {

    case missingResponseData
    case failedToDecodePayload(Decodable.Type, Error)

}

/// An object responsible for decoding the http response payload into
/// an api model.

struct ResponsePayloadDecoder {

    let decoder: JSONDecoder

    init(decoder: JSONDecoder) {
        self.decoder = decoder
    }

    func decodePayload<T: Decodable>(
        from response: HTTPResponse,
        as type: T.Type
    ) throws -> T {
        guard let data = response.payload else {
            throw ResponsePayloadDecoderError.missingResponseData
        }

        do {
            return try decoder.decode(
                T.self,
                from: data
            )
        } catch {
            throw ResponsePayloadDecoderError.failedToDecodePayload(
                T.self,
                error
            )
        }
    }

}
