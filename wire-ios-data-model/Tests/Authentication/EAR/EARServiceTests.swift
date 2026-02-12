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
final class EARServiceTests: XCTestCase, @MainActor EARServiceDelegate {

    var coreDataStack: CoreDataStack!
    var uiMOC: NSManagedObjectContext!
    var syncMOC: NSManagedObjectContext!
    var sut: EARService!
    var keyRepository: MockEARKeyRepositoryInterface!
    var keyEncryptor: MockEARKeyEncryptorInterface!
    var earStorage: EARStorage!
    var earMessageEncryptionService: MockEARMessageEncryptionServiceProtocol!
    var earMigrator: MockEARMigratorProtocol!
    var userID: UUID!
    var prepareForMigrationCalls = 0

    // MARK: - Life cycle

    override func setUp() async throws {
        try await super.setUp()

        coreDataStack = try await CoreDataStackHelper().createStack()
        uiMOC = coreDataStack.viewContext
        syncMOC = coreDataStack.syncContext
        
        userID = UUID()
        
        keyRepository = MockEARKeyRepositoryInterface()
        keyEncryptor = MockEARKeyEncryptorInterface()
        earMessageEncryptionService = MockEARMessageEncryptionServiceProtocol()
        earMigrator = MockEARMigratorProtocol()

        earStorage = .init(userID: userID, sharedUserDefaults: .temporary())
        earStorage.enableEAR(true)

        // Setup default mock behaviors
        setMockEncryptionService()
        setMockMigrator()

        sut = await createSUT(
            earStorage: earStorage,
            mockMessageEncryptionService: earMessageEncryptionService,
            mockMigrator: earMigrator
        )
        prepareForMigrationCalls = 0
        
        _ = await uiMOC.perform { [uiMOC, userID] in
            let modelHelper = ModelHelper()
            modelHelper.createSelfUser(id: userID!, in: uiMOC!)
            modelHelper.createSelfClient(in: uiMOC!)
        }
    }

    override func tearDown() async throws {
        await setEAREnabled(false)

        userID = nil
        sut = nil
        earStorage = nil
        keyRepository = nil
        keyEncryptor = nil
        earMigrator = nil
        earMessageEncryptionService = nil
        try await super.tearDown()
    }

