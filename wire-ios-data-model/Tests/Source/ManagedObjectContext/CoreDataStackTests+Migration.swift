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

class CoreDataStackTests_Migration: DatabaseBaseTest {

    enum TestError: Error {
        case somethingWentWrong
    }

    override func tearDown() {
        CoreDataStack.clearMigrationDirectory(dispatchGroup: dispatchGroup)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertFalse(FileManager.default.fileExists(atPath: CoreDataStack.migrationDirectory.path))
        super.tearDown()
    }

    func performMigration(
        accountIdentifier: UUID,
        migration: @escaping (NSManagedObjectContext) throws -> Void
    ) async throws {
        try await CoreDataStack.migrateLocalStorage(
            accountIdentifier: accountIdentifier,
            applicationContainer: DatabaseBaseTest.applicationContainer,
            migration: migration
        )
    }

    // MARK: - Migration tests

    @MainActor
    func testThatLocalStoreMigration_CanAlterTheDatabase() async throws {
        // given
        let metadataValue = 242
        let metadataKey = "hello"
        let uuid = UUID()
        _ = try await createStorageStackAndWaitForCompletion(userID: uuid)

        // when
        try await performMigration(accountIdentifier: uuid) { context in
            context.setPersistentStoreMetadata(metadataValue, key: metadataKey)
        }

        // then
        let directory = try await createStorageStackAndWaitForCompletion(userID: uuid)
        let storedValue = directory.viewContext.persistentStoreMetadata(forKey: metadataKey) as? Int
        XCTAssertEqual(storedValue, metadataValue)
    }

    @MainActor
    func testThatLocalStoreMigration_DoesNotAlterTheDatabase_WhenMigrationFails() async throws {
        // given
        let metadataValue = 242
        let metadataKey = "hello"
        let uuid = UUID()
        _ = try await createStorageStackAndWaitForCompletion(userID: uuid)

        // then
        disableZMLogError(true)
        await XCTAssertThrowsErrorAsync {
            // when
            try await self.performMigration(accountIdentifier: uuid) { context in
                context.setPersistentStoreMetadata(metadataValue, key: metadataKey)
                try context.save()
                throw TestError.somethingWentWrong
            }
        } errorHandler: { error in
            switch error {
            case CoreDataStack.MigrationError.migrationFailed(TestError.somethingWentWrong):
                break
            default:
                XCTFail("unexpected error: \(error)")
            }
        }
        disableZMLogError(false)

        // then
        let directory = try await createStorageStackAndWaitForCompletion(userID: uuid)
        let storedValue = directory.viewContext.persistentStoreMetadata(forKey: metadataKey) as? Int
        XCTAssertNil(storedValue)
    }

    func testThatLocalStoreMigration_FailWhenLocalStoreDoesNotExist() async throws {
        // given
        let uuid = UUID()

        // then
        await XCTAssertThrowsErrorAsync {
            // when
            try await self.performMigration(accountIdentifier: uuid) { _ in }
        } errorHandler: { error in
            switch error {
            case CoreDataStack.MigrationError.missingLocalStore:
                break
            default:
                XCTFail("unexpected error: \(error)")
            }
        }
    }

    func testThatLocalStoreMigration_DeletesTemporaryStore_OnSuccess() async throws {
        // given
        let uuid = UUID()
        _ = try await createStorageStackAndWaitForCompletion(userID: uuid)

        // when
        try await performMigration(accountIdentifier: uuid) { _ in }

        // then
        XCTAssertFalse(FileManager.default.fileExists(atPath: CoreDataStack.migrationDirectory.path))
    }

    func testThatLocalStoreMigration_DeletesTemporaryStore_OnFailure() async throws {
        // given
        let uuid = UUID()
        _ = try await createStorageStackAndWaitForCompletion(userID: uuid)

        // then
        disableZMLogError(true)
        await XCTAssertThrowsErrorAsync {
            // when
            try await self.performMigration(accountIdentifier: uuid) { _ in
                throw TestError.somethingWentWrong
            }
        } errorHandler: { error in
            switch error {
            case CoreDataStack.MigrationError.migrationFailed(TestError.somethingWentWrong):
                break
            default:
                XCTFail("unexpected error: \(error)")
            }
        }
        disableZMLogError(false)

        // then
        XCTAssertFalse(FileManager.default.fileExists(atPath: CoreDataStack.migrationDirectory.path))
    }
}
