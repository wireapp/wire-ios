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
import ZMUtilities

class DictionaryTests : XCTestCase {
    
    func testThatItMapsKeys() {
        
        // GIVEN
        let input = ["A" : 12, "Boo" : 23]
        
        // WHEN
        let output = input.mapKeys {
            return $0.lowercased()
        }
        
        // THEN
        XCTAssertEqual(output, ["a": 12, "boo" : 23])
    }
    
    func testThatItMapsKeysWithEmptyDictionary() {
        
        // GIVEN
        let input = [String:Int]()
        
        // WHEN
        let output = input.mapKeys {
            return $0.lowercased()
        }
        
        // THEN
        XCTAssertEqual(output, [:])
    }
    
    func testThatItCreatesDictionaryFromCollection() {
        
        // GIVEN
        let input = ["a", "bbb", "cc"]
        
        // WHEN
        let output = input.dictionary {
            return (key: $0, value: $0.utf8.count)
        }
        
        // THEN
        XCTAssertEqual(output, ["a" : 1, "bbb" : 3, "cc" : 2])
    }
    
    func testThatItOverwriteKeysIfRepeated() {
        
        // GIVEN
        let input = ["a", "bbb", "a"]
        
        // WHEN
        var count = 0
        let output = input.dictionary { (value) -> (key: String, value: Int) in
            count += 1
            return (key: value, value: count)
        }
        
        // THEN
        XCTAssertEqual(output, ["a" : 3, "bbb" : 2])
    }
}
