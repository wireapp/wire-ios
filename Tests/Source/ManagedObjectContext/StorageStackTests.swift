//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

class StorageStackTests: DatabaseBaseTest {
    
    func testThatItCreatesSubfolderForStorageWithUUID() {
        
        // GIVEN
        let userID = UUID.create()
        let accountFolder = StorageStack.accountFolder(accountIdentifier: userID, applicationContainer: self.applicationContainer)
        
        // WHEN
        _ = self.createStorageStackAndWaitForCompletion(userID: userID)

        // THEN
        XCTAssertTrue(FileManager.default.fileExists(atPath: accountFolder.path))
    }
    
    func testThatTheContextDirectoryIsTornDown() {
        
        // GIVEN
        weak var contextDirectory: ManagedObjectContextDirectory? = self.createStorageStackAndWaitForCompletion()

        // WHEN
        StorageStack.reset()
        
        // THEN
        XCTAssertNil(contextDirectory)
    }
    
    func testThatNoMigrationIsNeededForInMemoryDatabase() {
        // GIVEN
        StorageStack.shared.createStorageAsInMemory = true
        let uuid = UUID.create()
        
        // THEN
        XCTAssertFalse(StorageStack.shared.needsToRelocateOrMigrateLocalStack(accountIdentifier: uuid, applicationContainer: self.applicationContainer))
    }
    
