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

import LocalAuthentication
import XCTest

@testable import WireDataModel
@testable import WireDataModelSupport

@MainActor
final class EARServiceTests: EARServiceTestsBase, @MainActor EARServiceDelegate {

    var sut: EARService!
    var earStorage: EARStorage!
    var earMessageEncryptionService: MockEARMessageEncryptionServiceProtocol!
    var earMigrator: MockEARMigratorProtocol!
    var prepareForMigrationCalls = 0

    // MARK: - Life cycle

    override func setUp() async throws {
        try await super.setUp()

        earMessageEncryptionService = MockEARMessageEncryptionServiceProtocol()
        earMigrator = MockEARMigratorProtocol()

        earStorage = .init(userID: userID, sharedUserDefaults: .temporary())
        earStorage.enableEAR(true)

        // Setup default mock behaviors
        setMockEncryptionService()
        setMockMigrator()

        sut = await createSUT()
        prepareForMigrationCalls = 0
    }

    override func tearDown() async throws {
        sut = nil
        earStorage = nil
        earMigrator = nil
        earMessageEncryptionService = nil
        try await super.tearDown()
    }

    func createSUT(
        canPerformMigration: Bool = false
    ) async -> EARService {
        let sut = await EARService(
            accountID: userID,
            keyRepository: keyRepository,
            keyEncryptor: keyEncryptor,
            databaseContexts: [uiMOC, syncMOC],
            coreDataStack: coreDataStack,
            canPerformKeyMigration: canPerformMigration,
            earStorage: earStorage,
            messageEncryptionService: earMessageEncryptionService,
            migrator: earMigrator,
            authenticationContext: MockAuthenticationContextProtocol()
        )

        sut.delegate = self
        return sut
    }

    // MARK: - Delegate

    func prepareForMigration(onReady: @escaping (NSManagedObjectContext) throws -> Void) rethrows {
        prepareForMigrationCalls += 1
        try onReady(uiMOC)
    }

    // MARK: - Mock helpers

    // MARK: - Test-specific Errors

    enum MockError: Error {
        case cannotStoreKey
    }

    // MARK: - Mock Setup (Specific to Unit Tests)

    /// Sets up mock encryption service behaviors
    func setMockEncryptionService() {
        earMessageEncryptionService.setDatabaseKey_MockMethod = { _ in }
        earMessageEncryptionService.getDatabaseKey_MockValue = nil
    }

    /// Sets up mock migrator behaviors
    func setMockMigrator() {
        earMigrator.migrateTowardEncryptionAtRestContext_MockMethod = { _ in }
        earMigrator.migrateAwayFromEncryptionAtRestContext_MockMethod = { _ in }
    }

    // MARK: - Overridden Helper (adds earStorage behavior)

    /// Overrides base class to also update earStorage
    override func setEAREnabled(_ enabled: Bool) async {
        earStorage.enableEAR(enabled)
        await super.setEAREnabled(enabled)
    }

    // MARK: - Migration

    func test_ItDoesNotMigrateKeys_IfEARIsDisabled() async throws {
        // Given
        await setEAREnabled(false)

        // When
        sut = await createSUT(canPerformMigration: true)

        // Then
        XCTAssertTrue(keyRepository.storePublicKeyDescriptionKey_Invocations.isEmpty)
    }

    func test_ItDoesNotMigrateKeys_IfSecondaryKeysAlreadyExist() async throws {
        // Given
        await setEAREnabled(true)
        let existingSecondaryKeys = try generateSecondaryKeyPair()
        keyRepository.fetchPublicKeyDescription_MockValue = existingSecondaryKeys.publicKey

        // When
        sut = await createSUT(canPerformMigration: true)
        
        // Then
        XCTAssertTrue(keyRepository.storePublicKeyDescriptionKey_Invocations.isEmpty)
    }

    func test_ItDoesMigrateKeys_IfEARIsEnabledAndSecondaryKeysDontExist() async throws {
        // Given
        await setEAREnabled(true)
        keyRepository.fetchPublicKeyDescription_MockError = EARKeyRepositoryFailure.keyNotFound
        keyRepository.storePublicKeyDescriptionKey_MockMethod = { _, _ in }

        // When
        sut = await createSUT(canPerformMigration: true)
        
        // Then we stored a new public key
        XCTAssertEqual(keyRepository.storePublicKeyDescriptionKey_Invocations.count, 1)
    }

    // MARK: - Enable EAR

