//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
@testable import WireNetwork

final class UTCTimeDecodingTests: XCTestCase {

    func test_DecodingWithFractionalSeconds() throws {
        // Given
        let timestamp = "\"2024-06-04T15:03:07.598Z\""
        let data = Data(timestamp.utf8)

        // When
        let utcTime = try JSONDecoder().decode(UTCTime.self, from: data)

        // Then
        XCTAssertEqual(utcTime.date, Date(timeIntervalSince1970: 1_717_513_387.598))
    }

    func test_DecodingWithoutFractionalSeconds() throws {
        // Given
        let timestamp = "\"2021-05-12T10:52:02Z\""
        let data = Data(timestamp.utf8)

        // When
        let utcTime = try JSONDecoder().decode(UTCTime.self, from: data)

        // Then
        XCTAssertEqual(utcTime.date, Date(timeIntervalSince1970: 1_620_816_722))
    }

}
