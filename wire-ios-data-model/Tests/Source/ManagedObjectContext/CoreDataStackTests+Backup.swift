//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

@testable import WireDataModel
@testable import WireDataModelSupport

final class CoreDataStackTests_Backup: DatabaseBaseTest {

    private var migrator: MockCoreDataMessagingMigratorProtocol!
    private var earMigrator: MockEARMigratorProtocol!

    override func setUp() {
        super.setUp()

        migrator = MockCoreDataMessagingMigratorProtocol()
        migrator.requiresMigrationAtToVersion_MockMethod = { _, _ in
            false
        }
        migrator.migrateStoreAtToVersion_MockMethod = { _, _ in }

        earMigrator = MockEARMigratorProtocol()
        earMigrator.migrateTowardEncryptionAtRestContext_MockMethod = { _ in }
        earMigrator.migrateAwayFromEncryptionAtRestContext_MockMethod = { _ in }
    }

    override func tearDown() {
        migrator = nil

        CoreDataStack.clearBackupDirectory(dispatchGroup: dispatchGroup)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertFalse(FileManager.default.fileExists(atPath: CoreDataStack.backupsDirectory.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: CoreDataStack.importsDirectory.path))

        super.tearDown()
    }

    func createBackup(
        accountIdentifier: UUID,
        earMigrator: EARMigratorProtocol? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> URL {
        try await CoreDataStack.backupLocalStorage(
            accountIdentifier: accountIdentifier,
            clientIdentifier: name,
            applicationContainer: DatabaseBaseTest.applicationContainer,
            earMigrator: earMigrator
        ).url
    }

    func importBackup(
        accountIdentifier: UUID,
        backup: URL,
        migrator: CoreDataMessagingMigratorProtocol,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> URL {
        try await CoreDataStack.importLocalStorage(
            accountIdentifier: accountIdentifier,
            from: backup,
            applicationContainer: DatabaseBaseTest.applicationContainer,
            messagingMigrator: migrator
        )
    }

    @MainActor
    func createBackupAndDeleteOriginalAccount(
        accountIdentifier: UUID,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> URL {

        defer { clearStorageFolder() }

        // create populated account database
        let directory = try await createStorageStackAndWaitForCompletion(userID: accountIdentifier)
        _ = ZMConversation.insertGroupConversation(moc: directory.viewContext, participants: [ZMUser]())
        directory.viewContext.saveOrRollback()

        return try await createBackup(accountIdentifier: accountIdentifier)
    }

    // MARK: - Export

    func testThatItFailsWithWrongAccountIdentifier() async throws {
        // given
        _ = try await createStorageStackAndWaitForCompletion(userID: UUID())

        await XCTAssertThrowsErrorAsync {
            // when
            try await createBackup(accountIdentifier: UUID())
        } errorHandler: { error in
            switch error {
            case CoreDataStack.BackupError.failedToRead:
                // then
                break
            default:
                XCTFail("unexpected error: \(error)")
            }
        }
    }

    func testThatItFindsTheStorageWithCorrectAccountIdentifier() async throws {
        // given
        let uuid = UUID()
        _ = try await createStorageStackAndWaitForCompletion(userID: uuid)

        // when
        let url = try await createBackup(accountIdentifier: uuid)

        // then
        let fm = FileManager.default
        XCTAssertTrue(fm.fileExists(atPath: url.path))
        let databaseDirectory = url.appendingPathComponent("data")
        let metadataURL = url.appendingPathComponent("export.json")

        XCTAssertTrue(fm.fileExists(atPath: databaseDirectory.path))
        XCTAssertTrue(fm.fileExists(atPath: metadataURL.path))
        XCTAssertTrue(try fm.contentsOfDirectory(atPath: databaseDirectory.path).count > 1)
        XCTAssertTrue(try fm.contentsOfDirectory(atPath: url.path).count > 1)
    }

    func testThatItFailsWhenItCannotCreateTargetDirectory() async throws {
        // given
        let uuid = UUID()
        _ = try await createStorageStackAndWaitForCompletion(userID: uuid)
        // create empty file where backup needs to be saved to
        try Data().write(to: CoreDataStack.backupsDirectory)

        await XCTAssertThrowsErrorAsync {
            // when
            try await createBackup(accountIdentifier: uuid)
        } errorHandler: { error in
            switch error {
            case CoreDataStack.BackupError.failedToWrite:
                // then
                break
            default:
                XCTFail("unexpected error: \(error)")
            }
        }
    }

    @MainActor
    func testThatItDisablesEncryptionAtRest_WhenEARIsEnableAndMigratorIsValid() async throws {
        // given
        let uuid = UUID()
        let directory = try await createStorageStackAndWaitForCompletion(userID: uuid)
        directory.viewContext.encryptMessagesAtRest = true
        directory.viewContext.saveOrRollback()

        // when
        let backup = try await createBackup(accountIdentifier: uuid, earMigrator: earMigrator)
        directory.viewContext.saveOrRollback()

        // then
        let model = CoreDataStack.loadMessagingModel()
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let storeFile = backup.appendingPathComponent("data").appendingStoreFile()
        _ = try coordinator.addPersistentStore(type: .sqlite, configuration: nil, at: storeFile, options: [:])
        XCTAssert(FileManager.default.fileExists(atPath: storeFile.path))
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        XCTAssertFalse(context.encryptMessagesAtRest)
    }

    @MainActor
    func testThatItFailsWhenEARIsEnabledAndMigratorIsNil() async throws {
        // given
        let uuid = UUID()
        let directory = try await createStorageStackAndWaitForCompletion(userID: uuid)
        directory.viewContext.encryptMessagesAtRest = true
        directory.viewContext.saveOrRollback()

        await XCTAssertThrowsErrorAsync {
            // when
            try await createBackup(accountIdentifier: uuid, earMigrator: nil)
        } errorHandler: { error in
            switch error {
            case CoreDataStack.BackupError.failedToWrite(
                CoreDataStack.BackupError.missingEARMigrator
            ):
                // then
                break
            default:
                XCTFail("unexpected error: \(error)")
            }
        }
    }

    @MainActor
    func testThatItPreservesOriginalDataAfterBackup() async throws {
        // given
        let uuid = UUID()
        let directory = try await createStorageStackAndWaitForCompletion(userID: uuid)
        _ = ZMConversation.insertGroupConversation(moc: directory.viewContext, participants: [])
        directory.viewContext.saveOrRollback()

        // when
        _ = try await createBackup(accountIdentifier: uuid)

        // then
        let fetchConversations = ZMConversation.sortedFetchRequest()
        XCTAssertEqual(try directory.viewContext.count(for: fetchConversations), 1)
    }

    @MainActor
    func testThatItPreservesOriginaDataAfterBackupIfStackIsNotActive() async throws {
        // given
        let uuid = UUID()
        let directory = try await createStorageStackAndWaitForCompletion(userID: uuid)
        _ = ZMConversation.insertGroupConversation(moc: directory.viewContext, participants: [])
        directory.viewContext.saveOrRollback()

        // when
        _ = try await createBackup(accountIdentifier: uuid)

        // then
        let anotherDirectory = try await createStorageStackAndWaitForCompletion(userID: uuid)
        let fetchConversations = ZMConversation.sortedFetchRequest()
        XCTAssertEqual(try anotherDirectory.viewContext.count(for: fetchConversations), 1)
    }

    // MARK: - Import

    @MainActor
    func testThatItCanOpenAnImportedBackup() async throws {
        // given
        let uuid = UUID()
        let backup = try await createBackupAndDeleteOriginalAccount(accountIdentifier: uuid)

        // when
        _ = try await importBackup(
            accountIdentifier: uuid,
            backup: backup,
            migrator: migrator
        )

        // then
        let directory = try await createStorageStackAndWaitForCompletion(userID: uuid)
        let fetchConversations = ZMConversation.sortedFetchRequest()
        XCTAssertEqual(try directory.viewContext.count(for: fetchConversations), 1)
    }

    @MainActor
    func testThatMetadataIsDeletedWhenImportingBackup() async throws {
        // given
        let uuid = UUID()
        let directory = try await createStorageStackAndWaitForCompletion(userID: uuid)

        // Set metadata on DB which we expect to be cleared when importing from a backup
        directory.viewContext.setPersistentStoreMetadata("1234567890", key: ZMPersistedClientIdKey)
        directory.viewContext.setPersistentStoreMetadata(
            "1234567890",
            key: PersistentMetadataKey.lastUpdateEventID.rawValue
        )
        directory.viewContext.forceSaveOrRollback()

        let backup = try await createBackup(accountIdentifier: uuid)

        // Delete account
        clearStorageFolder()

        // when
        _ = try await importBackup(
            accountIdentifier: uuid,
            backup: backup,
            migrator: migrator
        )

        let importedDirectory = try await createStorageStackAndWaitForCompletion(userID: uuid)

        // then
        XCTAssertNil(importedDirectory.viewContext.persistentStoreMetadata(forKey: ZMPersistedClientIdKey))
        XCTAssertNil(
            importedDirectory.viewContext
                .persistentStoreMetadata(forKey: PersistentMetadataKey.lastUpdateEventID.rawValue)
        )
    }

    func testThatItFailsWhenImportingBackupIntoWrongAccount() async throws {
        // given
        let uuid = UUID()
        let backup = try await createBackupAndDeleteOriginalAccount(accountIdentifier: uuid)
        let differentUUID = UUID()

        // Then
        await XCTAssertThrowsErrorAsync {
            // when
            try await importBackup(
                accountIdentifier: differentUUID,
                backup: backup,
                migrator: migrator
            )
        } errorHandler: { error in
            switch error as? CoreDataStack.BackupImportError {
            case .incompatibleBackup?: break
            default: XCTFail("unexpected error: \(error)")
            }
        }
    }

    func testThatItFailsWhenImportingNonExistantBackup() async throws {
        // given
        let uuid = UUID()
        let backup = DatabaseBaseTest.applicationContainer.appendingPathComponent("non-existing-backup")

        // Then
        await XCTAssertThrowsErrorAsync {
            try await importBackup(
                accountIdentifier: uuid,
                backup: backup,
                migrator: migrator
            )
        } errorHandler: { error in
            switch error as? CoreDataStack.BackupImportError {
            case .failedToCopy?: break
            default: XCTFail("unexpected error: \(error)")
            }
        }
    }

    @MainActor
    func testThatItCallsMigratorDuringImport() async throws {
        // given
        let accountIdentifier = UUID()
        let backup = try await createBackupAndDeleteOriginalAccount(accountIdentifier: accountIdentifier)

        // when
        _ = try await importBackup(
            accountIdentifier: accountIdentifier,
            backup: backup,
            migrator: migrator
        )

        // then
        let directory = try await createStorageStackAndWaitForCompletion(userID: accountIdentifier)
        let fetchConversations = ZMConversation.sortedFetchRequest()
        XCTAssertEqual(try directory.viewContext.count(for: fetchConversations), 1)

        XCTAssertEqual(migrator.migrateStoreAtToVersion_Invocations.count, 1)
    }
}
