////
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import XCTest
@testable import WireDataModel

class StorageStackBackupTests: DatabaseBaseTest {

    override func setUp() {
        super.setUp()
        StorageStack.shared.createStorageAsInMemory = false
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: StorageStack.backupsDirectory)
        super.tearDown()
    }

    func createBackup(accountIdentifier: UUID, file: StaticString =
        #file, line: UInt = #line) -> Result<URL>? {

        var result: Result<URL>?
        StorageStack.backupLocalStorage(accountIdentifier: accountIdentifier, clientIdentifier: name!, applicationContainer: applicationContainer, dispatchGroup: self.dispatchGroup) {
            result = $0
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)
        return result
    }

    func testThatItFailsWithWrongAccountIdentifier() throws {
        // given
        let uuid = UUID()
        _ = createStorageStackAndWaitForCompletion(userID: uuid)

        // when
        guard let result = createBackup(accountIdentifier: UUID()) else { return XCTFail() }

        guard case let .failure(error) = result else { return XCTFail() }

        XCTAssertEqual(error as? StorageStack.BackupError, .failedToRead)
    }

    func testThatItFindsTheStorageWithCorrectAccountIdentifier() throws {
        // given
        let uuid = UUID()
        _ = createStorageStackAndWaitForCompletion(userID: uuid)

        // when
        guard let result = createBackup(accountIdentifier: uuid) else { return XCTFail() }

        // then
        guard case let .success(url) = result else { return XCTFail() }

        let fm = FileManager.default
        XCTAssertTrue(fm.fileExists(atPath: url.path))
        let databaseDirectory = url.appendingPathComponent("data")
        let metadataURL = url.appendingPathComponent("metadata.json")
        
        XCTAssertTrue(fm.fileExists(atPath: databaseDirectory.path))
        XCTAssertTrue(fm.fileExists(atPath: metadataURL.path))
        XCTAssertTrue(try fm.contentsOfDirectory(atPath: databaseDirectory.path).count > 1)
        XCTAssertTrue(try fm.contentsOfDirectory(atPath: url.path).count > 1)
    }

    func testThatItFailsWhenItCannotCreateTargetDirectory() throws {
        // given
        let uuid = UUID()
        _ = createStorageStackAndWaitForCompletion(userID: uuid)
        // create empty file where backup needs to be saved to
        try Data().write(to: StorageStack.backupsDirectory)

        // when
        guard let result = createBackup(accountIdentifier: uuid) else { return XCTFail() }

        guard case let .failure(error) = result else { return XCTFail() }

        XCTAssertEqual(error as? StorageStack.BackupError, .failedToWrite)
    }

    func testThatItPreservesOriginalDataAfterBackup() {
        // given
        let uuid = UUID()
        let directory = createStorageStackAndWaitForCompletion(userID: uuid)
        _ = ZMConversation.insertGroupConversation(into: directory.uiContext, withParticipants: [])
        directory.uiContext.saveOrRollback()

        // when
        guard let result = createBackup(accountIdentifier: uuid) else { return XCTFail() }

        // then
        guard case .success = result else { return XCTFail() }
        let fetchConversations = ZMConversation.sortedFetchRequest()!
        XCTAssertEqual(try directory.uiContext.count(for: fetchConversations), 1)
    }

    func testThatItPreservesOriginaDataAfterBackupIfStackIsNotActive() throws {
        // given
        let uuid = UUID()
        let directory = createStorageStackAndWaitForCompletion(userID: uuid)
        _ = ZMConversation.insertGroupConversation(into: directory.uiContext, withParticipants: [])
        directory.uiContext.saveOrRollback()
        StorageStack.reset()

        // when
        guard let result = createBackup(accountIdentifier: uuid) else { return XCTFail() }

        // then
        guard case .success = result else { return XCTFail() }
        let anotherDirectory = createStorageStackAndWaitForCompletion(userID: uuid)
        let fetchConversations = ZMConversation.sortedFetchRequest()!
        XCTAssertEqual(try anotherDirectory.uiContext.count(for: fetchConversations), 1)
    }
}
