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

class UInt_RandomTests: XCTestCase {
    
    func testThatTheGeneratedNumberIsInRange() {
        
        let upperBound: UInt = 2
        let range = 0..<upperBound
        
        for _ in 0..<100 {
            XCTAssertTrue(range.contains(UInt.secureRandomNumber(upperBound: upperBound)))
        }
    }
    
    func testThatItGeneratesZeroWhenTheUpperBoundIsZeroOrOne() {
        XCTAssertEqual(UInt.secureRandomNumber(upperBound: 0), 0)
        XCTAssertEqual(UInt.secureRandomNumber(upperBound: 1), 0)
    }
    
    func testThatItGeneratesANumberWhenThenUpperBoundIsMax() {
        XCTAssertNotNil(UInt.secureRandomNumber(upperBound: UInt.max))
    }
}
