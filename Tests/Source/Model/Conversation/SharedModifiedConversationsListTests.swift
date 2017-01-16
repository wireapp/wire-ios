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


@testable import ZMCDataModel


fileprivate extension Notification {

    init(inserted: [NSManagedObject] = [], updated: [NSManagedObject] = [], deleted: [NSManagedObject] = []) {
        self.init(name: .NSManagedObjectContextDidSave, userInfo: [
            NSInsertedObjectsKey: Set<NSManagedObject>(inserted),
            NSUpdatedObjectsKey: Set<NSManagedObject>(updated),
            NSDeletedObjectsKey: Set<NSManagedObject>(deleted)
        ])
    }

}


class ContextDidSaveNotificationPersistenceTests: BaseZMMessageTests {

    var sut: ContextDidSaveNotificationPersistence!

    override func setUp() {
        super.setUp()
        sut = ContextDidSaveNotificationPersistence()
    }

    override func tearDown() {
        sut.clear()
        super.tearDown()
    }

    func testThatItCanStoreAndReadAChangeNotification() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let uri = conversation.objectID.uriRepresentation()
        XCTAssertNotNil(uri)

        // When
        sut.add(.init(inserted: [conversation]))

        // Then
        let expected = [NSInsertedObjectsKey: [uri] as AnyObject] as [AnyHashable: AnyObject]
        XCTAssertEqual(sut.storedNotifications.count, 1)

        for (key, value) in sut.storedNotifications.first! {
            XCTAssertEqual(value as? Set<NSManagedObject>, expected[key] as? Set<NSManagedObject>)
        }
    }

    func testThatItCanClearTheStoredNotifications() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        XCTAssertNotNil(conversation.objectID.uriRepresentation())
        sut.add(.init(inserted: [conversation]))
        XCTAssertEqual(sut.storedNotifications.count, 1)

        // When
        sut.clear()

        // Then
        XCTAssertEqual(sut.storedNotifications.count, 0)

    }

    func testThatItCanSaveMultipleNotifications() {
        // Given
        let firstConversation = ZMConversation.insertNewObject(in: uiMOC)
        let firstURI = firstConversation.objectID.uriRepresentation()

        let secondConversation = ZMConversation.insertNewObject(in: uiMOC)
        let secondURI = secondConversation.objectID.uriRepresentation()

        // When
        sut.add(.init(inserted: [firstConversation], deleted: [firstConversation]))

        // Then
        XCTAssertEqual(sut.storedNotifications.count, 1)

        // When
        sut.add(.init(updated: [secondConversation]))

        // Then
        XCTAssertEqual(sut.storedNotifications.count, 2)

        // Then
        let firstExpected = [
            NSInsertedObjectsKey: [firstURI] as AnyObject,
            NSDeletedObjectsKey: [secondURI] as AnyObject
            ] as [AnyHashable: AnyObject]

        let secondExpected = [
            NSUpdatedObjectsKey: [secondURI] as AnyObject
            ] as [AnyHashable: AnyObject]

        for (key, value) in sut.storedNotifications.first! {
            XCTAssertEqual(value as? Set<NSManagedObject>, firstExpected[key] as? Set<NSManagedObject>)
        }

        for (key, value) in sut.storedNotifications.last! {
            XCTAssertEqual(value as? Set<NSManagedObject>, secondExpected[key] as? Set<NSManagedObject>)
        }
    }


}


