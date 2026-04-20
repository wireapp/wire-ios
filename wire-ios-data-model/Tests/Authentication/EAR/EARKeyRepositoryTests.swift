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

import Foundation
import Testing
@testable import WireDataModel

@Suite
struct EARKeyRepositoryTests {

    let sut: EARKeyRepository
    let accountID: UUID
    let keyGenerator: EARKeyGenerator

    let primaryPublicDesc: PublicEARKeyDescription
    let secondaryPublicDesc: PublicEARKeyDescription
    let primaryPrivateDesc: PrivateEARKeyDescription
    let secondaryPrivateDesc: PrivateEARKeyDescription
    let databaseKeyDesc: DatabaseEARKeyDescription

    init() {
        self.sut = EARKeyRepository()
        self.accountID = UUID()
        self.keyGenerator = EARKeyGenerator()

        self.primaryPublicDesc = .primaryKeyDescription(accountID: accountID)
        self.secondaryPublicDesc = .secondaryKeyDescription(accountID: accountID)
        self.primaryPrivateDesc = .primaryKeyDescription(accountID: accountID, context: nil)
        self.secondaryPrivateDesc = .secondaryKeyDescription(accountID: accountID)
        self.databaseKeyDesc = .keyDescription(accountID: accountID)
    }

    // MARK: - Public Key

    @Test("Stores and fetches a public key")
    func storeAndFetchPublicKey() throws {
        // Given
        let (publicKey, _) = try keyGenerator.generatePrimaryPublicPrivateKeyPair(id: "test-primary-\(accountID)")
        defer { try? sut.deletePublicKey(description: primaryPublicDesc) }

        // When
        try sut.storePublicKey(description: primaryPublicDesc, key: publicKey)
        let fetched = try sut.fetchPublicKey(description: primaryPublicDesc)

        // Then
        #expect(SecKeyCopyExternalRepresentation(fetched, nil) == SecKeyCopyExternalRepresentation(publicKey, nil))
    }

    @Test("Returns cached public key without hitting keychain again")
    func fetchPublicKey_returnsFromCache() throws {
        // Given
        let (publicKey, _) = try keyGenerator.generatePrimaryPublicPrivateKeyPair(id: "test-cache-\(accountID)")
        try sut.storePublicKey(description: primaryPublicDesc, key: publicKey)

        // populate cache
        _ = try sut.fetchPublicKey(description: primaryPublicDesc)
        // remove from keychain, only cache remains
        try KeychainManager.deleteItem(primaryPublicDesc)

        // When
        let fetched = try sut.fetchPublicKey(description: primaryPublicDesc)

        // Then
        #expect(SecKeyCopyExternalRepresentation(fetched, nil) == SecKeyCopyExternalRepresentation(publicKey, nil))
    }

    @Test("Throws keyNotFound when public key is absent")
    func fetchPublicKey_throwsKeyNotFound_whenAbsent() {
        #expect(throws: EARKeyRepositoryFailure.keyNotFound) {
            try sut.fetchPublicKey(description: primaryPublicDesc)
        }
    }

    @Test("Deletes public key from keychain and cache")
    func deletePublicKey_removesFromKeychainAndCache() throws {
        // Given
        let (publicKey, _) = try keyGenerator.generatePrimaryPublicPrivateKeyPair(id: "test-delete-\(accountID)")
        try sut.storePublicKey(description: primaryPublicDesc, key: publicKey)

        // populate cache
        _ = try sut.fetchPublicKey(description: primaryPublicDesc)

        // When
        try sut.deletePublicKey(description: primaryPublicDesc)

        // Then — cache cleared, keychain cleared
        #expect(throws: EARKeyRepositoryFailure.keyNotFound) {
            try sut.fetchPublicKey(description: primaryPublicDesc)
        }
    }

    // MARK: - Database Key

    @Test("Stores and fetches a database key")
    func storeAndFetchDatabaseKey() throws {
        // Given
        let databaseKey = Data.randomEncryptionKey()
        defer { try? sut.deleteDatabaseKey(description: databaseKeyDesc) }

        // When
        try sut.storeDatabaseKey(description: databaseKeyDesc, key: databaseKey)
        let fetched = try sut.fetchDatabaseKey(description: databaseKeyDesc)

        // Then
        #expect(fetched == databaseKey)
    }

    @Test("Throws keyNotFound when database key is absent")
    func fetchDatabaseKey_throwsKeyNotFound_whenAbsent() {
        #expect(throws: EARKeyRepositoryFailure.keyNotFound) {
            try sut.fetchDatabaseKey(description: databaseKeyDesc)
        }
    }

    @Test("Deletes database key from keychain")
    func deleteDatabaseKey_removesFromKeychain() throws {
        // Given
        try sut.storeDatabaseKey(description: databaseKeyDesc, key: .randomEncryptionKey())

        // When
        try sut.deleteDatabaseKey(description: databaseKeyDesc)

        // Then
        #expect(throws: EARKeyRepositoryFailure.keyNotFound) {
            try sut.fetchDatabaseKey(description: databaseKeyDesc)
        }
    }

    // MARK: - Cache

    @Test("clearCache forces a keychain refetch on next access")
    func clearCache_forcesRefetchFromKeychain() throws {
        // Given
        let (publicKey, _) = try keyGenerator.generatePrimaryPublicPrivateKeyPair(id: "test-clear-\(accountID)")
        try sut.storePublicKey(description: primaryPublicDesc, key: publicKey)

        // populate cache
        _ = try sut.fetchPublicKey(description: primaryPublicDesc)
        // remove from keychain
        try KeychainManager.deleteItem(primaryPublicDesc)

        // When
        sut.clearCache()

        // Then — cache is gone, keychain miss propagates
        #expect(throws: EARKeyRepositoryFailure.keyNotFound) {
            try sut.fetchPublicKey(description: primaryPublicDesc)
        }
    }

}
