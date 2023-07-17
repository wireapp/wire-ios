//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
@testable import Wire

struct BoolPair { // Tuple would work better, but it cannot conform to @c Copyable
    var first: Bool
    var second: Bool

    func calculate() -> Bool {
        return self.first && self.second
    }
}

extension BoolPair: Copyable {
    init(instance: BoolPair) {
        self.first = instance.first
        self.second = instance.second
    }
}

class CombinationTestTest: XCTestCase {
    func testBoolConjunctionCombination() {
        let boolCombinations = Set<Bool>(arrayLiteral: false, true)

        let firstMutation = { (proto: BoolPair, value: Bool) -> BoolPair in
            var new = proto.copyInstance()
            new.first = value
            return new
        }
        let firstMutator = Mutator<BoolPair, Bool>(applicator: firstMutation, combinations: boolCombinations)

        let secondMutation = { (proto: BoolPair, value: Bool) -> BoolPair in
            var new = proto.copyInstance()
            new.second = value
            return new
        }
        let secondMutator = Mutator<BoolPair, Bool>(applicator: secondMutation, combinations: boolCombinations)

        let test = CombinationTest(mutable: BoolPair(first: false, second: false), mutators: [firstMutator, secondMutator])

        XCTAssertEqual(test.testAll { (variation) -> (Bool?) in
            return variation.result.calculate() == variation.combinationChain.allSatisfy { $0 }
        }.count, 0)
    }
}
