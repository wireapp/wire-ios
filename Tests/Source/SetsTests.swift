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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


import XCTest
import ZMUtilities

// MARK: OrderedSet

class OrderedSetTests : XCTestCase
{
    class Foo : NSObject {
        let innerValue : Int
        init(_ value: Int) {
            self.innerValue = value
        }
    }
    
    func testThatCountReturnsZeroForAnEmptySet() {
        
        // given
        let mySet = OrderedSet(array: Array<Foo>())
        
        // then
        XCTAssertEqual(mySet.count, 0)
    }
    
    func testThatCountReturnsThree() {
        // given
        let mySet = OrderedSet(array: [Foo(2), Foo(3), Foo(1)])
        
        // then
        XCTAssertEqual(mySet.count, 3)
    }
    
    func testThatItReturnsTheElements() {
        
        // given
        let array = [Foo(2), Foo(3), Foo(1)]
        let mySet = OrderedSet(array: array)
        
        // then
        var count = 0
        for x in mySet {
            XCTAssertEqual(array[count].innerValue, x.innerValue)
            ++count
        }
        
        XCTAssertEqual(count, array.count)
        
    }
    
    func testThatItReturnsTrueForEqualSets() {
        
        // given
        let array = [Foo(2), Foo(3), Foo(1)]
        let mySet1 = OrderedSet(array: array)
        let mySet2 = OrderedSet(array: array)
        
        // then
        XCTAssertEqual(mySet1, mySet2)
    }
    
    func testThatItReturnsFalseForNonEqualSets() {
        
        // given
        let array1 = [Foo(2), Foo(3), Foo(1)]
        let array2 = [Foo(2), Foo(3), Foo(5)]
        
        let mySet1 = OrderedSet(array: array1)
        let mySet2 = OrderedSet(array: array2)
        
        // then
        XCTAssertNotEqual(mySet1, mySet2)
    }
    
}
