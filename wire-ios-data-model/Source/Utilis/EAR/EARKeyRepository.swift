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

// TODO: make automockable

public protocol EARKeyRepositoryInterface {

    func storePublicKey(description: PublicEARKeyDescription, key: SecKey) throws
    func fetchPublicKey(description: PublicEARKeyDescription) throws -> SecKey
    func fetchPrivateKey(description: PrivateEARKeyDescription) throws -> SecKey
    func storeDatabaseKey(description: DatabaseEARKeyDescription, key: Data) throws
    func fetchDatabaseKey(description: DatabaseEARKeyDescription) throws -> Data

}

public class EARKeyRepository: EARKeyRepositoryInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - Public keys

    public func storePublicKey(description: PublicEARKeyDescription, key: SecKey) throws {
        try KeychainManager.storeItem(description, value: key)
    }

    public func fetchPublicKey(description: PublicEARKeyDescription) throws -> SecKey {
        return try KeychainManager.fetchItem(description)
    }

    // MARK: - Private keys

    public func fetchPrivateKey(description: PrivateEARKeyDescription) throws -> SecKey {
        return try KeychainManager.fetchItem(description)
    }

    // MARK: - Datatbase keys

    public func storeDatabaseKey(description: DatabaseEARKeyDescription, key: Data) throws {
        try KeychainManager.storeItem(description, value: key)
    }

    public func fetchDatabaseKey(description: DatabaseEARKeyDescription) throws -> Data {
        return try KeychainManager.fetchItem(description)
    }

}
