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
import ZMCDataModel

class ChangedObjectSetTests: ZMBaseManagedObjectTest {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEquatable() {
        // given
        let a = NSObject()
        
        // then
        XCTAssertEqual(ChangedObjectSet(), ChangedObjectSet())
        XCTAssertEqual(ChangedObjectSet(element: a), ChangedObjectSet(element: a))
        XCTAssertNotEqual(ChangedObjectSet(), ChangedObjectSet(element: a))
        XCTAssertNotEqual(ChangedObjectSet(element: a), ChangedObjectSet())
    }
    
    func testThatPoppingAnEmptySet() {
        // given
        let sut = ChangedObjectSet()
        
        // when
        XCTAssert(sut.decompose() == nil)
    }
    
    func testThatPoppingASetWithASingleObjectReturnsThatObject() {
        // given
        let a = NSObject()
        let sut = ChangedObjectSet(element: a)
        
        // when
        if let (head, tail) = sut.decompose() {
            // then
            XCTAssertEqual(head.object, a)
            XCTAssertEqual(head.keys , AffectedKeys.all)
            XCTAssertEqual(tail, ChangedObjectSet())
        } else {
            XCTFail("decompose() returned nil")
        }
    }
    
    func testThatItCanUnionMultipleObjects() {
        // given
        let a = NSObject()
        let b = NSObject()
        let setA = ChangedObjectSet(element: a, affectedKeys: .some(KeySet(key: "foo")))
        let setB = ChangedObjectSet(element: b, affectedKeys: .some(KeySet(key: "bar")))
        
        let sut = setA.unionWithSet(setB)
        
        // when
        let owkA = ChangedObjectSet.ObjectWithKeys(object: a, keys:.some(KeySet(key: "foo")))
        let owkB = ChangedObjectSet.ObjectWithKeys(object: b, keys:.some(KeySet(key: "bar")))

        if let (head, tail) = sut.decompose() {
            // then
            if  head == owkA {
                XCTAssertEqual(tail, setB)
            } else if  head == owkB {
                XCTAssertEqual(tail, setA)
            } else {
                XCTFail("decompose() failed")
            }
        } else {
            XCTFail("decompose() returned nil")
        }
    }

    func testThatItCanUnionTheSameObjectWithMultipleKeys() {
        // given
        let a = NSObject()
        let setA = ChangedObjectSet(element: a, affectedKeys: .some(KeySet(key: "foo")))
        let setB = ChangedObjectSet(element: a, affectedKeys: .some(KeySet(key: "bar")))
        
        let sut = setA.unionWithSet(setB)

        // when
        if let (head, tail) = sut.decompose() {
            // then
            XCTAssertEqual(head.object, a)
            XCTAssertEqual(head.keys, AffectedKeys.some(KeySet(["bar", "foo"])))
            XCTAssertEqual(tail, ChangedObjectSet())
        } else {
            XCTFail("decompose() returned nil")
        }
    }
    
    func testTestItCanBeCreatedFromAObjectsDidChangeNotification() {
        // given
        let fakeMOC = NSObject()
        let a = NSObject()
        let b = NSObject()
        let c = NSObject()
        let d = NSObject()
        let userInfo = [NSUpdatedObjectsKey: NSSet(objects: a, b), NSRefreshedObjectsKey: NSSet(objects: c, d)]
        let note = Notification(name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: fakeMOC, userInfo: userInfo)
        
        // when
        let sut = ChangedObjectSet(notification: note)
        let allObjects = NSMutableSet()
        
        // then
        for owk in sut {
            allObjects.add(owk.object)
            XCTAssertEqual(owk.keys, AffectedKeys.all)
        }
        XCTAssertEqual(allObjects, NSSet(objects: a, b, c, d))
    }
}
