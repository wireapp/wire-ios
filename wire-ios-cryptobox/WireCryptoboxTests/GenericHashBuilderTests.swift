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
@testable import WireCryptobox

final class GenericHashBuilderTests: XCTestCase {
    func testThatItHashesTheData() {
        // GIVEN
        let data = Data("some data".utf8)
        // WHEN
        let builder = GenericHashBuilder()
        builder.append(data)
        let hash = builder.build()
        // THEN
        let genericHash = GenericHash(value: 108_806_884_620_190_685)
        XCTAssertEqual(hash, genericHash)
        XCTAssertEqual(hash.hashValue, genericHash.hashValue)
    }

    func testThatDifferentDataHasDifferentHash() {
        // GIVEN
        let data = Data("some data".utf8)
        let otherData = Data("some other data".utf8)
        // WHEN
        let builder = GenericHashBuilder()
        builder.append(data)
        let hash = builder.build()

        let otherBuilder = GenericHashBuilder()
        otherBuilder.append(otherData)
        let otherHash = otherBuilder.build()
        // THEN
        XCTAssertNotEqual(hash.hashValue, otherHash.hashValue)
    }

    func testThatSameDataHasSameHash() {
        // GIVEN
        let data = Data("some data".utf8)
        let otherData = Data("some data".utf8)
        // WHEN
        let builder = GenericHashBuilder()
        builder.append(data)
        let hash = builder.build()

        let otherBuilder = GenericHashBuilder()
        otherBuilder.append(otherData)
        let otherHash = otherBuilder.build()
        // THEN
        XCTAssertEqual(hash.hashValue, otherHash.hashValue)
    }

    func testThatDataCanBeAppended() {
        // GIVEN
        let data = Data("some data".utf8)
        let otherData1 = Data("some ".utf8)
        let otherData2 = Data("data".utf8)
        // WHEN
        let builder = GenericHashBuilder()
        builder.append(data)
        let hash = builder.build()

        let otherBuilder = GenericHashBuilder()
        otherBuilder.append(otherData1)
        otherBuilder.append(otherData2)
        let otherHash = otherBuilder.build()
        // THEN
        XCTAssertEqual(hash.hashValue, otherHash.hashValue)
    }
}