    func testThatItCanReopenAPreviouslyExistingDatabase() {
    
        // GIVEN
        let firstStackExpectation = self.expectation(description: "Callback invoked")
        let testValue = "12345678"
        let testKey = "aassddffgg"
        var contextDirectory: ManagedObjectContextDirectory! = nil
        StorageStack.shared.createManagedObjectContextDirectory(
            accountIdentifier: accountID,
            applicationContainer: self.applicationContainer
        ) { directory in
            contextDirectory = directory
            firstStackExpectation.fulfill()
        }
        
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 1))
        
        // create an entry to check that it is reopening the same DB
        contextDirectory.uiContext.setPersistentStoreMetadata(testValue, key: testKey)
        let conversationTemp = ZMConversation.insertNewObject(in: contextDirectory.uiContext)
        contextDirectory.uiContext.forceSaveOrRollback()
        let objectID = conversationTemp.objectID
        contextDirectory = nil
        StorageStack.reset()
        
        // WHEN

        let secondStackExpectation = self.expectation(description: "Callback invoked")
        
        StorageStack.shared.createManagedObjectContextDirectory(
            accountIdentifier: accountID,
            applicationContainer: self.applicationContainer
        ) { directory in
            contextDirectory = directory
            secondStackExpectation.fulfill()
        }
        
        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 1))
        XCTAssertEqual(contextDirectory.uiContext.persistentStoreCoordinator!.persistentStores.count, 1)

        guard let readValue = contextDirectory.uiContext.persistentStoreMetadata(forKey: testKey) as? String else {
            XCTFail("Can't read previous value from the context")
            return
        }
        guard let _ = try? contextDirectory.uiContext.existingObject(with: objectID) as? ZMConversation else {
            XCTFail("Can't find previous conversation in the context")
            return
        }
        XCTAssertEqual(readValue, testValue)
    }

    func testThatItCanReopenAPreviouslyExistingDatabase_InMemory() {

        // GIVEN
        StorageStack.shared.createStorageAsInMemory = true
        let testValue = "12345678"
        let testKey = "aassddffgg"
        var contextDirectory: ManagedObjectContextDirectory! = nil
        StorageStack.shared.createManagedObjectContextDirectory(accountIdentifier: accountID,
            applicationContainer: applicationContainer,
            dispatchGroup: dispatchGroup,
            completionHandler: { contextDirectory = $0 }
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // create an entry to check that it is reopening the same DB
        contextDirectory.uiContext.setPersistentStoreMetadata(testValue, key: testKey)
        let conversationTemp = ZMConversation.insertNewObject(in: contextDirectory.uiContext)
        contextDirectory.uiContext.forceSaveOrRollback()
        let objectID = conversationTemp.objectID
        contextDirectory = nil

        // WHEN
        StorageStack.shared.createManagedObjectContextDirectory(
            accountIdentifier: accountID,
            applicationContainer: applicationContainer,
            dispatchGroup: dispatchGroup,
            completionHandler: { contextDirectory = $0 }
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        contextDirectory.uiContext.setPersistentStoreMetadata(testValue, key: testKey)
        XCTAssertEqual(contextDirectory.uiContext.persistentStoreCoordinator!.persistentStores.count, 1)

        guard let readValue = contextDirectory.uiContext.persistentStoreMetadata(forKey: testKey) as? String else {
            return XCTFail("Can't read previous value from the context")

        }
        guard let _ = try? contextDirectory.uiContext.existingObject(with: objectID) as? ZMConversation else {
            return XCTFail("Can't find previous conversation in the context")
        }
        XCTAssertEqual(readValue, testValue)
        StorageStack.shared.createStorageAsInMemory = false
    }
    
    func testThatItPerformsMigrationCallbackWhenDifferentVersion() throws {
        
        // GIVEN
        let completionExpectation = self.expectation(description: "Callback invoked")
        let migrationExpectation = self.expectation(description: "Migration started")
        let storeFile = StorageStack.accountFolder(accountIdentifier: accountID, applicationContainer: self.applicationContainer).appendingPersistentStoreLocation()
        try FileManager.default.createDirectory(at: storeFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        // copy old version database into the expected location
        guard let source = Bundle(for: type(of: self)).url(forResource: "store2-3", withExtension: "wiredatabase") else {
            XCTFail("missing resource")
            return
        }
        let destination = URL(string: storeFile.absoluteString)!
        try FileManager.default.copyItem(at: source, to: destination)
        
        // WHEN
        var contextDirectory: ManagedObjectContextDirectory? = nil
        XCTAssertTrue(StorageStack.shared.needsToRelocateOrMigrateLocalStack(accountIdentifier: accountID, applicationContainer: self.applicationContainer))
        StorageStack.shared.createManagedObjectContextDirectory(
            accountIdentifier: accountID,
            applicationContainer: self.applicationContainer,
            startedMigrationCallback: { migrationExpectation.fulfill() }
        ) { directory in
            contextDirectory = directory
            completionExpectation.fulfill()
        }
        
        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 2))
        guard let uiContext = contextDirectory?.uiContext else {
            XCTFail("No context")
            return
        }
        let messageCount = try uiContext.count(for: ZMClientMessage.sortedFetchRequest())
        XCTAssertGreaterThan(messageCount, 0)
        
    }
    
    func testThatItPerformsMigrationWhenStoreIsInOldLocation() {
        
        let testValue = "12345678"
        let testKey = "aassddffgg"
        let sessionID = EncryptionSessionIdentifier(userId: "test", clientId: "session")
        
        zip(previousDatabaseLocations, previousKeyStoreLocations).forEach { oldDatabasePath, oldKeystorePath in

            // GIVEN
            StorageStack.reset()
            self.clearStorageFolder()
            
            let oldStoreFile = oldDatabasePath.appendingStoreFile()
            self.createLegacyStore(filePath: oldStoreFile) { contextDirectory in
                contextDirectory.uiContext.setPersistentStoreMetadata(testValue, key: testKey)
                contextDirectory.uiContext.forceSaveOrRollback()
            }
            self.createSessionInKeyStore(accountDirectory: oldKeystorePath, applicationContainer: self.applicationContainer, sessionId: sessionID)
            let accountDirectory = StorageStack.accountFolder(accountIdentifier: self.accountID, applicationContainer: self.applicationContainer)
            
            // expectations
            let migrationExpectation = self.expectation(description: "Migration started")
            let completionExpectation = self.expectation(description: "Stack initialization completed")
            
            // WHEN
            // create the stack, check that the value is there and that it calls the migration callback
            var newStoreFile: URL? = nil
            XCTAssertTrue(StorageStack.shared.needsToRelocateOrMigrateLocalStack(accountIdentifier: self.accountID, applicationContainer: self.applicationContainer))
            StorageStack.shared.createManagedObjectContextDirectory(
                accountIdentifier: self.accountID,
                applicationContainer: self.applicationContainer,
                startedMigrationCallback: { migrationExpectation.fulfill() }
            ) { MOCs in
                defer { completionExpectation.fulfill() }
                guard let string = MOCs.uiContext.persistentStoreMetadata(forKey: testKey) as? String else {
                    return XCTFail("Failed to find same value after migrating from \(oldDatabasePath.path)")
                }
                newStoreFile = MOCs.uiContext.persistentStoreCoordinator!.persistentStores.first!.url
                XCTAssertEqual(string, testValue)
            }
            
            // THEN
            XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 1))
            
            // check that all files are in the new location
            if let newStore = newStoreFile {
                XCTAssertTrue(checkSupportFilesExists(storeFile: newStore))
            } else {
                XCTFail()
            }
            XCTAssertFalse(checkSupportFilesExists(storeFile: oldStoreFile))
            
            let keyStoreFolder = FileManager.keyStoreURL(accountDirectory: oldKeystorePath, createParentIfNeeded: false)
            XCTAssertFalse(FileManager.default.fileExists(atPath: keyStoreFolder.path))
            XCTAssertTrue(self.doesSessionExistInKeyStore(accountDirectory: accountDirectory, applicationContainer: self.applicationContainer, sessionId: sessionID))
            
            StorageStack.reset()
        }
    }
    
    func testThatItPerformsMigrationWhenThereExistsMultipleLegacyStores() throws {
        
        let testKey = "aassddffgg"
        let testValue = "eggplant"
        let sessionID = EncryptionSessionIdentifier(userId: "test", clientId: "session")
        
        let oldPath = self.previousDatabaseLocations.first!
        
        // GIVEN
        StorageStack.reset()	
        
        // create a single legacy store
        let oldStoreFile = oldPath.appendingStoreFile()
        self.createLegacyStore(filePath: oldStoreFile) { contextDirectory in
            contextDirectory.uiContext.setPersistentStoreMetadata(testValue, key: testKey)
            contextDirectory.uiContext.forceSaveOrRollback()
        }
        
        self.createSessionInKeyStore(accountDirectory: oldPath, applicationContainer: self.applicationContainer, sessionId: sessionID)
        
        // copy the store to all remaining possible legacy locations
        try previousDatabaseLocations.filter { $0 != oldPath }.forEach { oldLocation in
            // copy store files
            try ["-shm", "-wal", ""].forEach { storeFileExtension in
                let source = oldStoreFile.appendingSuffixToLastPathComponent(suffix: storeFileExtension)
                let destination = oldLocation.appendingStoreFile().appendingSuffixToLastPathComponent(suffix: storeFileExtension)
                try FileManager.default.createDirectory(at: oldLocation, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: source, to: destination)
            }

            // copy keystore
            let source = oldPath.appendingPathComponent("otr", isDirectory: true)
            let destination = oldLocation.appendingPathComponent("otr", isDirectory: true)
            try FileManager.default.copyItem(at: source, to: destination)
        }
        
        // expectations
        let migrationExpectation = self.expectation(description: "Migration started")
        let completionExpectation = self.expectation(description: "Stack initialization completed")
        
        // WHEN
        // create the stack, check that the value is there and that it calls the migration callback
        var newStoreFile: URL? = nil
        StorageStack.shared.createManagedObjectContextDirectory(
            accountIdentifier: accountID,
            applicationContainer: self.applicationContainer,
            startedMigrationCallback: { migrationExpectation.fulfill() }
        ) { MOCs in
            defer { completionExpectation.fulfill() }
            guard let string = MOCs.uiContext.persistentStoreMetadata(forKey: testKey) as? String else {
                XCTFail("Failed to find same value after migrating")
                return
            }
            newStoreFile = MOCs.uiContext.persistentStoreCoordinator!.persistentStores.first!.url
            XCTAssertEqual(string, testValue)
        }
        
        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 1))
        
        // check that all files are in the new location
        if let newStore = newStoreFile {
            XCTAssertTrue(checkSupportFilesExists(storeFile: newStore))
        } else {
            XCTFail()
        }
        
        let accountDirectory = StorageStack.accountFolder(accountIdentifier: accountID, applicationContainer: self.applicationContainer)
        
        // check all legacy databses and keystores deleted
        zip(previousDatabaseLocations, previousKeyStoreLocations).forEach { databaseFolder, keyStorePath in
            XCTAssertFalse(checkSupportFilesExists(storeFile: databaseFolder.appendingStoreFile()))
            let keyStoreFolder = FileManager.keyStoreURL(accountDirectory: keyStorePath, createParentIfNeeded: false)
            XCTAssertFalse(FileManager.default.fileExists(atPath: keyStoreFolder.path), "File still exists at \(keyStorePath.path)")
        }
        
        // new keystore exists
        XCTAssertTrue(self.doesSessionExistInKeyStore(accountDirectory: accountDirectory, applicationContainer: self.applicationContainer, sessionId: sessionID))
        StorageStack.reset()
    }
    
    func testThatItDoesNotInvokeTheMigrationCallbackWhenThereIsNoMigration() {
        
        // GIVEN
        let completionExpectation = self.expectation(description: "Callback invoked")
        
        // WHEN
        XCTAssertFalse(StorageStack.shared.needsToRelocateOrMigrateLocalStack(accountIdentifier: accountID, applicationContainer: self.applicationContainer))
        StorageStack.shared.createManagedObjectContextDirectory(
            accountIdentifier: accountID,
            applicationContainer: self.applicationContainer,
            startedMigrationCallback: { XCTFail() }
        ) { directory in
            completionExpectation.fulfill()
        }
        
        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }
    
    func testThatWhenMigrationIsInterruptedAfterMigratingKeystoreItCanBeRestarted() {
    
        // To simulate an interrupted migration, we create the legacy store and
        // migrate the keystore immediately. Then we start the migration from this
        // inconsistent state.
        
        let testKey = "aassddffgg"
        let testValue = "eggplant"
        let sessionID = EncryptionSessionIdentifier(userId: "test", clientId: "session")
        
        let oldPath = self.previousDatabaseLocations.first!
        let accountDirectory = StorageStack.accountFolder(accountIdentifier: accountID, applicationContainer: self.applicationContainer)
        
        // GIVEN
        StorageStack.reset()
        
        // create a single legacy store
        let oldStoreFile = oldPath.appendingStoreFile()
        self.createLegacyStore(filePath: oldStoreFile) { contextDirectory in
            contextDirectory.uiContext.setPersistentStoreMetadata(testValue, key: testKey)
            contextDirectory.uiContext.forceSaveOrRollback()
        }
        
        // migrate the keystore already
        self.createSessionInKeyStore(accountDirectory: oldPath, applicationContainer: self.applicationContainer, sessionId: sessionID)
        UserClientKeysStore.migrateIfNeeded(accountIdentifier: accountID, accountDirectory: accountDirectory, applicationContainer: self.applicationContainer)
        
        // expectations
        let migrationExpectation = self.expectation(description: "Migration started")
        let completionExpectation = self.expectation(description: "Stack initialization completed")
        
        // WHEN
        // create the stack, check that the value is there and that it calls the migration callback
        var newStoreFile: URL? = nil
        StorageStack.shared.createManagedObjectContextDirectory(
            accountIdentifier: accountID,
            applicationContainer: self.applicationContainer,
            startedMigrationCallback: { migrationExpectation.fulfill() }
        ) { MOCs in
            defer { completionExpectation.fulfill() }
            guard let string = MOCs.uiContext.persistentStoreMetadata(forKey: testKey) as? String else {
                XCTFail("Failed to find same value after migrating")
                return
            }
            newStoreFile = MOCs.uiContext.persistentStoreCoordinator!.persistentStores.first!.url
            XCTAssertEqual(string, testValue)
        }
        
        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 1))
        
        // check that all files are in the new location
        if let newStore = newStoreFile {
            XCTAssertTrue(checkSupportFilesExists(storeFile: newStore))
        } else {
            XCTFail()
        }
        
        // check all legacy stores deleted
        for oldPath in self.previousDatabaseLocations {
            let oldStoreFile = oldPath.appendingStoreFile()
            XCTAssertFalse(checkSupportFilesExists(storeFile: oldStoreFile))
            let keyStoreFolder = FileManager.keyStoreURL(accountDirectory: oldPath, createParentIfNeeded: false)
            XCTAssertFalse(FileManager.default.fileExists(atPath: keyStoreFolder.path))
        }
        
        // new keystore exists
        XCTAssertTrue(self.doesSessionExistInKeyStore(accountDirectory: accountDirectory, applicationContainer: self.applicationContainer, sessionId: sessionID))
        StorageStack.reset()
    }
    
    func testThatWhenMigrationIsInterruptedDuringKeystoreMigrationItCanBeRestarted() {
        
        // To simulate an interrupted migration, we create the legacy store and
        // migrate the keystore immediately, recreate the legacy keystore, then restart 
        // the migration from this inconsistent state.
        
        let sessionID = EncryptionSessionIdentifier(userId: "test", clientId: "session")
        
        let oldPath = self.previousDatabaseLocations.first!
        let accountDirectory = StorageStack.accountFolder(accountIdentifier: accountID, applicationContainer: self.applicationContainer)
        
        // GIVEN
        StorageStack.reset()
        
        // create a single legacy store
        let oldStoreFile = oldPath.appendingStoreFile()
        self.createLegacyStore(filePath: oldStoreFile) { _ in }
        
        
        // migrate the keystore already
        self.createSessionInKeyStore(accountDirectory: oldPath, applicationContainer: self.applicationContainer, sessionId: sessionID)
        UserClientKeysStore.migrateIfNeeded(accountIdentifier: accountID, accountDirectory: accountDirectory, applicationContainer: self.applicationContainer)
        
        // expectations
        let migrationExpectation = self.expectation(description: "Migration started")
        let completionExpectation = self.expectation(description: "Stack initialization completed")
        
        // WHEN
        // create the stack, check that the value is there and that it calls the migration callback
        StorageStack.shared.createManagedObjectContextDirectory(
            accountIdentifier: accountID,
            applicationContainer: self.applicationContainer,
            startedMigrationCallback: { migrationExpectation.fulfill() }
        ) { MOCs in
            _ = MOCs.uiContext.persistentStoreCoordinator!.persistentStores.first!.url
            completionExpectation.fulfill()
        }
        
        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 1))
        
        // new keystore exists
        XCTAssertTrue(self.doesSessionExistInKeyStore(accountDirectory: accountDirectory, applicationContainer: self.applicationContainer, sessionId: sessionID))
        StorageStack.reset()
        
    }
}

