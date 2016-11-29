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


import Foundation
import ZMCDataModel
import ZMTesting


class ObjectSnapshotTests : ZMBaseManagedObjectTest {
    
    class Foo : NSObject, ObjectInSnapshot
    {
        var array : NSMutableArray
        var set : NSMutableSet
        var dict : NSMutableDictionary
        var orderedSet : NSMutableOrderedSet
        var data : NSMutableData
        var string : NSMutableString
        
        override init() {
            array = NSMutableArray()
            set = NSMutableSet()
            dict = NSMutableDictionary()
            orderedSet = NSMutableOrderedSet()
            data = NSMutableData()
            string = NSMutableString()
        }
        
        var observableKeys : [String] {
            return ["array", "set", "dict", "orderedSet", "data", "string"]
        }
    }
    
    func testThatItReturnsNoNewSnapshotIfThereIsNoChange()
    {
        // given
        let user = ZMUser.insertNewObject(in:self.uiMOC)
        user.name = "Fabio"
        user.accentColorValue = ZMAccentColor.brightOrange
        let observedKeys = KeySet(["name", "accentColorValue"])
        
        let sut = ObjectSnapshot(object: user, keys: observedKeys)
        
        // when
        let result : (ObjectSnapshot, ObjectSnapshot.KeysAndOldValues)? = sut.updatedSnapshot(user, affectedKeys: AffectedKeys.some(KeySet(["name","accentColorValue"])))
        
        // then
        XCTAssertTrue(result == nil)
    }
    
    
    func testThatItReturnsANewSnapshotAndKeysOnceIfThereIsAChangeInTheOnlyKeyObserved()
    {
        // given
        let user = ZMUser.insertNewObject(in:self.uiMOC)
        user.name = "Fabio"
        user.accentColorValue = ZMAccentColor.brightOrange
        let observedKeys = KeySet(["name", "accentColorValue"])
        
        let sut = ObjectSnapshot(object: user, keys: observedKeys)
        
        // when
        user.name = "Fritz"
        if let (snapshot, keysAndOldValues) = sut.updatedSnapshot(user, affectedKeys: AffectedKeys.some(observedKeys)) {
            let allKeys = Array(keysAndOldValues.keys)
            XCTAssertEqual(allKeys, [KeyPath.keyPathForString("name")])
            AssertKeyPathDictionaryHasOptionalValue(keysAndOldValues, key: KeyPath.keyPathForString("name"), expected: "Fabio" as NSObject)

            // once?
            let newSnapshot = ObjectSnapshot(object: user, keys: observedKeys)
            XCTAssertEqual(snapshot, newSnapshot)
        }
        else {
            XCTFail("Should not be empty")
        }
    }
    
    func testThatItReturnsANewSnapshotAndKeysOnceIfANilObjectBecameNotNil()
    {
        // given
        let user = ZMUser.insertNewObject(in:self.uiMOC)
        user.name = nil
        let observedKeys = KeySet(["name", "accentColorValue"])
        
        let sut = ObjectSnapshot(object: user, keys: observedKeys)
        
        // when
        user.name = "Fritz"
        if let (snapshot, keysAndOldValues) = sut.updatedSnapshot(user, affectedKeys: AffectedKeys.some(observedKeys)) {
            let allKeys = Array(keysAndOldValues.keys)
            XCTAssertEqual(allKeys, [KeyPath.keyPathForString("name")])
            AssertKeyPathDictionaryHasOptionalNilValue(keysAndOldValues, key: KeyPath.keyPathForString("name"))
            
            // once?
            let newSnapshot = ObjectSnapshot(object: user, keys: observedKeys)
            XCTAssertEqual(snapshot, newSnapshot)
        } else {
            XCTFail("Should not be empty")
        }
    }
    
    func testThatItReturnsANewSnapshotAndKeysOnceIfANonNilObjectBecameNil()
    {
        // given
        let user = ZMUser.insertNewObject(in:self.uiMOC)
        user.name = "Jacques"
        self.uiMOC.saveOrRollback()
        let observedKeys = KeySet(["name", "accentColorValue"])
        
        let sut = ObjectSnapshot(object: user, keys: observedKeys)
        
        // when
        user.name = nil
        if let (snapshot, keysAndOldValues) = sut.updatedSnapshot(user, affectedKeys: AffectedKeys.some(observedKeys)) {
            let allKeys = Array(keysAndOldValues.keys)
            XCTAssertEqual(allKeys, [KeyPath.keyPathForString("name")])
            AssertKeyPathDictionaryHasOptionalValue(keysAndOldValues, key: KeyPath.keyPathForString("name"), expected: "Jacques" as NSObject)

            // once?
            let newSnapshot = ObjectSnapshot(object: user, keys: observedKeys)
            XCTAssertEqual(snapshot, newSnapshot)
        }
        else {
            XCTFail("Should not be empty")
        }
    }
    
