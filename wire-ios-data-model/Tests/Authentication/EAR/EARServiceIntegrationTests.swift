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

/// Integration tests for EARService
///
/// These tests use real EARMessageEncryptionService and EARMigrator
/// to verify the end-to-end behavior of EARService. They test that the full encryption/decryption
/// flow works correctly, including:
/// - Message content encryption/decryption
/// - Normalized text handling
/// - Draft message encryption/decryption
/// - Key generation and storage in keychain
/// - Service sharing across contexts
///
/// For unit tests that verify EARService orchestration with mocked dependencies,
/// see EARServiceTests.swift
@MainActor
final class EARServiceIntegrationTests: EARServiceTestsBase, @MainActor EARServiceDelegate {

    var prepareForMigrationCalls = 0
    var earStorage: EARStorage!
    var messageEncryptionService: EARMessageEncryptionServiceProtocol!
    var migrator: EARMigrator!
    
    // MARK: - Life cycle

    override func setUp() async throws {
        try await super.setUp()
        
        earStorage = EARStorage(userID: userID, sharedUserDefaults: .temporary())
        messageEncryptionService = EARMessageEncryptionService(earStorage: earStorage)
        migrator = EARMigrator(messageEncryptionService: messageEncryptionService)
        
        prepareForMigrationCalls = 0
    }

    override func tearDown() async throws {
        earStorage = nil
        messageEncryptionService = nil
        migrator = nil
        try await super.tearDown()
    }

    /// Creates EARService with real encryption service and migrator (integration test setup)
    func createSUT(
        canPerformMigration: Bool = false,
        contexts: [NSManagedObjectContext]? = nil
    ) async -> EARService {
        let sut = await EARService(
            accountID: userID,
            keyRepository: keyRepository,
            keyEncryptor: keyEncryptor,
            databaseContexts: contexts ?? [uiMOC, syncMOC],
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

    // MARK: - Enable EAR

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
    
    func test_ExistingMessageContentIsDecrypted_WhenEarIsDisabled() async throws {
        // Given
        let sut = await createSUT(canPerformMigration: true)

        // Mock
        mockKeyGeneration()
        mockKeyDeletion()

        // Enable EAR
        XCTAssertNoThrow(try sut.enableEncryptionAtRest(context: uiMOC))
        XCTAssertEqual(prepareForMigrationCalls, 1)
        
        // Add message to conversation
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

        // When disabling EAR
        XCTAssertNoThrow(try sut.disableEncryptionAtRest(context: uiMOC))

        // Then migration delegate was called
        XCTAssertEqual(prepareForMigrationCalls, 2)

        XCTAssertFalse(messageData.isEncrypted)
        XCTAssertEqual(messageData.unencryptedContent, "Beep bloop")

        // Then EAR is disabled on the context
        XCTAssertFalse(uiMOC.encryptMessagesAtRest)
    }

    func test_NormalizedMessageContentIsUpdated_WhenEarIsDisabled() async throws {
        // Given
        let sut = await createSUT(canPerformMigration: true)

        // Mock
        mockKeyGeneration()
        mockKeyDeletion()

        // Enable EAR
        XCTAssertNoThrow(try sut.enableEncryptionAtRest(context: uiMOC))
        XCTAssertEqual(prepareForMigrationCalls, 1)

        // Add message to conversation
        let conversation = createConversation(in: uiMOC)
        let message = try conversation.appendText(content: "Beep bloop") as! ZMMessage

        XCTAssertNotNil(message.normalizedText)
        XCTAssertEqual(message.normalizedText?.isEmpty, true)

        // When
        XCTAssertNoThrow(try sut.disableEncryptionAtRest(context: uiMOC))

        // Then
        XCTAssertNotNil(message.normalizedText)
        XCTAssertEqual(message.normalizedText?.isEmpty, false)
        
        // Then EAR is disabled on the context
        XCTAssertFalse(uiMOC.encryptMessagesAtRest)
    }

    func test_DraftMessageContentIsDecrypted_WhenEarIsDisabled() async throws {
        // Given
        let sut = await createSUT(canPerformMigration: true)

        // Mock
        mockKeyGeneration()
        mockKeyDeletion()

        // Enable EAR
        XCTAssertNoThrow(try sut.enableEncryptionAtRest(context: uiMOC))
        XCTAssertEqual(prepareForMigrationCalls, 1)
       
        // Add message to conversation
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

        // Then EAR is disabled on the context
        XCTAssertFalse(uiMOC.encryptMessagesAtRest)
    }

    func test_MigrationIsCanceled_WhenASingleInstanceFailsToMigrate() async throws {
        // Given
        let databaseKey1 = VolatileData(from: .randomEncryptionKey())
        let databaseKey2 = VolatileData(from: .randomEncryptionKey())
        await setEAREnabled(true)

        // create sut
        let sut = await createSUT(canPerformMigration: true)
        
        // create conversation
        let conversation = createConversation(in: uiMOC)

        // add message encrypted with first db key
        messageEncryptionService.setDatabaseKey(databaseKey1)
        try conversation.appendText(content: "Beep bloop")

        // add message encrypted with second db key
        messageEncryptionService.setDatabaseKey(databaseKey2)
        try conversation.appendText(content: "buzz buzzz")

        let results: [ZMGenericMessageData] = try uiMOC.fetchObjects()
        XCTAssertEqual(results.count, 2)

        // When
        XCTAssertThrowsError(try sut.disableEncryptionAtRest(context: uiMOC)) { error in
            switch error {
            case let EARMigrator.MigrationError.failedToMigrateInstances(type, _):
                XCTAssertEqual(type.entityName(), ZMGenericMessageData.entityName())
            default:
                XCTFail("Unexpected error thrown: \(error.localizedDescription)")
            }
        }

        // Then
        XCTAssertTrue(uiMOC.encryptMessagesAtRest)
    }

    // MARK: - Security Tests

    // @SF.Storage @TSFI.FS-IOS @TSFI.Enclave-IOS @S0.1 @S0.2
    func test_ItStoresAndClearsDatabaseKeyOnAllContexts() async throws {
        // Given
        // Create sut in order to set the EARMessageEncryptionService on the contexts
        _ = await createSUT()
        
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

    // @SF.Storage @TSFI.UserInterface @S0.1 @S0.2
    func test_OldEncryptionKeysAreReplaced_AfterActivatingEncryptionAtRest() async throws {
        // Given
        let earStorage = EARStorage(userID: userID, sharedUserDefaults: .temporary())
        let messageEncryptionService = EARMessageEncryptionService(earStorage: earStorage)
        let migrator = EARMigrator(messageEncryptionService: messageEncryptionService)

        let sut = await EARService(
            accountID: userID,
            keyRepository: EARKeyRepository(),  // Real keychain access
            keyEncryptor: EARKeyEncryptor(),    // Real crypto
            databaseContexts: [uiMOC],
            coreDataStack: coreDataStack,
            canPerformKeyMigration: false,
            earStorage: earStorage,
            messageEncryptionService: messageEncryptionService,
            migrator: migrator,
            authenticationContext: MockAuthenticationContextProtocol()
        )
        sut.delegate = self

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
}
