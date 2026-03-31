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

/// Base class providing common test utilities for EARService tests
///
/// This class contains shared helper methods, mock setup utilities, and test data
/// generation used by both unit tests (EARServiceTests) and integration tests
/// (EARServiceIntegrationTests).
@MainActor
class EARServiceTestsBase: XCTestCase {

    var coreDataStack: CoreDataStack!
    var uiMOC: NSManagedObjectContext!
    var syncMOC: NSManagedObjectContext!
    var keyRepository: MockEARKeyRepositoryInterface!
    var keyEncryptor: MockEARKeyEncryptorInterface!
    var userID: UUID!

    // MARK: - Setup/Teardown

    override func setUp() async throws {
        try await super.setUp()

        coreDataStack = try await CoreDataStackHelper().createStack()
        uiMOC = coreDataStack.viewContext
        syncMOC = coreDataStack.syncContext

        userID = UUID()

        keyRepository = MockEARKeyRepositoryInterface()
        keyEncryptor = MockEARKeyEncryptorInterface()

        _ = await uiMOC.perform { [uiMOC, userID] in
            let modelHelper = ModelHelper()
            modelHelper.createSelfUser(id: userID!, in: uiMOC!)
            modelHelper.createSelfClient(in: uiMOC!)
        }
    }

    override func tearDown() async throws {
        uiMOC = nil
        syncMOC = nil
        coreDataStack = nil
        userID = nil
        keyRepository = nil
        keyEncryptor = nil
        try await super.tearDown()
    }

    // MARK: - Key Generation Helpers

    /// Generates a primary key pair for testing
    func generatePrimaryKeyPair() throws -> (publicKey: SecKey, privateKey: SecKey) {
        let keyGenerator = EARKeyGenerator()
        return try keyGenerator.generatePrimaryPublicPrivateKeyPair(id: "primary")
    }

    /// Generates a secondary key pair for testing
    func generateSecondaryKeyPair() throws -> (publicKey: SecKey, privateKey: SecKey) {
        let keyGenerator = EARKeyGenerator()
        return try keyGenerator.generateSecondaryPublicPrivateKeyPair(id: "secondary")
    }

    // MARK: - Mock Setup Helpers

    /// Sets up all key-related mocks for a complete flow (delete, encrypt, store, fetch)
    func mockKeyGeneration() {
        mockKeyDeletion()
        keyEncryptor.encryptDatabaseKeyPublicKey_MockValue = .randomEncryptionKey()
        mockKeyStorage()
        try? mockKeyFetching()
    }

    /// Mocks key deletion operations
    func mockKeyDeletion() {
        keyRepository.deletePublicKeyDescription_MockMethod = { _ in }
        keyRepository.deletePrivateKeyDescription_MockMethod = { _ in }
        keyRepository.deleteDatabaseKeyDescription_MockMethod = { _ in }
    }

    /// Mocks key storage operations
    func mockKeyStorage() {
        keyRepository.storePublicKeyDescriptionKey_MockMethod = { _, _ in }
        keyRepository.storeDatabaseKeyDescriptionKey_MockMethod = { _, _ in }
    }

    /// Mocks key fetching operations with generated test keys
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

    // MARK: - Test Data Helpers

    /// Helper to enable/disable EAR on the UI context
    func setEAREnabled(_ enabled: Bool) async {
        uiMOC.encryptMessagesAtRest = enabled
    }

    /// Creates a test conversation in the specified context
    @discardableResult
    func createConversation(
        in moc: NSManagedObjectContext
    ) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: moc)
        conversation.remoteIdentifier = UUID()
        return conversation
    }
}

// MARK: - Test Helper Extensions

extension ZMGenericMessageData {

    /// Returns the unencrypted text content of a message for testing
    var unencryptedContent: String? {
        underlyingMessage?.text.content
    }
}

extension NSManagedObjectContext {

    /// Fetches all objects of a specific type from the context
    func fetchObjects<T: ZMManagedObject>() throws -> [T] {
        let request = NSFetchRequest<T>(entityName: T.entityName())
        request.returnsObjectsAsFaults = false
        return try fetch(request)
    }
}

extension ZMConversation {

    /// Returns true if the conversation has encrypted draft message data
    var hasEncryptedDraftMessageData: Bool {
        draftMessageData != nil && draftMessageNonce != nil
    }

    /// Returns the unencrypted draft message text for testing
    var unencryptedDraftMessageContent: String? {
        draftMessage?.text
    }
}