    func testThatItDoesNotReturnsANewSnapshotIfThereIsAChangeInAKeyThatIsNotObserved()
    {
        // given
        let user = ZMUser.insertNewObject(in:self.uiMOC)
        user.name = "Fabio"
        user.accentColorValue = ZMAccentColor.brightOrange
        let observedKeys = KeySet(key: "name")
        
        let sut = ObjectSnapshot(object: user, keys: observedKeys)
        
        // when
        user.accentColorValue = ZMAccentColor.strongBlue
        let result : (ObjectSnapshot, ObjectSnapshot.KeysAndOldValues)? = sut.updatedSnapshot(user, affectedKeys: AffectedKeys.all)
        
        // then
        XCTAssertTrue(result == nil)
    }
    
    func testThatItDoesNotReturnANewSnapshotIfThereIsAChangeInAnObservedKeyThatIsNotPassedToTheUpdate()
    {
        // given
        let user = ZMUser.insertNewObject(in:self.uiMOC)
        user.name = "Fabio"
        user.accentColorValue = ZMAccentColor.brightOrange
        let observedKeys = KeySet(["name", "accentColorValue"])
        
        let sut = ObjectSnapshot(object: user, keys: observedKeys)
        
        // when
        user.accentColorValue = ZMAccentColor.strongBlue
        let result : (ObjectSnapshot, ObjectSnapshot.KeysAndOldValues)? = sut.updatedSnapshot(user, affectedKeys: AffectedKeys.some(KeySet(key: "name")))
        
        // then
        XCTAssertTrue(result == nil)
    }

    func testThatItReturnsANewSnapshotAndKeysOnceIfThereIsANewObjectInARelationship()
    {
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        let observedKeys = KeySet(key: "messages")
        
        let sut = ObjectSnapshot(object:conversation, keys:observedKeys)
        
        // when
        conversation.appendMessage(withText: "foo");
        
        if let (snapshot, keysAndOldValues) = sut.updatedSnapshot(conversation, affectedKeys: AffectedKeys.some(observedKeys)) {
            let allKeys = Array(keysAndOldValues.keys)
            XCTAssertEqual(allKeys, [KeyPath.keyPathForString("messages")])
            AssertKeyPathDictionaryHasOptionalValue(keysAndOldValues, key: KeyPath.keyPathForString("messages"), expected: NSOrderedSet())
            
            // once?
            let newSnapshot = ObjectSnapshot(object: conversation, keys: observedKeys)
            XCTAssertEqual(snapshot, newSnapshot)
        }
        else {
            XCTFail("Should not be empty")
        }
    }
    
    
    func testThatItDoesNotReturnANewSnapshotIfThereIsAChangedObjectInARelationship()
    {
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        let user = ZMUser.insertNewObject(in:self.uiMOC)
        conversation.mutableOtherActiveParticipants.add(user)
        let observedKeys = KeySet(["mutableOtherActiveParticipants"])
        
        let sut = ObjectSnapshot(object:conversation, keys:observedKeys)
        
        // when
        user.accentColorValue = ZMAccentColor.softPink
        let result = sut.updatedSnapshot(conversation, affectedKeys: AffectedKeys.some(observedKeys))
        
        // then
        XCTAssertTrue(result == nil)
    }
    
    func checkThatItReturnsANewSnapshotIfThereIsANewObject<T : NSObject>(_ key: String, mutator: (T) -> Void) -> Bool
    {
        // given
        let foo = Foo()
        let observedKeys = KeySet(["array","set","orderedSet","dict","data","string"])
        let sut = ObjectSnapshot(object:foo, keys:observedKeys)
        
        // when
        mutator(foo.value(forKey: key) as! T)
        if let (newSnapshot, keysAndOldValues) = sut.updatedSnapshot(foo, affectedKeys: AffectedKeys.all) {
            
            let expectedSnapshot = ObjectSnapshot(object: foo, keys: observedKeys)
            let a = (expectedSnapshot == newSnapshot)
            let b1 = KeySet(keyPaths: Array(keysAndOldValues.keys))
            let b2 = KeySet(key: key as String)
            let b = b1 == b2
            return a && b
        } else {
            return false
        }
    }

    func testThatItReturnsANewSnapshotAndKeysAfterAChangeInAMutableObject()
    {
        XCTAssertTrue(checkThatItReturnsANewSnapshotIfThereIsANewObject("array",
            mutator: {
                (array : NSMutableArray) in array.add("Bar")
        }))

        XCTAssertTrue(checkThatItReturnsANewSnapshotIfThereIsANewObject("set",
            mutator: {
                (set : NSMutableSet) in set.add("Bar")
        }))
        XCTAssertTrue(checkThatItReturnsANewSnapshotIfThereIsANewObject("dict",
            mutator: {
                (dict : NSMutableDictionary) in dict.setValue("Bar", forKey: "foo")
        }))
        XCTAssertTrue(checkThatItReturnsANewSnapshotIfThereIsANewObject("orderedSet",
            mutator: {
                (orderedSet : NSMutableOrderedSet) in orderedSet.add("Bar")
        }))
        XCTAssertTrue(checkThatItReturnsANewSnapshotIfThereIsANewObject("data",
            mutator: {
                (data : NSMutableData) in data.append(Data(bytes: [1,2,3,4]))
        }))
        XCTAssertTrue(checkThatItReturnsANewSnapshotIfThereIsANewObject("string",
            mutator: {
                (string : NSMutableString) in string.append("bla")
        }))
    }
}

