//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import XCTest


private class PredicateTestHelper: NSObject {
    let a: Bool
    let b: Bool

    init(a: Bool, b: Bool) {
        self.a = a
        self.b = b
    }
}

class NSPredicateOperatorTests: XCTestCase {

    // MARK: &&

    func testThatItCreatesACorrectANDPredicate() {
        executeWithAllBooleanCombinations { lhs, rhs in
            let matching = PredicateTestHelper(a: lhs, b: rhs)
            let notMatching = PredicateTestHelper(a: lhs, b: !rhs)
            let aPredicate = NSPredicate(format: "a == %@", NSNumber(value: lhs))
            let bPredicate = NSPredicate(format: "b == %@", NSNumber(value: rhs))
            let compound = aPredicate && bPredicate
            XCTAssertTrue(compound.evaluate(with: matching))
            XCTAssertFalse(compound.evaluate(with: notMatching))
        }
    }

    // MARK: ||

    func testThatItCreatesACorrectORPredicate() {
        executeWithAllBooleanCombinations { lhs, rhs in
            let matchingLHS = PredicateTestHelper(a: lhs, b: !rhs)
            let matchingRHS = PredicateTestHelper(a: !lhs, b: rhs)
            let matchingBoth = PredicateTestHelper(a: lhs, b: rhs)
            let notMatching = PredicateTestHelper(a: !lhs, b: !rhs)
            let aPredicate = NSPredicate(format: "a == %@", NSNumber(value: lhs))
            let bPredicate = NSPredicate(format: "b == %@", NSNumber(value: rhs))
            let compound = aPredicate || bPredicate
            XCTAssertTrue(compound.evaluate(with: matchingLHS))
            XCTAssertTrue(compound.evaluate(with: matchingRHS))
            XCTAssertTrue(compound.evaluate(with: matchingBoth))
            XCTAssertFalse(compound.evaluate(with: notMatching))
        }
    }

    // MARK: Helper

    func executeWithAllBooleanCombinations(block: (Bool, Bool) -> Void) {
        [true, false].forEach { lhs in
            [true, false].forEach { rhs in
                block(lhs, rhs)
            }
        }
    }

}
