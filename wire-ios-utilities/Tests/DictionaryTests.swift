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
import WireUtilities

class DictionaryTests: XCTestCase {

    func testThatItMapsKeys() {

        // GIVEN
        let input = ["A": 12, "Boo": 23]

        // WHEN
        let output = input.mapKeys {
            return $0.lowercased()
        }

        // THEN
        XCTAssertEqual(output, ["a": 12, "boo": 23])
    }

    func testThatItMapsKeysWithEmptyDictionary() {

        // GIVEN
        let input = [String: Int]()

        // WHEN
        let output = input.mapKeys {
            return $0.lowercased()
        }

        // THEN
        XCTAssertEqual(output, [:])
    }

    func testThatItCreateDictionaryWithRepeatedValues() {
        // given
        let input = [1, 2, 3]

        // when
        let dictionary = Dictionary(keys: input, repeatedValue: "foo")

        // then
        XCTAssertEqual(dictionary, [1: "foo", 2: "foo", 3: "foo"])
    }

    func testThatItMapsADictionarysKeysAndValues() {
        // given
        let input = [1: "foo1", 2: "foo2", 3: "foo3"]

        // when
        let dictionary: [Int: String] = input.mapKeysAndValues(keysMapping: ({$0*2}), valueMapping: ({$1 + "bar"}))

        // then
        XCTAssertEqual(dictionary, [2: "foo1bar", 4: "foo2bar", 6: "foo3bar"])
    }

    func testThatItRemovesNilValuesWhenMappingKeysAndValues() {
        // given
        let input = [1: "foo1", 2: "foo2", 3: "foo3"]

        // when
        let dictionary: [Int: String] = input.mapKeysAndValues(keysMapping: ({$0*2}),
                                                                 valueMapping: ({ $0 == 1 ? nil : $1 + "bar"}))

        // then
        XCTAssertEqual(dictionary, [4: "foo2bar", 6: "foo3bar"])
    }

    func testThatItMergesTwoDictioniesOverwritingOldValue() {
        // given
        let input = [1: "foo1", 2: "foo2", 3: "foo3"]
        let other = [1: "bar", 4: "foo4"]

        // when
        let updated = input.updated(other: other)

        // then
        XCTAssertEqual(updated, [1: "bar", 2: "foo2", 3: "foo3", 4: "foo4"])
    }

}
