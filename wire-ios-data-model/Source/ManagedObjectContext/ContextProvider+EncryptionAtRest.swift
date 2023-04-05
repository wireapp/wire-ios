//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

public extension ContextProvider {

    /// Retrieve or create the encryption keys necessary for enabling / disabling encryption at rest.
    ///
    /// This method should only be called on the main thread.

    func encryptionKeysForSettingEncryptionAtRest(enabled: Bool) throws -> EncryptionKeys {
        var encryptionKeys: EncryptionKeys

        if enabled {
            try EncryptionKeys.deleteKeys(for: account)
            encryptionKeys = try EncryptionKeys.createKeys(for: account)
            storeEncryptionKeysInAllContexts(encryptionKeys: encryptionKeys)
        } else {
            encryptionKeys = try viewContext.getEncryptionKeys()
            clearEncryptionKeysInAllContexts()
        }

        return encryptionKeys
    }

    /// Synchronously stores the given encryption keys in each managed object context.

    func storeEncryptionKeysInAllContexts(encryptionKeys: EncryptionKeys) {
        for context in [viewContext, syncContext, searchContext] {
            context.performAndWait { context.encryptionKeys = encryptionKeys }
        }
    }

    /// Synchronously clears the encryption keys in each managed object context.

    func clearEncryptionKeysInAllContexts() {
        for context in [viewContext, syncContext, searchContext] {
            context.performAndWait { context.encryptionKeys = nil }
        }
    }

    /// Lock the database.

    func lockDatabase() {
        for context in [viewContext, syncContext, searchContext] {
            context.performAndWait { context.databaseKey = nil }
        }
    }

    /// Unlock the database using the given authentication context.

    func unlockDatabase(context: LAContext) throws {
        let keyProvider = EncryptionAtRestKeyProvider(account: account)
        let privateKey = try keyProvider.fetchPrimaryPrivateKey(context: context)

        let encryptedDatabaseKey = try keyProvider.fetchDatabaseKey()
        let decryptedDatabaseKey = try decryptDatabaseKey(
            encryptedDatabaseKey,
            privateKey: privateKey
        )

        let databaseKey = VolatileData(from: decryptedDatabaseKey)

        for context in [viewContext, syncContext, searchContext] {
            context.performAndWait { context.databaseKey = databaseKey }
        }
    }

    private func encryptDatabaseKey(
        _ databaseKey: Data,
        publicKey: SecKey
    ) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let encryptedDatabaseKey = SecKeyCreateEncryptedData(
            publicKey,
            databaseKeyAlgorithm,
            databaseKey as CFData, &error
        ) else {
            let error = error!.takeRetainedValue() as Error
            throw error
        }

        return encryptedDatabaseKey as Data
    }

    private func decryptDatabaseKey(
        _ encryptedDatabaseKey: Data,
        privateKey: SecKey
    ) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let databaseKey = SecKeyCreateDecryptedData(
            privateKey,
            databaseKeyAlgorithm,
            encryptedDatabaseKey as CFData,
            &error
        ) else {
            let error = error!.takeRetainedValue() as Error
            throw error
        }

        return databaseKey as Data
    }

    private var databaseKeyAlgorithm: SecKeyAlgorithm {
        return .eciesEncryptionCofactorX963SHA256AESGCM
    }

}
