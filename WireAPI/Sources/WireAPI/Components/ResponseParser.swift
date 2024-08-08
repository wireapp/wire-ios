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

/// A reusable and configurable response parser.
///
/// Construct parsing behavior by adding rules for parsing
/// success and failure results.

struct ResponseParser<Success> {
    
    enum ParsingError: Swift.Error {
        case noParseBlocksDefined
        case nothingToParse
    }

    private typealias ParseBlock = (Int, Data?) throws -> Success?

    private let decoder: JSONDecoder
    private var parseBlocks: [ParseBlock]

    init(decoder: JSONDecoder = .init()) {
        self.decoder = decoder
        parseBlocks = []
    }

    /// Success with output data
    
    func success<Payload: Decodable & ToAPIModelConvertible>(
        code: Int,
        type: Payload.Type
    ) -> ResponseParser<Success> where Payload.APIModel == Success {
        var copy = self
        copy.parseBlocks.append { actualCode, data in
            guard actualCode == code, let data else { return nil }
            let payload = try decoder.decode(Payload.self, from: data)
            return payload.toAPIModel()
        }
        return copy
    }
    
    /// Success with no output
    
    func success(code: Int) -> ResponseParser<Success> where Success == Void {
        var copy = self
        copy.parseBlocks.append { actualCode, data in
            guard actualCode == code, data == nil else { return nil }
            return ()
        }
        return copy
    }

    func failure(
        code: Int,
        label: String = "",
        error: Error
    ) -> ResponseParser<Success> {
        var copy = self
        copy.parseBlocks.append { _, data in
            guard let data else { return nil }
            let failure = try decoder.decode(FailureResponse.self, from: data)
            guard failure.code == code, failure.label == label else { return nil }
            throw error
        }
        return copy
    }

    func parse(_ response: HTTPResponse) throws -> Success {
        guard !parseBlocks.isEmpty else {
            throw ParsingError.noParseBlocksDefined
        }
        
        let code = response.code
        let data = response.payload
        
        for matcher in parseBlocks {
            if let success = try matcher(code, data) {
                return success
            }
        }
        
        if let data {
            let failure = try decoder.decode(FailureResponse.self, from: data)
            throw failure
        } else {
            throw ParsingError.nothingToParse
        }
        
    }

}