    func test_EnableEncryptionAtRest_DontEnableIfNotNeeded() async throws {
        // Given
        await setEAREnabled(true)

        // When
        XCTAssertNoThrow(try sut.enableEncryptionAtRest(context: uiMOC))

        // Then
        XCTAssertEqual(prepareForMigrationCalls, 0)
    }

    func test_EnableEncryptionAtRest_SkipMigration() async throws {
        // Given
        await setEAREnabled(false)

        // Mock
        mockKeyGeneration()

        // When
        XCTAssertNoThrow(try sut.enableEncryptionAtRest(
            context: uiMOC,
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

        // Then we force refetch database key
        XCTAssertEqual(keyRepository.fetchPrivateKeyDescription_Invocations.count, 1)
        XCTAssertEqual(keyEncryptor.decryptDatabaseKeyPrivateKey_Invocations.count, 1)

        // Then migration was not run
        XCTAssertEqual(prepareForMigrationCalls, 0)

        // Then EAR is enabled on the context
        XCTAssertTrue(uiMOC.encryptMessagesAtRest)

        // Then database key was set via the encryption service
        XCTAssertEqual(earMessageEncryptionService.setDatabaseKey_Invocations.count, 1)
        XCTAssertNotNil(earMessageEncryptionService.setDatabaseKey_Invocations.first as? VolatileData)
    }

    func test_EnableEncryptionAtRest_RollbackOnFailure() async throws {
        // Given
        await setEAREnabled(false)

        // Mock
        mockKeyGeneration()
        keyRepository.storeDatabaseKeyDescriptionKey_MockError = MockError.cannotStoreKey

        // When
        XCTAssertThrowsError(try sut.enableEncryptionAtRest(context: uiMOC, skipMigration: true)) { error in
            guard case MockError.cannotStoreKey = error else {
                return XCTFail("unexpected error: \(error)")
            }
        }

        // Then EAR is not enabled (rollback occurred)
        XCTAssertFalse(uiMOC.encryptMessagesAtRest)

        // Then database key was cleared during rollback
        XCTAssertTrue(earMessageEncryptionService.setDatabaseKey_Invocations.contains(where: { $0 == nil }))

        // Then keys were deleted during cleanup
        // In total, the 5 keys (2 public, 2 private, 1 database) were
        // deleted 2 times. Once before generating new keys, and once
        // after cleaning up the error.
        XCTAssertEqual(keyRepository.deletePublicKeyDescription_Invocations.count, 4)
        XCTAssertEqual(keyRepository.deletePrivateKeyDescription_Invocations.count, 4)
        XCTAssertEqual(keyRepository.deleteDatabaseKeyDescription_Invocations.count, 2)
    }

    func test_EnableEncryptionAtRest_FailedToMigrate() async throws {
        // Given
        await setEAREnabled(false)
        sut.delegate = nil

        // Mock
        mockKeyGeneration()

        // When
        XCTAssertThrowsError(try sut.enableEncryptionAtRest(context: uiMOC)) { error in
            guard case EARServiceFailure.cannotPerformMigration = error else {
                return XCTFail("unexpected error: \(error)")
            }
        }
    }

    // MARK: - Disable EAR

    func test_DisableEncryptionAtRest_DontDisableIfNotNeeded() async throws {
        // Given
        await setEAREnabled(false)

        // When
        XCTAssertNoThrow(try sut.disableEncryptionAtRest(context: uiMOC))

        // Then
        XCTAssertEqual(prepareForMigrationCalls, 0)
        XCTAssertTrue(keyRepository.deletePublicKeyDescription_Invocations.isEmpty)
    }

    func test_DisableEncryptionAtRest_SkipMigration() async throws {
        // Given
        await setEAREnabled(true)
        earMessageEncryptionService.getDatabaseKey_MockValue = validDatabaseKey
    
        // Mock
        mockKeyDeletion()

        // When
        XCTAssertNoThrow(try sut.disableEncryptionAtRest(
            context: uiMOC,
            skipMigration: true
        ))

        // Then deleted existing keys
        XCTAssertEqual(keyRepository.deletePublicKeyDescription_Invocations.count, 2)
        XCTAssertEqual(keyRepository.deletePrivateKeyDescription_Invocations.count, 2)
        XCTAssertEqual(keyRepository.deleteDatabaseKeyDescription_Invocations.count, 1)

        // Then migration was not run
        XCTAssertEqual(prepareForMigrationCalls, 0)

        // Then EAR is disabled on the context and storage
        XCTAssertFalse(uiMOC.encryptMessagesAtRest)
        XCTAssertFalse(earStorage.earEnabled())
        
        // Then database key was cleared via the encryption service
        XCTAssertEqual(earMessageEncryptionService.setDatabaseKey_Invocations.count, 1)
        XCTAssertEqual(earMessageEncryptionService.setDatabaseKey_Invocations.first, .some(nil))
    }

    // MARK: - Lock database

    func test_LockDatabase() throws {
        // Given
        // Mock
        keyRepository.clearCache_MockMethod = {}

        // When
        sut.lockDatabase()

        // Then database key was cleared via the encryption service
        XCTAssertTrue(earMessageEncryptionService.setDatabaseKey_Invocations.contains(where: { $0 == nil }))

        // Then key repository cache was cleared
        XCTAssertEqual(keyRepository.clearCache_Invocations.count, 1)
    }

    // MARK: - Unlock database

    func test_UnlockDatabase() throws {
        // Given
        let keys = try generatePrimaryKeyPair()
        let encryptedDatabaseKey = Data.randomEncryptionKey()
        let decryptedDatabaseKey = Data.randomEncryptionKey()

        // Mock
        keyRepository.fetchPrivateKeyDescription_MockValue = keys.privateKey
        keyRepository.fetchDatabaseKeyDescription_MockValue = encryptedDatabaseKey
        keyEncryptor.decryptDatabaseKeyPrivateKey_MockValue = decryptedDatabaseKey

        // When
        XCTAssertNoThrow(try sut.unlockDatabase())

        // Then database key was set via the encryption service
        XCTAssertEqual(earMessageEncryptionService.setDatabaseKey_Invocations.count, 1)
        let key = try XCTUnwrap(earMessageEncryptionService.setDatabaseKey_Invocations.first)
        XCTAssertEqual(key?._storage, decryptedDatabaseKey)
    }

    // MARK: - Fetch public keys

    func test_FetchPublicKeys() async throws {
        // Given
        await setEAREnabled(true)
        let primaryKeys = try generatePrimaryKeyPair()
        let secondaryKeys = try generateSecondaryKeyPair()

        // Mock
        mockFetchingPublicKeys(
            primary: primaryKeys.publicKey,
            secondary: secondaryKeys.publicKey
        )

        // When
        let publicKeys = try XCTUnwrap(sut.fetchPublicKeys())

        // Then
        XCTAssertEqual(publicKeys.primary, primaryKeys.publicKey)
        XCTAssertEqual(publicKeys.secondary, secondaryKeys.publicKey)
    }

    func test_FetchPublicKeys_EARDisabled() async throws {
        // Given
        await setEAREnabled(false)

        // When
        let publicKeys = try sut.fetchPublicKeys()

        // Then
        XCTAssertNil(publicKeys)
    }

    func test_FetchPublicKeys_KeyNotFound() async throws {
        // Given
        await setEAREnabled(true)
        let primaryKeys = try generatePrimaryKeyPair()

        // Mock
        mockFetchingPublicKeys(
            primary: primaryKeys.publicKey,
            secondary: nil
        )

        // When then
        XCTAssertThrowsError(try sut.fetchPublicKeys()) { error in
            guard case EARKeyRepositoryFailure.keyNotFound = error else {
                return XCTFail("unexpected error")
            }
        }
    }

    private func mockFetchingPublicKeys(primary: SecKey?, secondary: SecKey?) {
        keyRepository.fetchPublicKeyDescription_MockMethod = { description in
            switch (description.label, primary, secondary) {
            case let ("public", primary?, _):
                return primary

            case let ("secondary-public", _, secondary?):
                return secondary

            default:
                throw EARKeyRepositoryFailure.keyNotFound
            }
        }
    }

    // MARK: - Fetch private keys

    func test_FetchPrivateKeys() async throws {
        // Given
        await setEAREnabled(true)
        let primaryKeys = try generatePrimaryKeyPair()
        let secondaryKeys = try generateSecondaryKeyPair()

        // Mock
        mockFetchingPrivateKeys(
            primary: primaryKeys.privateKey,
            secondary: secondaryKeys.privateKey
        )

        // When
        let privateKeys = try XCTUnwrap(sut.fetchPrivateKeys(includingPrimary: true))

        // Then
        XCTAssertEqual(privateKeys.primary, primaryKeys.privateKey)
        XCTAssertEqual(privateKeys.secondary, secondaryKeys.privateKey)
    }

    func test_FetchPrivateKeys_EARDisabled() async throws {
        // Given
        await setEAREnabled(false)

        // When
        let privateKeys = try sut.fetchPrivateKeys(includingPrimary: true)

        // Then
        XCTAssertNil(privateKeys)
    }

    func test_FetchPrivateKeys_ExcludingPrimary() async throws {
        // Given
        await setEAREnabled(true)
        let primaryKeys = try generatePrimaryKeyPair()
        let secondaryKeys = try generateSecondaryKeyPair()

        // Mock
        mockFetchingPrivateKeys(
            primary: primaryKeys.privateKey,
            secondary: secondaryKeys.privateKey
        )

        // When
        let privateKeys = try XCTUnwrap(sut.fetchPrivateKeys(includingPrimary: false))

        // Then
        XCTAssertNil(privateKeys.primary)
        XCTAssertEqual(privateKeys.secondary, secondaryKeys.privateKey)
    }

    func test_FetchPrivateKeys_PrimaryKeyNotFound() async throws {
        // Given
        await setEAREnabled(true)
        let secondaryKeys = try generateSecondaryKeyPair()

        // Mock
        mockFetchingPrivateKeys(
            primary: nil,
            secondary: secondaryKeys.privateKey
        )

        // When
        let privateKeys = try XCTUnwrap(sut.fetchPrivateKeys(includingPrimary: true))

        // Then
        XCTAssertNil(privateKeys.primary)
        XCTAssertEqual(privateKeys.secondary, secondaryKeys.privateKey)
    }

    func test_FetchPrivateKeys_SecondaryKeyNotFound() async throws {
        // Given
        await setEAREnabled(true)

        // Mock
        mockFetchingPrivateKeys(
            primary: nil,
            secondary: nil
        )

        // When then
        XCTAssertThrowsError(try sut.fetchPrivateKeys(includingPrimary: true)) { error in
            guard case EARKeyRepositoryFailure.keyNotFound = error else {
                return XCTFail("unexpected error")
            }
        }
    }

    private func mockFetchingPrivateKeys(primary: SecKey?, secondary: SecKey?) {
        keyRepository.fetchPrivateKeyDescription_MockMethod = { description in
            switch (description.label, primary, secondary) {
            case let ("private", primary?, _):
                return primary

            case let ("secondary-private", _, secondary?):
                return secondary

            default:
                throw EARKeyRepositoryFailure.keyNotFound
            }
        }
    }

    // MARK: - Security tests

    // @SF.Storage @TSFI.ClientRNG @S0.1 @S0.2
    func test_EncryptionKeysAreSuccessfullyCreated() throws {
        // Mock
        mockKeyGeneration()

        // When
        let databaseKey = try sut.generateKeys()

        // Then
        XCTAssertEqual(databaseKey._storage.count, 32)
    }

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func test_EncryptionKeysAreSuccessfullyDeleted() throws {
        // Mock
        mockKeyGeneration()
        _ = try sut.generateKeys()

        keyRepository.deletePublicKeyDescription_Invocations.removeAll()
        keyRepository.deletePrivateKeyDescription_Invocations.removeAll()
        keyRepository.deleteDatabaseKeyDescription_Invocations.removeAll()

        // When
        try XCTAssertNoThrow(sut.deleteExistingKeys())

        // Then
        XCTAssertEqual(keyRepository.deletePublicKeyDescription_Invocations.count, 2)
        XCTAssertEqual(keyRepository.deletePrivateKeyDescription_Invocations.count, 2)
        XCTAssertEqual(keyRepository.deleteDatabaseKeyDescription_Invocations.count, 1)
    }

    // @SF.Storage @TSFI.ClientRNG @S0.1 @S0.2
    func test_AsymmetricKeysWorksWithExpectedAlgorithm() throws {
        // Given
        let keyGen = EARKeyGenerator()
        let keys = try keyGen.generatePrimaryPublicPrivateKeyPair(id: "EARServiceTests")
        let data = Data("Hello world".utf8)

        // When
        guard let encryptedData = SecKeyCreateEncryptedData(
            keys.publicKey,
            .eciesEncryptionCofactorX963SHA256AESGCM,
            data as CFData,
            nil
        ) else {
            return XCTFail("failed to encrypt data")
        }

        guard let decryptedData = SecKeyCreateDecryptedData(
            keys.privateKey,
            .eciesEncryptionCofactorX963SHA256AESGCM,
            encryptedData,
            nil
        ) else {
            return XCTFail("failed to decrypt data")
        }

        // Then
        XCTAssertEqual(decryptedData as Data, data)
    }

    func test_setInitialEARFlagValue_ChangesEARStorageValue() {
        // when
        let currentValue = earStorage.earEnabled()
        sut.setInitialEARFlagValue(!currentValue)
        // THEN
        XCTAssertEqual(earStorage.earEnabled(), !currentValue)
    }
}
