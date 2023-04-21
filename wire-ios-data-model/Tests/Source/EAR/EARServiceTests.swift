//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import LocalAuthentication
@testable import WireDataModel

final class EARServiceTests: DatabaseBaseTest, EARServiceDelegate {

    var sut: EARService!
    var keyRepository: MockEARKeyRepositoryInterface!
    var keyEncryptor: MockEARKeyEncryptorInterface!
    var viewContext: NSManagedObjectContext!
    var syncContext: NSManagedObjectContext!

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()

        let coreDataStack = createStorageStackAndWaitForCompletion(userID: accountID)

        viewContext = coreDataStack.viewContext
        syncContext = coreDataStack.syncContext
        keyRepository = MockEARKeyRepositoryInterface()
        keyEncryptor = MockEARKeyEncryptorInterface()

        sut = EARService(
            accountID: accountID,
            keyRepository: keyRepository,
            keyEncryptor: keyEncryptor,
            databaseContexts: [viewContext, syncContext]
        )

        sut.delegate = self
        prepareForMigrationCalls = 0
    }

    override func tearDown() {
        sut = nil
        keyRepository = nil
        keyEncryptor = nil
        viewContext = nil
        syncContext = nil
        super.tearDown()
    }

    // MARK: - Delegate

    var prepareForMigrationCalls = 0

    func prepareForMigration(onReady: @escaping (NSManagedObjectContext) throws -> Void) {
        prepareForMigrationCalls += 1
        try? onReady(viewContext)
    }

    // MARK: - Mock helpers

    func generateKeyPair(id: String) throws -> (publicKey: SecKey, privateKey: SecKey) {
        let keyGenerator = EARKeyGenerator()
        return try keyGenerator.generatePublicPrivateKeyPair(id: id)
    }

    func mockKeyGeneration() {
        mockKeyDeletion()
        keyEncryptor.encryptDatabaseKeyPublicKey_MockValue = .randomEncryptionKey()
        mockKeyStorage()
    }

    func mockKeyDeletion() {
        keyRepository.deletePublicKeyDescription_MockMethod = { _ in }
        keyRepository.deletePrivateKeyDescription_MockMethod = { _ in }
        keyRepository.deleteDatabaseKeyDescription_MockMethod = { _ in }
    }

    func mockKeyStorage() {
        keyRepository.storePublicKeyDescriptionKey_MockMethod = { _, _ in }
        keyRepository.storeDatabaseKeyDescriptionKey_MockMethod = { _, _ in }
    }

    // MARK: - Enable EAR

    func test_EnableEncryptionAtRest_DontEnableIfNotNeeded() throws {
        // Given
        viewContext.encryptMessagesAtRest = true

        // When
        XCTAssertNoThrow(try sut.enableEncryptionAtRest(context: viewContext))

        // Then
        XCTAssertEqual(prepareForMigrationCalls, 0)
    }

    func test_EnableEncryptionAtRest() throws {
        // Given
        viewContext.encryptMessagesAtRest = false
        viewContext.databaseKey = nil

        syncContext.performAndWait {
            syncContext.encryptMessagesAtRest = false
            syncContext.databaseKey = nil
        }

        // Mock
        mockKeyGeneration()

        // When
        XCTAssertNoThrow(try sut.enableEncryptionAtRest(
            context: viewContext,
            skipMigration: true
        ))

        // Then deleted existing keys
        XCTAssertEqual(keyRepository.deletePublicKeyDescription_Invocations.count, 2)
        XCTAssertEqual(keyRepository.deletePrivateKeyDescription_Invocations.count, 2)
        XCTAssertEqual(keyRepository.deleteDatabaseKeyDescription_Invocations.count, 1)

        // Then database key was encrypted
        XCTAssertEqual(keyEncryptor.encryptDatabaseKeyPublicKey_Invocations.count, 1)

        // Then new keys are stored
        XCTAssertEqual(keyRepository.storePublicKeyDescriptionKey_Invocations.count, 2)
        XCTAssertEqual(keyRepository.storeDatabaseKeyDescriptionKey_Invocations.count, 1)

        // Then migration was not run
        XCTAssertEqual(prepareForMigrationCalls, 0)

        // Then EAR is enabled on the context
        XCTAssertTrue(viewContext.encryptMessagesAtRest)

        // Then all contexts have the database key.
        XCTAssertNotNil(viewContext.databaseKey)
        syncContext.performAndWait { XCTAssertNotNil(syncContext.databaseKey) }
    }

    func test_EnableEncryptionAtRest_FailedToMigrate() throws {
        // Given
        viewContext.encryptMessagesAtRest = false
        sut.delegate = nil

        // Mock
        mockKeyGeneration()

        // When
        XCTAssertThrowsError(try sut.enableEncryptionAtRest(context: viewContext)) { error in
            guard case EARServiceFailure.cannotPerformMigration = error else {
                return XCTFail("unexpected error: \(error)")
            }
        }
    }

    // MARK: - Disable EAR

    func test_DisableEncryptionAtRest_DontDisableIfNotNeeded() throws {
        // Given
        viewContext.encryptMessagesAtRest = false

        // When
        XCTAssertNoThrow(try sut.disableEncryptionAtRest(context: viewContext))

        // Then
        XCTAssertEqual(prepareForMigrationCalls, 0)
    }

    func test_DisableEncryptionAtRest_DatabaseKeyMissing() throws {
        // Given
        viewContext.encryptMessagesAtRest = true
        viewContext.databaseKey = nil

        // When
        XCTAssertThrowsError(try sut.disableEncryptionAtRest(context: viewContext)) { error in
            guard case EARServiceFailure.databaseKeyMissing = error else {
                return XCTFail("unexpected error: \(error)")
            }
        }
    }

    func test_DisableEncryptionAtRest() throws {
        // Given
        let databaseKey = VolatileData(from: .randomEncryptionKey())
        viewContext.encryptMessagesAtRest = true
        viewContext.databaseKey = databaseKey

        syncContext.performAndWait {
            syncContext.encryptMessagesAtRest = true
            syncContext.databaseKey = databaseKey
        }

        // Mock
        mockKeyDeletion()

        // When
        XCTAssertNoThrow(try sut.disableEncryptionAtRest(
            context: viewContext,
            skipMigration: true
        ))

        // Then deleted existing keys
        XCTAssertEqual(keyRepository.deletePublicKeyDescription_Invocations.count, 2)
        XCTAssertEqual(keyRepository.deletePrivateKeyDescription_Invocations.count, 2)
        XCTAssertEqual(keyRepository.deleteDatabaseKeyDescription_Invocations.count, 1)

        // Then migration was not run
        XCTAssertEqual(prepareForMigrationCalls, 0)

        // Then EAR is disabled on the context
        XCTAssertFalse(viewContext.encryptMessagesAtRest)

        // Then all contexts no longer have the database key
        XCTAssertNil(viewContext.databaseKey)
        syncContext.performAndWait { XCTAssertNil(syncContext.databaseKey) }
    }

    // MARK: - Lock database

    func test_LockDatabase() throws {
        // Given
        let databaseKey = VolatileData(from: .randomEncryptionKey())

        viewContext.databaseKey = databaseKey

        syncContext.performAndWait {
            syncContext.databaseKey = databaseKey
        }

        // When
        sut.lockDatabase()

        // Then
        XCTAssertNil(viewContext.databaseKey)

        syncContext.performAndWait {
            XCTAssertNil(syncContext.databaseKey)
        }
    }

    // MARK: - Unlock database

    func test_UnlockDatabase() throws {
        // Given
        let keys = try generateKeyPair(id: "test")
        let encryptedDatabaseKey = Data.randomEncryptionKey()
        let decryptedDatabaseKey = Data.randomEncryptionKey()
        let context = LAContext()

        // Mock
        keyRepository.fetchPrivateKeyDescription_MockValue = keys.privateKey
        keyRepository.fetchDatabaseKeyDescription_MockValue = encryptedDatabaseKey
        keyEncryptor.decryptDatabaseKeyPrivateKey_MockValue = decryptedDatabaseKey

        // When
        XCTAssertNoThrow(try sut.unlockDatabase(context: context))

        // Then
        XCTAssertEqual(viewContext.databaseKey?._storage, decryptedDatabaseKey)

        syncContext.performAndWait {
            XCTAssertEqual(syncContext.databaseKey?._storage, decryptedDatabaseKey)
        }
    }

    // MARK: - Fetch public keys

    func test_FetchPublicKeys() throws {
        // Given
        let primaryKeys = try generateKeyPair(id: "primary")
        let secondaryKeys = try generateKeyPair(id: "secondary")

        // Mock
        mockFetchingPublicKeys(
            primary: primaryKeys.publicKey,
            secondary: secondaryKeys.publicKey
        )

        // When
        let publicKeys = try sut.fetchPublicKeys()

        // Then
        XCTAssertEqual(publicKeys.primary, primaryKeys.publicKey)
        XCTAssertEqual(publicKeys.secondary, secondaryKeys.publicKey)
    }

    func test_FetchPublicKeys_KeyNotFound() throws {
        // Given
        let primaryKeys = try generateKeyPair(id: "primary")

        // Mock
        mockFetchingPublicKeys(
            primary: primaryKeys.publicKey,
            secondary: nil
        )

        // When then
        XCTAssertThrowsError(try sut.fetchPublicKeys()) { error in
            guard case EarKeyRepositoryFailure.keyNotFound = error else {
                return XCTFail("unexpected error")
            }
        }
    }

    private func mockFetchingPublicKeys(primary: SecKey?, secondary: SecKey?) {
        keyRepository.fetchPublicKeyDescription_MockMethod = { description in
            switch (description.label, primary, secondary) {
            case ("primary-public", let primary?, _):
                return primary

            case ("secondary-public", _, let secondary?):
                return secondary

            default:
                throw EarKeyRepositoryFailure.keyNotFound
            }
        }
    }

    // MARK: - Fetch private keys

    func test_FetchPrivateKeys() throws {
        // Given
        let primaryKeys = try generateKeyPair(id: "primary")
        let secondaryKeys = try generateKeyPair(id: "secondary")

        // Mock
        mockFetchingPrivateKeys(
            primary: primaryKeys.privateKey,
            secondary: secondaryKeys.privateKey
        )

        // When
        let privateKeys = try sut.fetchPrivateKeys()

        // Then
        XCTAssertEqual(privateKeys.primary, primaryKeys.privateKey)
        XCTAssertEqual(privateKeys.secondary, secondaryKeys.privateKey)
    }

    func test_FetchPrivateKeys_PrimaryKeyNotFound() throws {
        // Given
        let secondaryKeys = try generateKeyPair(id: "secondary")

        // Mock
        mockFetchingPrivateKeys(
            primary: nil,
            secondary: secondaryKeys.privateKey
        )

        // When
        let privateKeys = try sut.fetchPrivateKeys()

        // Then
        XCTAssertNil(privateKeys.primary)
        XCTAssertEqual(privateKeys.secondary, secondaryKeys.privateKey)
    }

    func test_FetchPrivateKeys_SecondaryKeyNotFound() throws {
        // Mock
        mockFetchingPrivateKeys(
            primary: nil,
            secondary: nil
        )

        // When then
        XCTAssertThrowsError(try sut.fetchPrivateKeys()) { error in
            guard case EarKeyRepositoryFailure.keyNotFound = error else {
                return XCTFail("unexpected error")
            }
        }
    }

    private func mockFetchingPrivateKeys(primary: SecKey?, secondary: SecKey?) {
        keyRepository.fetchPrivateKeyDescription_MockMethod = { description in
            switch (description.label, primary, secondary) {
            case ("primary-private", let primary?, _):
                return primary

            case ("secondary-private", _, let secondary?):
                return secondary

            default:
                throw EarKeyRepositoryFailure.keyNotFound
            }
        }
    }

}
