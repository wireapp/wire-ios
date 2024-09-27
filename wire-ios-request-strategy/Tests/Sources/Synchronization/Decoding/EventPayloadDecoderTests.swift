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

// MARK: - EventPayloadDecoderTests

final class EventPayloadDecoderTests: XCTestCase {
    func testDecodeData() throws {
        // given
        let decoder = EventPayloadDecoder()

        // when
        let book = try decoder.decode(Book.self, from: jsonDataExample)

        // then
        XCTAssertEqual(book.title, "Hello World!")
        let expectedPublished = try XCTUnwrap(
            Calendar.current.date(
                from: .init(
                    timeZone: .init(secondsFromGMT: 0),
                    year: 2024,
                    month: 1,
                    day: 4,
                    hour: 10,
                    minute: 34,
                    second: 56,
                    nanosecond: 780_000_000
                )
            )
        )
        XCTAssertEqual(book.published.timeIntervalSince1970, expectedPublished.timeIntervalSince1970, accuracy: 0.0001)
    }

    func testDecodeDataFails() throws {
        // given
        let decoder = EventPayloadDecoder()
        let jsonDataEmpty = try XCTUnwrap(Data("".utf8))

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
        let expectedPublished = try XCTUnwrap(
            Calendar.current.date(
                from: .init(
                    timeZone: .init(secondsFromGMT: 0),
                    year: 2024,
                    month: 1,
                    day: 4,
                    hour: 10,
                    minute: 34,
                    second: 56,
                    nanosecond: 780_000_000
                )
            )
        )
        XCTAssertEqual(book.published.timeIntervalSince1970, expectedPublished.timeIntervalSince1970, accuracy: 0.0001)
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

// MARK: - Book

private struct Book: Decodable {
    let title: String
    // We want to test `Date` decoding, because JSONDecoder can have a custom `dateDecodingStrategy`.
    let published: Date
}

// MARK: JSON

private let jsonDataExample = Data("""
{
    "title": "Hello World!",
    "published": "2024-01-04T12:34:56.78+02:00"
}
""".utf8)
