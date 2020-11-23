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

class StorageStackTests_Backup: DatabaseBaseTest {

    override func setUp() {
        super.setUp()
        StorageStack.shared.createStorageAsInMemory = false
    }

    override func tearDown() {
        StorageStack.clearBackupDirectory(dispatchGroup: dispatchGroup)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertFalse(FileManager.default.fileExists(atPath: StorageStack.backupsDirectory.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: StorageStack.importsDirectory.path))
        super.tearDown()
    }
    
    func createBackup(accountIdentifier: UUID, encryptionKeys: EncryptionKeys? = nil, file: StaticString = #file, line: UInt = #line) -> Result<URL>? {

        var result: Result<URL>?
        StorageStack.backupLocalStorage(accountIdentifier: accountIdentifier,
                                        clientIdentifier: name,
                                        applicationContainer: applicationContainer,
                                        dispatchGroup: self.dispatchGroup,
                                        encryptionKeys: encryptionKeys) {
            result = $0.map { $0.url }
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)
        return result
    }
    
    func importBackup(accountIdentifier: UUID, backup: URL, file: StaticString = #file, line: UInt = #line) -> Result<URL>? {
        
        var result: Result<URL>?
        StorageStack.importLocalStorage(accountIdentifier: accountIdentifier, from: backup, applicationContainer: applicationContainer, dispatchGroup: dispatchGroup) {
             result = $0
        }
        
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)
        return result
    }
    
    func createBackupAndDeleteOriginalAccount(accountIdentifier: UUID, file: StaticString = #file, line: UInt = #line) -> URL? {
        // create populated account database
        let directory = createStorageStackAndWaitForCompletion(userID: accountIdentifier)
        _ = ZMConversation.insertGroupConversation(moc: directory.uiContext, participants: [ZMUser]())
        directory.uiContext.saveOrRollback()
        
        guard let result = createBackup(accountIdentifier: accountIdentifier) else { return nil }
        guard case .success(let url) = result else { return nil }
        
        // Delete account
        StorageStack.reset()
        clearStorageFolder()
        
        return url
    }
    
    // MARK: - Export

    func testThatItFailsWithWrongAccountIdentifier() throws {
        // given
        let uuid = UUID()
        _ = createStorageStackAndWaitForCompletion(userID: uuid)

        // when
        guard let result = createBackup(accountIdentifier: UUID()) else { return XCTFail() }

        guard case let .failure(error) = result else { return XCTFail() }

        switch error as? StorageStack.BackupError {
        case .failedToRead?: break
        default: XCTFail("unexpected error type")
        }
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
        let metadataURL = url.appendingPathComponent("export.json")
        
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

        switch error as? StorageStack.BackupError {
        case .failedToWrite?: break
        default: XCTFail("unexpected error type")
        }
    }
    
    func testThatItDisablesEncryptionAtRest_WhenEARIsEnableAndEncryptionKeysAreValid() throws {
        // given
        let uuid = UUID()
        let directory = createStorageStackAndWaitForCompletion(userID: uuid)
        directory.uiContext.encryptMessagesAtRest = true
        directory.uiContext.encryptionKeys = validEncryptionKeys
        
        // when
        guard let result = createBackup(accountIdentifier: uuid,
                                        encryptionKeys: validEncryptionKeys) else {
            return XCTFail()
        }
        directory.uiContext.saveOrRollback()
        
        // then
        switch result {
        case let .success(backup):
            let model = NSManagedObjectModel.loadModel()
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            let storeFile = backup.appendingPathComponent("data").appendingStoreFile()
            XCTAssert(FileManager.default.fileExists(atPath: storeFile.path))
            let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            XCTAssertFalse(context.encryptMessagesAtRest)
        case .failure:
            XCTFail()
        }
    }
    
    func testThatItFailsWhenEARIsEnabledAndEncryptionKeysAreNil() throws {
        // given
        let uuid = UUID()
        let directory = createStorageStackAndWaitForCompletion(userID: uuid)
        directory.uiContext.encryptMessagesAtRest = true
        directory.uiContext.encryptionKeys = nil
        directory.uiContext.saveOrRollback()
        
        // when
        guard let result = createBackup(accountIdentifier: uuid,
                                        encryptionKeys: nil) else {
            return XCTFail()
        }

        guard case let .failure(error) = result else { return XCTFail() }
        
        // then
        switch error as? StorageStack.BackupError {
        case .failedToWrite(let failureError):
            switch failureError as? StorageStack.BackupError {
            case .missingEAREncryptionKey: break
            default: XCTFail("unexpected error type")
        }
        default: XCTFail("unexpected error type")
        }
    }
    
    func testThatItPreservesOriginalDataAfterBackup() {
        // given
        let uuid = UUID()
        let directory = createStorageStackAndWaitForCompletion(userID: uuid)
        _ = ZMConversation.insertGroupConversation(moc: directory.uiContext, participants: [])
        directory.uiContext.saveOrRollback()

        // when
        guard let result = createBackup(accountIdentifier: uuid) else { return XCTFail() }

        // then
        guard case .success = result else { return XCTFail() }
        let fetchConversations = ZMConversation.sortedFetchRequest()
        XCTAssertEqual(try directory.uiContext.count(for: fetchConversations), 1)
    }

    func testThatItPreservesOriginaDataAfterBackupIfStackIsNotActive() throws {
        // given
        let uuid = UUID()
        let directory = createStorageStackAndWaitForCompletion(userID: uuid)
        _ = ZMConversation.insertGroupConversation(moc: directory.uiContext, participants: [])
        directory.uiContext.saveOrRollback()
        StorageStack.reset()

        // when
        guard let result = createBackup(accountIdentifier: uuid) else { return XCTFail() }

        // then
        guard case .success = result else { return XCTFail() }
        let anotherDirectory = createStorageStackAndWaitForCompletion(userID: uuid)
        let fetchConversations = ZMConversation.sortedFetchRequest()
        XCTAssertEqual(try anotherDirectory.uiContext.count(for: fetchConversations), 1)
    }
    
    // MARK: - Import
    
    func testThatItCanOpenAnImportedBackup() {
        // given
        let uuid = UUID()
        guard let backup = createBackupAndDeleteOriginalAccount(accountIdentifier: uuid) else { return XCTFail() }
        
        // when
        guard let result = importBackup(accountIdentifier: uuid, backup: backup) else { return XCTFail() }
        
        // then
        guard case .success = result else { return XCTFail() }
        let directory = createStorageStackAndWaitForCompletion(userID: uuid)
        let fetchConversations = ZMConversation.sortedFetchRequest()
        XCTAssertEqual(try directory.uiContext.count(for: fetchConversations), 1)
    }
    
    func testThatMetadataIsDeletedWhenImportingBackup() {
        // given
        let uuid = UUID()
        let directory = createStorageStackAndWaitForCompletion(userID: uuid)
        
        // Set metadata on DB which we expect to be cleared when importing from a backup
        directory.uiContext.setPersistentStoreMetadata("1234567890", key: ZMPersistedClientIdKey)
        directory.uiContext.setPersistentStoreMetadata("1234567890", key: PersistentMetadataKey.pushToken.rawValue)
        directory.uiContext.setPersistentStoreMetadata("1234567890", key: PersistentMetadataKey.pushKitToken.rawValue)
        directory.uiContext.setPersistentStoreMetadata("1234567890", key: PersistentMetadataKey.lastUpdateEventID.rawValue)
        directory.uiContext.forceSaveOrRollback()
        
        guard let backup = createBackup(accountIdentifier: uuid)?.value else { return XCTFail() }
        
        // Delete account
        StorageStack.reset()
        clearStorageFolder()
        
        // when
        guard let result = importBackup(accountIdentifier: uuid, backup: backup) else { return XCTFail() }
        guard case .success = result else { return XCTFail() }
        let importedDirectory = createStorageStackAndWaitForCompletion(userID: uuid)
        
        // then
        XCTAssertNil(importedDirectory.uiContext.persistentStoreMetadata(forKey: ZMPersistedClientIdKey))
        XCTAssertNil(importedDirectory.uiContext.persistentStoreMetadata(forKey: PersistentMetadataKey.pushToken.rawValue))
        XCTAssertNil(importedDirectory.uiContext.persistentStoreMetadata(forKey: PersistentMetadataKey.pushKitToken.rawValue))
        XCTAssertNil(importedDirectory.uiContext.persistentStoreMetadata(forKey: PersistentMetadataKey.lastUpdateEventID.rawValue))
    }
    
    func testThatItFailsWhenImportingBackupIntoWrongAccount() {
        // given
        let uuid = UUID()
        guard let backup = createBackupAndDeleteOriginalAccount(accountIdentifier: uuid) else { return XCTFail() }
        
        // when
        let differentUUID = UUID()
        guard let result = importBackup(accountIdentifier: differentUUID, backup: backup) else { return XCTFail() }
    
        // then
        guard case let .failure(error) = result else { return XCTFail() }
        switch error as? StorageStack.BackupImportError {
        case .incompatibleBackup?: break
        default: XCTFail()
        }
    }
    
    func testThatItFailsWhenImportingNonExistantBackup() {
        // given
        let uuid = UUID()
        let backup = applicationContainer.appendingPathComponent("non-existing-backup")
        
        // when
        guard let result = importBackup(accountIdentifier: uuid, backup: backup) else { return XCTFail() }
        
        // then
        guard case let .failure(error) = result else { return XCTFail() }
        switch error as? StorageStack.BackupImportError {
        case .failedToCopy?: break
        default: XCTFail()
        }
    }
}