// MARK: - Legacy User ID

extension StorageStackTests {
    
    func testThatItReturnsNilWhenLegacyStoreDoesNotExist() {
        
        // GIVEN
        let completionExpectation = self.expectation(description: "Callback invoked")
        
        // WHEN
        StorageStack.shared.fetchUserIDFromLegacyStore(
            applicationContainer: self.applicationContainer,
            startedMigrationCallback: { XCTFail() }
        ) { userID in
            completionExpectation.fulfill()
            XCTAssertNil(userID)
        }
        
        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
    }
    
    func testThatItReturnsNilWhenLegacyStoreExistsButThereIsNoUser() {
        
        // GIVEN
        self.previousDatabaseLocations.forEach { oldPath in
            
            let completionExpectation = self.expectation(description: "Callback invoked")
            self.createLegacyStore(filePath: oldPath.appendingStoreFile())
            
            // WHEN
            StorageStack.shared.fetchUserIDFromLegacyStore(
                applicationContainer: self.applicationContainer,
                startedMigrationCallback: { XCTFail() }
            ) { userID in
                completionExpectation.fulfill()
                XCTAssertNil(userID)
            }
            
            // THEN
            XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
            StorageStack.reset()
            self.clearStorageFolder()
        }
    }
    
    func testThatItReturnsUserIDFromLegacyStoreWhenItExists() {
        
        // GIVEN
        self.previousDatabaseLocationsBeforeMultiAccountSupport.forEach { oldPath in
            
            let completionExpectation = self.expectation(description: "Callback invoked")
            
            self.createLegacyStore(filePath: oldPath.appendingStoreFile()) { contextDirectory in
                ZMUser.selfUser(in: contextDirectory.uiContext).remoteIdentifier = self.accountID
                contextDirectory.uiContext.forceSaveOrRollback()
            }
            
            // WHEN
            StorageStack.shared.fetchUserIDFromLegacyStore(
                applicationContainer: self.applicationContainer,
                startedMigrationCallback: { XCTFail() }
            ) { fetchedUserID in
                completionExpectation.fulfill()
                XCTAssertEqual(self.accountID, fetchedUserID)
            }
            
            // THEN
            XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
            StorageStack.reset()
            clearStorageFolder()
            try? FileManager.default.removeItem(at: oldPath.deletingLastPathComponent())
        }
    }
}

extension StorageStackTests {
    
    /// Checks that all support files exists
    func checkSupportFilesExists(storeFile: URL) -> Bool {
        for ext in PersistentStoreRelocator.storeFileExtensions {
            let supportFile = storeFile.appendingSuffixToLastPathComponent(suffix: ext)
            guard FileManager.default.fileExists(atPath: supportFile.path) else {
                return false
            }
        }
        let supportDirectory = storeFile.deletingLastPathComponent().appendingPathComponent(".store_SUPPORT")
        guard FileManager.default.fileExists(atPath: supportDirectory.path) else {
             return false
        }
        return true
    }
}




