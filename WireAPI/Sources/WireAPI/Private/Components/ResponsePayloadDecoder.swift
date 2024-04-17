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
    case failedToDecodeSuccess(Error)
    case failedToDecodeFailure(Error)

}

/// An object responsible for decoding the http response payload into
/// an api model.

struct ResponsePayloadDecoder {

    let decoder: JSONDecoder

    init(decoder: JSONDecoder) {
        self.decoder = decoder
    }

    /// Decode the payload of a response.
    ///
    /// - Parameters:
    ///   - response: The http response to decode.
    ///   - type: The api model type to decode into.
    ///
    /// - Throws: `ResponsePayloadDecoderError` if decoding was unsuccessful.
    /// - Returns: A `Result` with the success response or a failure response.

    func decodePayload<T: Decodable>(
        from response: HTTPResponse,
        as type: T.Type
    ) throws -> Result<
        T,
        FailureResponse
    > {
        switch response.code {
        case 100...300:
            return .success(try decodeSuccess(response))
        default:
            return .failure(try decodeFailure(response))
        }
    }

    private func decodeSuccess<T: Decodable>(_ response: HTTPResponse) throws -> T {
        guard let data = response.payload else {
            throw ResponsePayloadDecoderError.missingResponseData
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ResponsePayloadDecoderError.failedToDecodeSuccess(error)
        }
    }

    private func decodeFailure(_ response: HTTPResponse) throws -> FailureResponse {
        guard let data = response.payload else {
            throw ResponsePayloadDecoderError.missingResponseData
        }

        do {
            return try decoder.decode(FailureResponse.self, from: data)
        } catch {
            throw ResponsePayloadDecoderError.failedToDecodeFailure(error)
        }
    }

}
