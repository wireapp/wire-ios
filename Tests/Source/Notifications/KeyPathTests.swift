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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import Foundation

class KeyPathTests: MessagingTest {

    func testThatItCreatesASimpleKeyPath() {
        let sut = KeyPath.keyPathForString("name")
        XCTAssertEqual(sut.rawValue, "name")
        XCTAssertEqual(sut.count, 1)
        XCTAssertFalse(sut.isPath)
    }

    func testThatItCreatesKeyPathThatIsAPath() {
        let sut = KeyPath.keyPathForString("foo.name")
        XCTAssertEqual(sut.rawValue, "foo.name")
        XCTAssertEqual(sut.count, 2)
        XCTAssertTrue(sut.isPath)
    }
    
    func testThatItDecomposesSimpleKeys() {
        let sut = KeyPath.keyPathForString("name")
        if let (a, b) = sut.decompose {
            XCTAssertEqual(a, KeyPath.keyPathForString("name"))
            XCTAssertEqual(b, nil)
        } else {
            XCTFail("Did not decompose")
        }
    }
    
    func testThatItDecomposesKeyPaths() {
        let sut = KeyPath.keyPathForString("foo.name")
        if let (a, b) = sut.decompose {
            XCTAssertEqual(a, KeyPath.keyPathForString("foo"))
            XCTAssertEqual(b, KeyPath.keyPathForString("name"))
        } else {
            XCTFail("Did not decompose")
        }
    }
}
