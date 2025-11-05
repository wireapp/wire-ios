//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

/// A reusable and configurable response parser.
///
/// Construct parsing behavior by adding rules for parsing
/// success and failure results.

struct ResponseParser<Success> {

    enum ParsingError: Error {
        case noParseBlocksDefined
        case noParseResult
    }

    private typealias ParseBlock = (Data?) throws -> Success?

    private let decoder: JSONDecoder
    private var parseBlocks: [Int: [ParseBlock]]

    init(decoder: JSONDecoder = .init()) {
        self.decoder = decoder
        self.parseBlocks = [:]
    }

    /// Success with output data

    func success<Payload: Decodable & ToAPIModelConvertible>(
        code: HTTPStatusCode,
        type: Payload.Type
    ) -> ResponseParser<Success> where Payload.APIModel == Success {
        precondition(200 ..< 300 ~= code.rawValue, "Requires a valid success code: 2xx")

        return addParseBlock(code: code) { data in
            guard let data else { return nil }
            let payload = try decoder.decode(Payload.self, from: data)
            return payload.toAPIModel()
        }
    }

    /// Success with no output

    func success(code: HTTPStatusCode) -> ResponseParser<Success> where Success == Void {
        precondition(200 ..< 300 ~= code.rawValue, "Requires a valid success code: 2xx")

        return addParseBlock(code: code) { data in
            guard data == nil || data?.isEmpty == true
            else { return nil }
            return ()
        }
    }

    /// Matches a failure response with the given `code` and optional `label`.
    ///
    /// If `label` is given, this method will attempt to parse a `FailureResponse` from the response data, and if this
    /// fails or the label does not match the `FailureResponse`, the match will fail. If this method is called multiple
    /// times with the same `code`, calls with the `label` set will be prioritized.

    func failure(
        code: HTTPStatusCode,
        label: String? = nil,
        error: some Error
    ) -> ResponseParser<Success> {
        addParseBlock(
            code: code,
            prioritize: label != nil
        ) { data in
            guard let label else {
                throw error
            }

            guard
                let data,
                let failure = try? decoder.decode(
                    FailureResponseV0.self,
                    from: data
                ),
                failure.label == label
            else {
                return nil
            }
            throw error
        }
    }

    func failure(
        code: HTTPStatusCode,
        label: String? = nil,
        decodingError: @escaping (Data) throws -> (some Error)?
    ) -> ResponseParser<Success> {
        addParseBlock(
            code: code,
            prioritize: label != nil
        ) { data in
            guard let data else {
                return nil
            }

            // First check label matches.
            if let label {
                guard
                    let failure = try? decoder.decode(
                        FailureResponseV0.self,
                        from: data
                    ),
                    failure.label == label
                else {
                    return nil
                }
            }

            guard let failure = try? decodingError(data) else {
                return nil
            }

            throw failure
        }
    }

    func failure<DecodableError: Decodable & Error>(
        code: HTTPStatusCode,
        decodableError: DecodableError.Type
    ) -> ResponseParser<Success> {
        addParseBlock(code: code) { data in
            guard let data else { return nil }
            let failure = try decoder.decode(DecodableError.self, from: data)
            throw failure
        }
    }

    func parse(_ response: HTTPResponse) throws -> Success {
        guard !parseBlocks.isEmpty else {
            throw ParsingError.noParseBlocksDefined
        }

        let code = response.code
        let data = response.payload

        return try parse(
            code: code,
            data: data
        )
    }

    func parse(code: Int, data: Data?) throws -> Success {
        let parseBlocks = parseBlocks[code] ?? []

        for matcher in parseBlocks {
            if let success = try matcher(data) {
                return success
            }
        }

        if let data {
            let failure = try decoder.decode(FailureResponseV0.self, from: data)
            throw failure.toAPIModel()
        } else {
            throw ParsingError.noParseResult
        }
    }

    // MARK: Private helps

    private func addParseBlock(
        code: HTTPStatusCode,
        prioritize: Bool = false,
        block: @escaping ParseBlock
    ) -> ResponseParser<Success> {
        var blocks = parseBlocks[code.rawValue] ?? []

        if prioritize {
            blocks.insert(block, at: 0)
        } else {
            blocks.append(block)
        }

        var copy = self
        copy.parseBlocks[code.rawValue] = blocks
        return copy
    }

}
