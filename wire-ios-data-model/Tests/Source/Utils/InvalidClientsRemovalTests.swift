//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import WireTesting
import XCTest
@testable import WireDataModel

class InvalidClientsRemovalTests: DiskDatabaseTest {
    override class func setUp() {
        super.setUp()
        DeveloperFlag.storage = UserDefaults(suiteName: UUID().uuidString)!
        var flag = DeveloperFlag.proteusViaCoreCrypto
        flag.isOn = false
    }

    override class func tearDown() {
        super.tearDown()
        DeveloperFlag.storage = UserDefaults.standard
    }

    func testThatItDoesNotRemoveValidClients() throws {
        // Given
        let user = ZMUser.insertNewObject(in: moc)
        let client = UserClient.insertNewObject(in: moc)
        client.user = user
        try moc.save()

        // When
        WireDataModel.InvalidClientsRemoval.removeInvalid(in: moc)

        // Then
        XCTAssertFalse(client.isDeleted)
        XCTAssertFalse(client.isZombieObject)
    }

    func testThatItDoesRemoveInvalidClient() throws {
        // Given
        let user = ZMUser.insertNewObject(in: moc)
        let client = UserClient.insertNewObject(in: moc)
        client.user = user
        let otherClient = UserClient.insertNewObject(in: moc)
        try moc.save()

        // When
        WireDataModel.InvalidClientsRemoval.removeInvalid(in: moc)

        // Then
        XCTAssertFalse(client.isDeleted)
        XCTAssertFalse(client.isZombieObject)
        XCTAssertTrue(otherClient.isDeleted)
        XCTAssertTrue(otherClient.isZombieObject)
    }

    func createSelfClient(in moc: NSManagedObjectContext) -> UserClient {
        let selfUser = ZMUser.selfUser(in: moc)
        if selfUser.remoteIdentifier == nil {
            selfUser.remoteIdentifier = .create()
        }
        let selfClient = UserClient.insertNewObject(in: moc)
        selfClient.remoteIdentifier = UUID.create().uuidString
        selfClient.user = selfUser
        moc.setPersistentStoreMetadata(selfClient.remoteIdentifier, key: ZMPersistedClientIdKey)
        moc.saveOrRollback()
        return selfClient
    }
}
