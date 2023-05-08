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

final class EARServiceTests: ZMBaseManagedObjectTest, EARServiceDelegate {

    var sut: EARService!
    var keyRepository: MockEARKeyRepositoryInterface!
    var keyEncryptor: MockEARKeyEncryptorInterface!

    var prepareForMigrationCalls = 0

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()

        keyRepository = MockEARKeyRepositoryInterface()
        keyEncryptor = MockEARKeyEncryptorInterface()

        sut = EARService(
            accountID: userIdentifier,
            keyRepository: keyRepository,
            keyEncryptor: keyEncryptor,
            databaseContexts: [uiMOC, syncMOC]
        )

        sut.delegate = self
        prepareForMigrationCalls = 0

        createSelfClient(onMOC: uiMOC)
    }

    override func tearDown() {
        sut = nil
        keyRepository = nil
        keyEncryptor = nil
        uiMOC.encryptMessagesAtRest = false
        uiMOC.databaseKey = nil
        super.tearDown()
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
        uiMOC.encryptMessagesAtRest = true

        // When
        XCTAssertNoThrow(try sut.enableEncryptionAtRest(context: uiMOC))

        // Then
        XCTAssertEqual(prepareForMigrationCalls, 0)
    }

    func test_EnableEncryptionAtRest_SkipMigration() throws {
        // Given
        uiMOC.encryptMessagesAtRest = false
        uiMOC.databaseKey = nil

        syncMOC.performAndWait {
            syncMOC.encryptMessagesAtRest = false
            syncMOC.databaseKey = nil
        }

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

        // Then migration was not run
        XCTAssertEqual(prepareForMigrationCalls, 0)

        // Then EAR is enabled on the context
        XCTAssertTrue(uiMOC.encryptMessagesAtRest)

        // Then all contexts have the database key.
        XCTAssertNotNil(uiMOC.databaseKey)
        syncMOC.performAndWait { XCTAssertNotNil(syncMOC.databaseKey) }
    }

    func test_EnableEncryptionAtRest_RollbackOnFailure() throws {
        // Given
        uiMOC.encryptMessagesAtRest = false

        // Mock
        mockKeyGeneration()
        keyRepository.storeDatabaseKeyDescriptionKey_MockError = MockError.cannotStoreKey

        // When
        XCTAssertThrowsError(try sut.enableEncryptionAtRest(context: uiMOC, skipMigration: true)) { error in
            guard case MockError.cannotStoreKey = error else {
                return XCTFail("unexpected error: \(error)")
            }
        }

        // Then
        XCTAssertFalse(uiMOC.encryptMessagesAtRest)
        XCTAssertNil(uiMOC.databaseKey)

        // In total, the 5 keys (2 public, 2 private, 1 database) were
        // deleted 2 times. Once before generating new keys, and once
        // after cleaning up the the error.
        XCTAssertEqual(keyRepository.deletePublicKeyDescription_Invocations.count, 4)
        XCTAssertEqual(keyRepository.deletePrivateKeyDescription_Invocations.count, 4)
        XCTAssertEqual(keyRepository.deleteDatabaseKeyDescription_Invocations.count, 2)
    }

    func test_EnableEncryptionAtRest_FailedToMigrate() throws {
        // Given
        uiMOC.encryptMessagesAtRest = false
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
    func test_ExistingMessageContentIsEncrypted_WhenEarIsEnabled() throws {
        // Given
        uiMOC.encryptMessagesAtRest = false
        uiMOC.databaseKey = nil

        let conversation = createConversation(in: uiMOC)
        try conversation.appendText(content: "Beep bloop")

        let results: [ZMGenericMessageData] = try uiMOC.fetchObjects()

        guard let messageData = results.first else {
            XCTFail("Could not find message data.")
            return
        }

        // Then
        XCTAssertFalse(messageData.isEncrypted)
        XCTAssertEqual(messageData.unencryptedContent, "Beep bloop")
        XCTAssertFalse(uiMOC.encryptMessagesAtRest)

        // Mock
        mockKeyGeneration()

        // When
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
    func test_NormalizedMessageContentIsCleared_WhenEarIsEnabled() throws {
        // Given
        uiMOC.encryptMessagesAtRest = false
        uiMOC.databaseKey = nil

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
    func test_DraftMessageContentIsEncrypted_WhenEarIsEnabled() throws {
        // Given
        uiMOC.encryptMessagesAtRest = false
        uiMOC.databaseKey = nil

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

    func test_DisableEncryptionAtRest_DontDisableIfNotNeeded() throws {
        // Given
        uiMOC.encryptMessagesAtRest = false

        // When
        XCTAssertNoThrow(try sut.disableEncryptionAtRest(context: uiMOC))

        // Then
        XCTAssertEqual(prepareForMigrationCalls, 0)
    }

    func test_DisableEncryptionAtRest_DatabaseKeyMissing() throws {
        // Given
        uiMOC.encryptMessagesAtRest = true
        uiMOC.databaseKey = nil

        // When
        XCTAssertThrowsError(try sut.disableEncryptionAtRest(context: uiMOC)) { error in
            guard case EARServiceFailure.databaseKeyMissing = error else {
                return XCTFail("unexpected error: \(error)")
            }
        }
    }

    func test_DisableEncryptionAtRest_SkipMigration() throws {
        // Given
        let databaseKey = VolatileData(from: .randomEncryptionKey())
        uiMOC.encryptMessagesAtRest = true
        uiMOC.databaseKey = databaseKey

        syncMOC.performAndWait {
            syncMOC.encryptMessagesAtRest = true
            syncMOC.databaseKey = databaseKey
        }

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

        // Then EAR is disabled on the context
        XCTAssertFalse(uiMOC.encryptMessagesAtRest)

        // Then all contexts no longer have the database key
        XCTAssertNil(uiMOC.databaseKey)
        syncMOC.performAndWait { XCTAssertNil(syncMOC.databaseKey) }
    }

    func test_ExistingMessageContentIsDecrypted_WhenEarIsDisabled() throws {
        // Given
        let databaseKey = VolatileData(from: .randomEncryptionKey())
        uiMOC.encryptMessagesAtRest = true
        uiMOC.databaseKey = databaseKey

        let conversation = createConversation(in: uiMOC)
        try conversation.appendText(content: "Beep bloop")

        let results: [ZMGenericMessageData] = try uiMOC.fetchObjects()

        guard let messageData = results.first else {
            XCTFail("Could not find message data.")
            return
        }

        // Then
        XCTAssertTrue(messageData.isEncrypted)
        XCTAssertEqual(messageData.unencryptedContent, "Beep bloop")

        // Mock
        mockKeyDeletion()

        // When
        XCTAssertNoThrow(try sut.disableEncryptionAtRest(context: uiMOC))

        // Then migration was run
        XCTAssertEqual(prepareForMigrationCalls, 1)
        XCTAssertFalse(messageData.isEncrypted)
        XCTAssertEqual(messageData.unencryptedContent, "Beep bloop")

        // Then EAR is disabled on the context
        XCTAssertFalse(uiMOC.encryptMessagesAtRest)
    }

    func test_NormalizedMessageContentIsUpdated_WhenEarIsDisabled() throws {
        // Given
        let databaseKey = VolatileData(from: .randomEncryptionKey())
        uiMOC.encryptMessagesAtRest = true
        uiMOC.databaseKey = databaseKey

        let conversation = createConversation(in: uiMOC)
        let message = try conversation.appendText(content: "Beep bloop") as! ZMMessage

        // Then
        XCTAssertNotNil(message.normalizedText)
        XCTAssertEqual(message.normalizedText?.isEmpty, true)

        // Mock
        mockKeyDeletion()

        // When
        XCTAssertNoThrow(try sut.disableEncryptionAtRest(context: uiMOC))

        // Then
        XCTAssertNotNil(message.normalizedText)
        XCTAssertEqual(message.normalizedText?.isEmpty, false)
        XCTAssertFalse(uiMOC.encryptMessagesAtRest)
    }

    func test_DraftMessageContentIsDecrypted_WhenEarIsDisabled() throws {
        // Given
        let databaseKey = VolatileData(from: .randomEncryptionKey())
        uiMOC.encryptMessagesAtRest = true
        uiMOC.databaseKey = databaseKey

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

        // Then
        XCTAssertTrue(conversation.hasDraftMessage)
        XCTAssertFalse(conversation.hasEncryptedDraftMessageData)
        XCTAssertEqual(conversation.unencryptedDraftMessageContent, "Beep bloop")
        XCTAssertFalse(uiMOC.encryptMessagesAtRest)
    }

    func test_MigrationIsCanceled_WhenASingleInstanceFailsToMigrate() throws {
        // Given
        let databaseKey1 = VolatileData(from: .randomEncryptionKey())
        let databaseKey2 = VolatileData(from: .randomEncryptionKey())
        uiMOC.encryptMessagesAtRest = true

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
    }

    // MARK: - Lock database

    func test_LockDatabase() throws {
        // Given
        let databaseKey = VolatileData(from: .randomEncryptionKey())

        uiMOC.databaseKey = databaseKey

        syncMOC.performAndWait {
            syncMOC.databaseKey = databaseKey
        }

        // When
        sut.lockDatabase()

        // Then
        XCTAssertNil(uiMOC.databaseKey)

        syncMOC.performAndWait {
            XCTAssertNil(syncMOC.databaseKey)
        }
    }

    // MARK: - Unlock database

    func test_UnlockDatabase() throws {
        // Given
        let keys = try generatePrimaryKeyPair()
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
        XCTAssertEqual(uiMOC.databaseKey?._storage, decryptedDatabaseKey)

        syncMOC.performAndWait {
            XCTAssertEqual(syncMOC.databaseKey?._storage, decryptedDatabaseKey)
        }
    }

    // MARK: - Fetch public keys

    func test_FetchPublicKeys() throws {
        // Given
        let primaryKeys = try generatePrimaryKeyPair()
        let secondaryKeys = try generateSecondaryKeyPair()

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
        let primaryKeys = try generatePrimaryKeyPair()

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
        let primaryKeys = try generatePrimaryKeyPair()
        let secondaryKeys = try generateSecondaryKeyPair()

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
        let secondaryKeys = try generateSecondaryKeyPair()

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

private extension ZMGenericMessageData {

    var unencryptedContent: String? {
        return underlyingMessage?.text.content
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
        return draftMessageData != nil && draftMessageNonce != nil
    }

    var unencryptedDraftMessageContent: String? {
        return draftMessage?.text
    }

}
