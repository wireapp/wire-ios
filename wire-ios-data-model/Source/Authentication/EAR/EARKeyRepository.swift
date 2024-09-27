//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import LocalAuthentication
import Security

// MARK: - EARKeyRepositoryInterface

// sourcery: AutoMockable
protocol EARKeyRepositoryInterface {
    func storePublicKey(description: PublicEARKeyDescription, key: SecKey) throws
    func fetchPublicKey(description: PublicEARKeyDescription) throws -> SecKey
    func deletePublicKey(description: PublicEARKeyDescription) throws
    func fetchPrivateKey(description: PrivateEARKeyDescription) throws -> SecKey
    func deletePrivateKey(description: PrivateEARKeyDescription) throws
    func storeDatabaseKey(description: DatabaseEARKeyDescription, key: Data) throws
    func fetchDatabaseKey(description: DatabaseEARKeyDescription) throws -> Data
    func deleteDatabaseKey(description: DatabaseEARKeyDescription) throws
    func clearCache()
}

// MARK: - EARKeyRepository

/// Caches keys for reuse and avoid prompting the user to authenticate for each key access.
final class EARKeyRepository: EARKeyRepositoryInterface {
    private var keyCache = [String: SecKey]()

    // MARK: - Life cycle

    init() {}

    // MARK: - Public keys

    func storePublicKey(description: PublicEARKeyDescription, key: SecKey) throws {
        try KeychainManager.storeItem(description, value: key)
    }

    func fetchPublicKey(description: PublicEARKeyDescription) throws -> SecKey {
        if let key = keyCache[description.id] {
            return key
        }

        do {
            let key: SecKey = try KeychainManager.fetchItem(description)
            keyCache[description.id] = key
            return key
        } catch KeychainManager.Error.failedToFetchItemFromKeychain(errSecItemNotFound) {
            throw EARKeyRepositoryFailure.keyNotFound
        } catch {
            throw error
        }
    }

    func deletePublicKey(description: PublicEARKeyDescription) throws {
        try KeychainManager.deleteItem(description)
        keyCache[description.id] = nil
    }

    // MARK: - Private keys

    func fetchPrivateKey(description: PrivateEARKeyDescription) throws -> SecKey {
        if let key = keyCache[description.id] {
            WireLogger.ear.info("found private key in key cache")
            return key
        }

        do {
            WireLogger.ear.info("did not find private key in key cache. fetching from keychain")

            let key: SecKey = try KeychainManager.fetchItem(description)
            keyCache[description.id] = key
            return key
        } catch KeychainManager.Error.failedToFetchItemFromKeychain(errSecItemNotFound) {
            WireLogger.ear.warn("private key not found in keychain", attributes: .safePublic)
            throw EARKeyRepositoryFailure.keyNotFound
        } catch {
            WireLogger.ear.warn("failed to fetch private key: \(error)", attributes: .safePublic)
            throw error
        }
    }

    func deletePrivateKey(description: PrivateEARKeyDescription) throws {
        try KeychainManager.deleteItem(description)
        keyCache[description.id] = nil
    }

    // MARK: - Database keys

    func storeDatabaseKey(description: DatabaseEARKeyDescription, key: Data) throws {
        try KeychainManager.storeItem(description, value: key)
    }

    func fetchDatabaseKey(description: DatabaseEARKeyDescription) throws -> Data {
        do {
            return try KeychainManager.fetchItem(description)
        } catch KeychainManager.Error.failedToFetchItemFromKeychain(errSecItemNotFound) {
            throw EARKeyRepositoryFailure.keyNotFound
        } catch {
            throw error
        }
    }

    func deleteDatabaseKey(description: DatabaseEARKeyDescription) throws {
        try KeychainManager.deleteItem(description)
    }

    // MARK: - Cache

    func clearCache() {
        WireLogger.ear.info("clear key cache", attributes: .safePublic)
        keyCache.removeAll()
    }
}
