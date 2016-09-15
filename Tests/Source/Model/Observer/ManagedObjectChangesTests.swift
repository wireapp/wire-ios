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

class ManagedObjectChangesTests: ZMBaseManagedObjectTest {

    func testThatItCreatesTheObjectCorrectly() {
        let inserted = createManagedObjects(10)
        let deleted = createManagedObjects(10)
        let updated = createManagedObjects(10)
        
        let sut = ManagedObjectChanges(inserted: inserted, deleted: deleted, updated: updated)
        XCTAssertEqual(sut.inserted, inserted)
        XCTAssertEqual(sut.deleted, deleted)
        XCTAssertEqual(sut.updated, updated)
    }
    
    func testThatItFiltersOutZombies() {
        let sut = ManagedObjectChanges(
            inserted: createZombies(5),
            deleted: createZombies(5),
            updated: createZombies(5)
        )
        
        let filtered = sut.changesWithoutZombies
        XCTAssertTrue(filtered.inserted.isEmpty)
        XCTAssertTrue(filtered.updated.isEmpty)
        XCTAssertEqual(filtered.deleted.count, 5)
    }
    
    func testThatItAppendsChangesToOtherChanges() {
        let inserted = createManagedObjects(2)
        let deleted = createManagedObjects(3)
        let updated = createManagedObjects(4)
        
        let otherInserted = createManagedObjects(4)
        let otherDeleted = createManagedObjects(3)
        let otherUpdated = createManagedObjects(2)
        
        let sut = ManagedObjectChanges(inserted: inserted, deleted: deleted, updated: updated)
        let other = ManagedObjectChanges(inserted: otherInserted, deleted: otherDeleted, updated: otherUpdated)
        let sum = sut + other
        
        XCTAssertEqual(sum.inserted, inserted + otherInserted)
        XCTAssertEqual(sum.deleted, deleted + otherDeleted)
        XCTAssertEqual(sum.updated, updated + otherUpdated)
    }

    func testThePerformanceOfTheFilteringOfZombieObjects() {

        let objects = createZombies(250) + createManagedObjects(250)
        let (inserted, deleted, updated) = (objects, objects, objects)
        let sut = ManagedObjectChanges(inserted: inserted, deleted: deleted, updated: updated)
        
        measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: false) {
            self.startMeasuring()
            let filtered = sut.changesWithoutZombies
            self.stopMeasuring()
            
            XCTAssertEqual(filtered.inserted.count, 250)
            XCTAssertEqual(filtered.deleted.count, 500)
            XCTAssertEqual(filtered.updated.count, 250)
        }
    }

}

// MARK: - Helper

extension ManagedObjectChangesTests {
    
    func createZombies(_ count: Int) -> [ZMManagedObject] {
        
        var objects = [ZMManagedObject]()
        for _ in 1...count {
            let obj = ZMUser.insertNewObject(in: uiMOC)
            obj.remoteIdentifier = UUID.create()
            objects.append(obj)
        }
        
        objects.forEach(uiMOC.delete)
        XCTAssertEqual(objects.count, count)
        ZMAssertAllTrue(objects) { $0.isZombieObject }
        return objects
    }
    
    func createManagedObjects(_ count: Int) -> [ZMManagedObject] {
        
        var objects = [ZMManagedObject]()
        for _ in 1...count {
            let obj = ZMConversation.insertNewObject(in: uiMOC)
            obj.remoteIdentifier = UUID.create()
            objects.append(obj)
        }
        
        ZMAssertAllFalse(objects) { $0.isZombieObject }
        return objects
    }
    
}

// MARK: - Custom Assertions

func ZMAssertAllTrue<E>(_ sequence: E, _ predicate: @escaping (E.Iterator.Element) -> Bool) where E: Sequence {
    sequence.forEach {
        XCTAssertTrue(predicate($0))
    }
}

func ZMAssertAllFalse<E>(_ sequence: E, _ predicate: @escaping (E.Iterator.Element) -> Bool) where E: Sequence {
    ZMAssertAllTrue(sequence) { !predicate($0) }
}
