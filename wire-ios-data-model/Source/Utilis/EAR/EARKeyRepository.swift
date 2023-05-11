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
import LocalAuthentication

// sourcery: AutoMockable
public protocol EARKeyRepositoryInterface {

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

public enum EarKeyRepositoryFailure: Error {

    case keyNotFound

}

public class EARKeyRepository: EARKeyRepositoryInterface {

    private var keyCache = [String: SecKey]()

    // MARK: - Life cycle

    public init() {}

    // MARK: - Public keys

    public func storePublicKey(description: PublicEARKeyDescription, key: SecKey) throws {
        try KeychainManager.storeItem(description, value: key)
    }

    public func fetchPublicKey(description: PublicEARKeyDescription) throws -> SecKey {
        if let key = keyCache[description.id] {
            return key
        }

        do {
            let key: SecKey = try KeychainManager.fetchItem(description)
            keyCache[description.id] = key
            return key
        } catch KeychainManager.Error.failedToFetchItemFromKeychain(errSecItemNotFound) {
            throw EarKeyRepositoryFailure.keyNotFound
        } catch {
            throw error
        }
    }

    public func deletePublicKey(description: PublicEARKeyDescription) throws {
        try KeychainManager.deleteItem(description)
        keyCache[description.id] = nil
    }

    // MARK: - Private keys

    public func fetchPrivateKey(description: PrivateEARKeyDescription) throws -> SecKey {
        if let key = keyCache[description.id] {
            return key
        }

        do {
            let key: SecKey = try KeychainManager.fetchItem(description)
            keyCache[description.id] = key
            return key
        } catch KeychainManager.Error.failedToFetchItemFromKeychain(errSecItemNotFound) {
            throw EarKeyRepositoryFailure.keyNotFound
        } catch {
            throw error
        }
    }

    public func deletePrivateKey(description: PrivateEARKeyDescription) throws {
        try KeychainManager.deleteItem(description)
        keyCache[description.id] = nil
    }

    // MARK: - Datatbase keys

    public func storeDatabaseKey(description: DatabaseEARKeyDescription, key: Data) throws {
        try KeychainManager.storeItem(description, value: key)
    }

    public func fetchDatabaseKey(description: DatabaseEARKeyDescription) throws -> Data {
        do {
            return try KeychainManager.fetchItem(description)
        } catch KeychainManager.Error.failedToFetchItemFromKeychain(errSecItemNotFound) {
            throw EarKeyRepositoryFailure.keyNotFound
        } catch {
            throw error
        }
    }

    public func deleteDatabaseKey(description: DatabaseEARKeyDescription) throws {
        return try KeychainManager.deleteItem(description)
    }

    // MARK: - Cache

    public func clearCache() {
        keyCache.removeAll()
    }

}
