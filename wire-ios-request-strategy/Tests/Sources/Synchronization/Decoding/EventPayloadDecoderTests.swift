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

import XCTest
@testable import WireRequestStrategy

final class EventPayloadDecoderTests: XCTestCase {

    func testDecodeData() throws {
        // given
        let decoder = EventPayloadDecoder()

        // when
        let book = try decoder.decode(Book.self, from: jsonDataExample)

        // then
        XCTAssertEqual(book.title, "Hello World!")
        XCTAssertEqual(book.published.description, "2024-01-04 10:34:56 +0000")
    }

    func testDecodeDataFails() throws {
        // given
        let decoder = EventPayloadDecoder()
        let jsonDataEmpty = try XCTUnwrap("".data(using: .utf8))

        // when
        // then
        XCTAssertThrowsError(try decoder.decode(Book.self, from: jsonDataEmpty))
    }

    func testDecodeDictionary() throws {
        // given
        let decoder = EventPayloadDecoder()
        let jsonObject = try JSONSerialization.jsonObject(with: jsonDataExample)
        let jsonDictionary = try XCTUnwrap(jsonObject as? [AnyHashable: Any])

        // when
        let book = try decoder.decode(Book.self, from: jsonDictionary)

        // then
        XCTAssertEqual(book.title, "Hello World!")
        XCTAssertEqual(book.published.description, "2024-01-04 10:34:56 +0000")
    }

    func testDecodeDictionaryFails() throws {
        // given
        let decoder = EventPayloadDecoder()
        let jsonDictionary = [123: 456]

        // when
        // then
        XCTAssertThrowsError(try decoder.decode(Book.self, from: jsonDictionary))
    }
}

// MARK: Decodable Struct

private struct Book: Decodable {
    let title: String
    let published: Date
}

// MARK: JSON

private let jsonDataExample = """
{
    "title": "Hello World!",
    "published": "2024-01-04T12:34:56.78+02:00"
}
""".data(using: .utf8)!
