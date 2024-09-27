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

// MARK: - EARKeyEncryptorInterface

// sourcery: AutoMockable
protocol EARKeyEncryptorInterface {
    func encryptDatabaseKey(
        _ databaseKey: Data,
        publicKey: SecKey
    ) throws -> Data

    func decryptDatabaseKey(
        _ encryptedDatabaseKey: Data,
        privateKey: SecKey
    ) throws -> Data
}

// MARK: - EARKeyEncryptor

struct EARKeyEncryptor: EARKeyEncryptorInterface {
    // MARK: Internal

    func encryptDatabaseKey(
        _ databaseKey: Data,
        publicKey: SecKey
    ) throws -> Data {
        var error: Unmanaged<CFError>?
        guard let encryptedDatabaseKey = SecKeyCreateEncryptedData(
            publicKey,
            databaseKeyAlgorithm,
            databaseKey as CFData,
            &error
        ) else {
            let error = error!.takeRetainedValue() as Error
            throw error
        }

        return encryptedDatabaseKey as Data
    }

    func decryptDatabaseKey(
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

    // MARK: Private

    private var databaseKeyAlgorithm: SecKeyAlgorithm {
        .eciesEncryptionCofactorX963SHA256AESGCM
    }
}
