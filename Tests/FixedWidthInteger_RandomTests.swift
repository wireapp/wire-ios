//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

class FixedWidthInteger_RandomTests: XCTestCase {
    
    func testThatTheGeneratedNumberIsInRangeWithUInt() {
        
        let upperBound: UInt = 2
        let range = 0..<upperBound
        
        for _ in 0..<100 {
            XCTAssertTrue(range.contains(UInt.secureRandomNumber(upperBound: upperBound)))
        }
    }
    
    func testThatTheGeneratedNumberIsInRangeWithInt() {
        
        let upperBound: Int = 100
        let range = -upperBound..<upperBound
        
        for _ in 0..<100 {
            XCTAssertTrue(range.contains(Int.secureRandomNumber(upperBound: upperBound)))
        }
    }
    
    func testThatItGeneratesZeroWhenTheUpperBoundIsZeroOrOne() {
        XCTAssertEqual(UInt.secureRandomNumber(upperBound: 0), 0)
        XCTAssertEqual(UInt.secureRandomNumber(upperBound: 1), 0)
    }
    
    func testThatItGeneratesANumberWhenThenUpperBoundIsMax() {
        XCTAssertNotNil(UInt.secureRandomNumber(upperBound: UInt.max))
    }
    
    /// Tests for all numeric types inheriting from FixedWidthInteger
    /// https://developer.apple.com/documentation/swift/fixedwidthinteger#relationships
    
    func testThatItGeneratesANumberByProvidingBounds_Int() {
        XCTAssertEqual(Int.secureRandomNumber(upperBound: Int.min), 0)
        XCTAssertNotNil(Int.secureRandomNumber(upperBound: Int.max))
    }
    
    func testThatItGeneratesANumberByProvidingBounds_Int8() {
        XCTAssertEqual(Int8.secureRandomNumber(upperBound: Int8.min), 0)
        XCTAssertNotNil(Int8.secureRandomNumber(upperBound: Int8.max))
    }
    
    func testThatItGeneratesANumberByProvidingBounds_Int16() {
        XCTAssertEqual(Int16.secureRandomNumber(upperBound: Int16.min), 0)
        XCTAssertNotNil(Int16.secureRandomNumber(upperBound: Int16.max))
    }
    
    func testThatItGeneratesANumberByProvidingBounds_Int32() {
        XCTAssertEqual(Int32.secureRandomNumber(upperBound: Int32.min), 0)
        XCTAssertNotNil(Int32.secureRandomNumber(upperBound: Int32.max))
    }
    
    func testThatItGeneratesANumberByProvidingBounds_Int64() {
        XCTAssertEqual(Int64.secureRandomNumber(upperBound: Int64.min), 0)
        XCTAssertNotNil(Int64.secureRandomNumber(upperBound: Int64.max))
    }
    
    func testThatItGeneratesANumberByProvidingBounds_UInt() {
        XCTAssertEqual(UInt.secureRandomNumber(upperBound: UInt.min), 0)
        XCTAssertNotNil(UInt.secureRandomNumber(upperBound: UInt.max))
    }
    
    func testThatItGeneratesANumberByProvidingBounds_UInt8() {
        XCTAssertEqual(UInt8.secureRandomNumber(upperBound: UInt8.min), 0)
        XCTAssertNotNil(UInt8.secureRandomNumber(upperBound: UInt8.max))
    }
    
    func testThatItGeneratesANumberByProvidingBounds_UInt16() {
        XCTAssertEqual(UInt16.secureRandomNumber(upperBound: UInt16.min), 0)
        XCTAssertNotNil(UInt16.secureRandomNumber(upperBound: UInt16.max))
    }
    
    func testThatItGeneratesANumberByProvidingBounds_UInt32() {
        XCTAssertEqual(UInt32.secureRandomNumber(upperBound: UInt32.min), 0)
        XCTAssertNotNil(UInt32.secureRandomNumber(upperBound: UInt32.max))
    }
    
    func testThatItGeneratesANumberByProvidingBounds_UInt64() {
        XCTAssertEqual(UInt64.secureRandomNumber(upperBound: UInt64.min), 0)
        XCTAssertNotNil(UInt64.secureRandomNumber(upperBound: UInt64.max))
    }
}
