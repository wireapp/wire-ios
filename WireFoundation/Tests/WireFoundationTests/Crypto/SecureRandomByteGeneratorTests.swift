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

@testable import WireFoundation

final class SecureRandomByteGeneratorTests: XCTestCase {

    func testByteGenerationIsRandom() throws {
        // When
        let randomBytes1 = try SecureRandomByteGenerator.generateBytes(count: 10)
        let randomBytes2 = try SecureRandomByteGenerator.generateBytes(count: 10)

        // Then
        XCTAssertNotEqual(randomBytes1, randomBytes2)
    }

    func testCorrectNumberOfBytesAreGenerated() throws {
        // Given
        let count = UInt.random(in: 0 ... 1_000)

        // When
        let bytes = try SecureRandomByteGenerator.generateBytes(count: count)

        // Then
        XCTAssertEqual(bytes.count, Int(count))
    }

}