    func createSUT(
        canPerformMigration: Bool = false,
        earStorage: EARStorage? = nil,
        mockMessageEncryptionService: EARMessageEncryptionServiceProtocol? = nil,
        mockMigrator: EARMigratorProtocol? = nil,
        contexts: [NSManagedObjectContext]? = nil
    ) async -> EARService {
        let earStorage = earStorage ?? EARStorage(userID: userID, sharedUserDefaults: .temporary())
        let messageEncryptionService = mockMessageEncryptionService ?? EARMessageEncryptionService(earStorage: earStorage)
        let migrator = mockMigrator ?? EARMigrator(messageEncryptionService: messageEncryptionService)
        let contexts = contexts ?? [uiMOC, syncMOC]
        
        let sut = await EARService(
            accountID: userID,
            keyRepository: keyRepository,
            keyEncryptor: keyEncryptor,
            databaseContexts: contexts,
            coreDataStack: coreDataStack,
            canPerformKeyMigration: canPerformMigration,
            earStorage: earStorage,
            messageEncryptionService: messageEncryptionService,
            migrator: migrator,
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

    enum MockError: Error {

        case cannotStoreKey

    }

    func generatePrimaryKeyPair() throws -> (publicKey: SecKey, privateKey: SecKey) {
        let keyGenerator = EARKeyGenerator()
        return try keyGenerator.generatePrimaryPublicPrivateKeyPair(id: "primary")
    }

    func generateSecondaryKeyPair() throws -> (publicKey: SecKey, privateKey: SecKey) {
        let keyGenerator = EARKeyGenerator()
        return try keyGenerator.generateSecondaryPublicPrivateKeyPair(id: "secondary")
    }

    func mockKeyGeneration() {
        mockKeyDeletion()
        keyEncryptor.encryptDatabaseKeyPublicKey_MockValue = .randomEncryptionKey()
        mockKeyStorage()
        try? mockKeyFetching()
    }

    func setMockEncryptionService() {
        earMessageEncryptionService.setDatabaseKey_MockMethod = { _ in }
    }

    func setMockMigrator() {
        earMigrator.migrateTowardEncryptionAtRestContext_MockMethod = { _ in }
        earMigrator.migrateAwayFromEncryptionAtRestContext_MockMethod = { _ in }
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

    func mockKeyFetching() throws {
        let primaryKeys = try generatePrimaryKeyPair()
        let secondaryKeys = try generateSecondaryKeyPair()

        keyRepository.fetchPublicKeyDescription_MockMethod = { description in
            switch description.label {
            case "public":
                return primaryKeys.publicKey

            case "secondary-public":
                return secondaryKeys.publicKey

            default:
                throw EARKeyRepositoryFailure.keyNotFound
            }
        }

        keyRepository.fetchPrivateKeyDescription_MockMethod = { description in
            switch description.label {
            case "private":
                return primaryKeys.privateKey

            case "secondary-private":
                return secondaryKeys.privateKey

            default:
                throw EARKeyRepositoryFailure.keyNotFound
            }
        }

        keyRepository.fetchDatabaseKeyDescription_MockValue = .randomEncryptionKey()
        keyEncryptor.decryptDatabaseKeyPrivateKey_MockValue = .randomEncryptionKey()
    }
    
    func setEAREnabled(_ enabled: Bool) async {
        earStorage.enableEAR(enabled)
        await uiMOC.perform { [uiMOC] in
            uiMOC.encryptMessagesAtRest = enabled
        }
    }
    
    @discardableResult
    func createConversation(
        in moc: NSManagedObjectContext,
        with participants: [ZMUser] = [],
        role: Role? = nil
    ) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: moc)
        conversation.remoteIdentifier = UUID()
        return conversation
    }

    // MARK: - Migration

    func test_ItDoesNotMigrateKeys_IfEARIsDisabled() async throws {
        // Given
        await setEAREnabled(false)

        // When
        sut = await createSUT(
            canPerformMigration: true,
            earStorage: earStorage,
            mockMessageEncryptionService: earMessageEncryptionService,
            mockMigrator: earMigrator
        )

        // Then
        XCTAssertTrue(keyRepository.storePublicKeyDescriptionKey_Invocations.isEmpty)
    }

    func test_ItDoesNotMigrateKeys_IfSecondaryKeysAlreadyExist() async throws {
        // Given
        await setEAREnabled(true)
        let existingSecondaryKeys = try generateSecondaryKeyPair()
        keyRepository.fetchPublicKeyDescription_MockValue = existingSecondaryKeys.publicKey

        // When
        sut = await createSUT(
            canPerformMigration: true,
            earStorage: earStorage,
            mockMessageEncryptionService: earMessageEncryptionService,
            mockMigrator: earMigrator
        )
        
        
        // Then
        XCTAssertTrue(keyRepository.storePublicKeyDescriptionKey_Invocations.isEmpty)
    }

    func test_ItDoesMigrateKeys_IfEARIsEnabledAndSecondaryKeysDontExist() async throws {
        // Given
        await setEAREnabled(true)
        keyRepository.fetchPublicKeyDescription_MockError = EARKeyRepositoryFailure.keyNotFound
        keyRepository.storePublicKeyDescriptionKey_MockMethod = { _, _ in }

        // When
        sut = await createSUT(
            canPerformMigration: true,
            earStorage: earStorage,
            mockMessageEncryptionService: earMessageEncryptionService,
            mockMigrator: earMigrator
        )
        
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

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    // Make sure that message content is encrypted when EAR is enabled
    func test_ExistingMessageContentIsEncrypted_WhenEarIsEnabled() async throws {
        // Given
        let sut = await createSUT(contexts: [uiMOC])
        
        // disable encryption at rest
        await setEAREnabled(false)

        // add message to a conversation
        let conversation = createConversation(in: uiMOC)
        try conversation.appendText(content: "Beep bloop")

        let results: [ZMGenericMessageData] = try uiMOC.fetchObjects()

        guard let messageData = results.first else {
            XCTFail("Could not find message data.")
            return
        }

        // Then
        // Message isn't encrypted
        XCTAssertFalse(messageData.isEncrypted)
        XCTAssertEqual(messageData.unencryptedContent, "Beep bloop")
        XCTAssertFalse(uiMOC.encryptMessagesAtRest)

        // Mock
        mockKeyGeneration()

        // When
        // enabling encryption at rest
        XCTAssertNoThrow(try sut.enableEncryptionAtRest(context: uiMOC))

        // Then migration was run
        XCTAssertEqual(prepareForMigrationCalls, 1)
        XCTAssertTrue(messageData.isEncrypted)
        XCTAssertEqual(messageData.unencryptedContent, "Beep bloop")

        // Then EAR is enabled on the context
        XCTAssertTrue(uiMOC.encryptMessagesAtRest)
    }

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    // Make sure that message content normalized for text search is also encrypted when EAR is enabled
    func test_NormalizedMessageContentIsCleared_WhenEarIsEnabled() async throws {
        // Given
        let sut = await createSUT(contexts: [uiMOC])

        // disable encryption at rest
        await setEAREnabled(false)

        // add message to a conversation
        let conversation = createConversation(in: uiMOC)
        let message = try conversation.appendText(content: "Beep bloop") as! ZMMessage

        // Then
        XCTAssertNotNil(message.normalizedText)
        XCTAssertEqual(message.normalizedText?.isEmpty, false)

        // Mock
        mockKeyGeneration()

        // When
        XCTAssertNoThrow(try sut.enableEncryptionAtRest(context: uiMOC))

        // Then
        XCTAssertNotNil(message.normalizedText)
        XCTAssertEqual(message.normalizedText?.isEmpty, true)
        XCTAssertTrue(uiMOC.encryptMessagesAtRest)
    }

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    // Make sure that message content that is drafted but not send by the user yet is also encrypted
    // when EAR is enabled
    func test_DraftMessageContentIsEncrypted_WhenEarIsEnabled() async throws {
        // Given
        let sut = await createSUT(contexts: [uiMOC])
        
        // disable encryption at rest
        await setEAREnabled(false)

        // add message to a conversation
        let conversation = createConversation(in: uiMOC)
        conversation.draftMessage = DraftMessage(
            text: "Beep bloop",
            mentions: [],
            quote: nil
        )

        // Then
        XCTAssertTrue(conversation.hasDraftMessage)
        XCTAssertFalse(conversation.hasEncryptedDraftMessageData)
        XCTAssertEqual(conversation.unencryptedDraftMessageContent, "Beep bloop")

        // Mock
        mockKeyGeneration()

        // When
        XCTAssertNoThrow(try sut.enableEncryptionAtRest(context: uiMOC))

        // Then
        XCTAssertTrue(conversation.hasEncryptedDraftMessageData)
        XCTAssertEqual(conversation.unencryptedDraftMessageContent, "Beep bloop")
        XCTAssertTrue(uiMOC.encryptMessagesAtRest)
    }

    // MARK: - Disable EAR

    func test_DisableEncryptionAtRest_DontDisableIfNotNeeded() async throws {
        // Given
        await setEAREnabled(false)

        // When
        XCTAssertNoThrow(try sut.disableEncryptionAtRest(context: uiMOC))

        // Then
        XCTAssertEqual(prepareForMigrationCalls, 0)
    }

    func test_DisableEncryptionAtRest_SkipMigration() async throws {
        // Given
        await setEAREnabled(true)

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

    // TODO: Move these tests to the EARMigrator, OR, don't use mocks and test the integration
    /*
    func test_ExistingMessageContentIsDecrypted_WhenEarIsDisabled() throws {
        // Given
        let databaseKey = VolatileData(from: .randomEncryptionKey())
        setEAREnabled(true)

        let conversation = createConversation(in: uiMOC)
        try conversation.appendText(content: "Beep bloop")

        // Mock
        mockKeyDeletion()

        // When
        XCTAssertNoThrow(try sut.disableEncryptionAtRest(context: uiMOC))

        // Then migration delegate was called
        XCTAssertEqual(prepareForMigrationCalls, 1)

        // Then migrator was called to decrypt existing content
        XCTAssertEqual(earMigrator.migrateAwayFromEncryptionAtRestContext_Invocations.count, 1)
        XCTAssertEqual(earMigrator.migrateAwayFromEncryptionAtRestContext_Invocations.first, uiMOC)

        // Then EAR is disabled on the context and storage
        XCTAssertFalse(uiMOC.encryptMessagesAtRest)
        XCTAssertFalse(earStorage.earEnabled())
    }

    func test_NormalizedMessageContentIsUpdated_WhenEarIsDisabled() throws {
        // Given
        let databaseKey = VolatileData(from: .randomEncryptionKey())
        setEAREnabled(true)

        let conversation = createConversation(in: uiMOC)
        let message = try conversation.appendText(content: "Beep bloop") as! ZMMessage

        // Mock
        mockKeyDeletion()

        // When
        XCTAssertNoThrow(try sut.disableEncryptionAtRest(context: uiMOC))

        // Then migrator was called to handle normalized text
        XCTAssertEqual(earMigrator.migrateAwayFromEncryptionAtRestContext_Invocations.count, 1)
        XCTAssertEqual(earMigrator.migrateAwayFromEncryptionAtRestContext_Invocations.first, uiMOC)

        // Then EAR is disabled on the context
        XCTAssertFalse(uiMOC.encryptMessagesAtRest)
    }

    func test_DraftMessageContentIsDecrypted_WhenEarIsDisabled() throws {
        // Given
        let databaseKey = VolatileData(from: .randomEncryptionKey())
        await setEAREnabled(true)
        earMessageEncryptionService.getDatabaseKey_MockValue = databaseKey
        earMigrator.migrateAwayFromEncryptionAtRestContext_Invocations.removeAll()

        let conversation = createConversation(in: uiMOC)
        conversation.draftMessage = DraftMessage(
            text: "Beep bloop",
            mentions: [],
            quote: nil
        )

        // Then
        XCTAssertTrue(conversation.hasDraftMessage)
        XCTAssertTrue(conversation.hasEncryptedDraftMessageData)
        XCTAssertEqual(conversation.unencryptedDraftMessageContent, "Beep bloop")

        // Mock
        mockKeyDeletion()

        // When
        XCTAssertNoThrow(try sut.disableEncryptionAtRest(context: uiMOC))

        // Then migrator was called to decrypt draft messages
        XCTAssertEqual(earMigrator.migrateAwayFromEncryptionAtRestContext_Invocations.count, 1)
        XCTAssertEqual(earMigrator.migrateAwayFromEncryptionAtRestContext_Invocations.first, uiMOC)

        // Then EAR is disabled on the context
        XCTAssertFalse(uiMOC.encryptMessagesAtRest)
    }

    func test_MigrationIsCanceled_WhenASingleInstanceFailsToMigrate() throws {
        // Given
        let databaseKey1 = VolatileData(from: .randomEncryptionKey())
        let databaseKey2 = VolatileData(from: .randomEncryptionKey())
        await setEAREnabled(true)

        let conversation = createConversation(in: uiMOC)

        uiMOC.databaseKey = databaseKey1
        try conversation.appendText(content: "Beep bloop")

        uiMOC.databaseKey = databaseKey2
        try conversation.appendText(content: "buzz buzzz")

        let results: [ZMGenericMessageData] = try uiMOC.fetchObjects()
        XCTAssertEqual(results.count, 2)

        // When
        XCTAssertThrowsError(try sut.disableEncryptionAtRest(context: uiMOC)) { error in
            // Then
            switch error {
            case let NSManagedObjectContext.MigrationError.failedToMigrateInstances(type, _):
                XCTAssertEqual(type.entityName(), ZMGenericMessageData.entityName())

            default:
                XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            }
        }

        // Then
        XCTAssertTrue(uiMOC.encryptMessagesAtRest)
    } */

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
        XCTAssertEqual(earMessageEncryptionService.setDatabaseKey_Invocations.first??._storage, decryptedDatabaseKey)
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

    func test_FetchPrivateKeys_EARDisabled() throws {
        // Given
        earStorage.enableEAR(false)
        uiMOC.encryptMessagesAtRest = false

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

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    func test_ItStoresAndClearsDatabaseKeyOnAllContexts() async throws {
        // Given
        // Create the EARService in order to set the EARMessageEncryptionService on the contexts
        _ = await EARService(
            accountID: userID,
            databaseContexts: [uiMOC, syncMOC],
            coreDataStack: coreDataStack,
            sharedUserDefaults: .temporary(),
            authenticationContext: MockAuthenticationContextProtocol()
        )

        let databaseKey = VolatileData(from: .randomEncryptionKey())
        
        // Mock key generation so unlock works
        mockKeyGeneration()

        // When - set key via service (simulating unlock)
        let service = try XCTUnwrap(uiMOC.earMessageEncryptionService)
        service.setDatabaseKey(databaseKey)

        // Then - key is accessible from all contexts (they share the same service)
        XCTAssertEqual(try XCTUnwrap(uiMOC.earMessageEncryptionService).getDatabaseKey(), databaseKey)

        let syncDatbaseKey = await syncMOC.perform { [syncMOC] in
            try? XCTUnwrap(syncMOC.earMessageEncryptionService).getDatabaseKey()
        }
        XCTAssertEqual(syncDatbaseKey, databaseKey)
        
        // When - clear key via service (simulating lock)
        service.setDatabaseKey(nil)

        // Then - key is cleared from all contexts
        XCTAssertNil(try XCTUnwrap(uiMOC.earMessageEncryptionService).getDatabaseKey())

        await syncMOC.perform { [syncMOC] in
            XCTAssertNil(try? XCTUnwrap(syncMOC.earMessageEncryptionService).getDatabaseKey())
        }
    }

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

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func test_OldEncryptionKeysAreReplaced_AfterActivatingEncryptionAtRest() async throws {
        // Given
        let earStorage = EARStorage(userID: userID, sharedUserDefaults: .temporary())
        let messageEncryptionService = EARMessageEncryptionService(earStorage: earStorage)
        let migrator = EARMigrator(messageEncryptionService: messageEncryptionService)
        
        let sut = await EARService(
            accountID: userID,
            keyRepository: EARKeyRepository(),
            keyEncryptor: EARKeyEncryptor(),
            databaseContexts: [uiMOC],
            coreDataStack: coreDataStack,
            canPerformKeyMigration: false,
            earStorage: earStorage,
            messageEncryptionService: messageEncryptionService,
            migrator: migrator,
            authenticationContext: MockAuthenticationContextProtocol()
        )

        let oldDatabaseKey = try sut.generateKeys()

        sut.setInitialEARFlagValue(true)
        await setEAREnabled(true)
        let oldPublicKeys = try XCTUnwrap(sut.fetchPublicKeys())
        let oldPrivateKeys = try XCTUnwrap(sut.fetchPrivateKeys(includingPrimary: true))
        let oldPrimaryPublicKey = oldPublicKeys.primary
        let oldPrimaryPrivateKey = try XCTUnwrap(oldPrivateKeys.primary)
        let oldSecondaryPublicKey = oldPublicKeys.secondary
        let oldSecondaryPrivateKey = oldPrivateKeys.secondary
        await setEAREnabled(false)

        // When
        try sut.enableEncryptionAtRest(context: uiMOC, skipMigration: true)

        // Then
        XCTAssertFalse(uiMOC.isLocked)

        let newPublicKeys = try XCTUnwrap(sut.fetchPublicKeys())
        let newPrivateKeys = try XCTUnwrap(sut.fetchPrivateKeys(includingPrimary: true))
        let newPrimaryPublicKey = newPublicKeys.primary
        let newPrimaryPrivateKey = try XCTUnwrap(newPrivateKeys.primary)
        let newSecondaryPublicKey = newPublicKeys.secondary
        let newSecondaryPrivateKey = newPrivateKeys.secondary
        let newDatabaseKey = try XCTUnwrap(try XCTUnwrap(uiMOC.earMessageEncryptionService).getDatabaseKey())
        
        XCTAssertNotEqual(oldPrimaryPublicKey, newPrimaryPublicKey)
        XCTAssertNotEqual(oldPrimaryPrivateKey, newPrimaryPrivateKey)
        XCTAssertNotEqual(oldSecondaryPublicKey, newSecondaryPublicKey)
        XCTAssertNotEqual(oldSecondaryPrivateKey, newSecondaryPrivateKey)
        XCTAssertNotEqual(oldDatabaseKey, newDatabaseKey)
        XCTAssertTrue(earStorage.earEnabled())
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

private extension ZMGenericMessageData {

    var unencryptedContent: String? {
        underlyingMessage?.text.content
    }

}

private extension NSManagedObjectContext {

    func fetchObjects<T: ZMManagedObject>() throws -> [T] {
        let request = NSFetchRequest<T>(entityName: T.entityName())
        request.returnsObjectsAsFaults = false
        return try fetch(request)
    }

}

private extension ZMConversation {

    var hasEncryptedDraftMessageData: Bool {
        draftMessageData != nil && draftMessageNonce != nil
    }

    var unencryptedDraftMessageContent: String? {
        draftMessage?.text
    }

}
