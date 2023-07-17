//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

class CombinationTest<SUT: Copyable, Variant: Hashable> {
    typealias M = Mutator<SUT, Variant>
    typealias CombinationChainPair = (combinationChain: [Variant], result: SUT)
    let mutators: [M]
    let mutable: SUT
    init(mutable: SUT, mutators: [M]) {
        self.mutable = mutable
        self.mutators = mutators
    }

    func allCombinations() -> [CombinationChainPair] {
        var current: [CombinationChainPair] = [(combinationChain: [], result: mutable)]

        self.mutators.forEach { mutator in
            let new = current.map { variation -> [CombinationChainPair] in
                let step = mutator.apply(variation.result)
                return step.map {
                    let newChain: [Variant] = [variation.combinationChain, [$0.combination]].reduce([], +)
                    return (combinationChain: newChain, result: $0.result)
                }
            }

            current = new.flatMap { $0 }
        }

        return current
    }

    @discardableResult func testAll(_ test: (CombinationChainPair) -> (Bool?)) -> [CombinationChainPair] {
        return self.allCombinations().compactMap {
            !(test($0) ?? true) ? $0 : .none
        }
    }
}
