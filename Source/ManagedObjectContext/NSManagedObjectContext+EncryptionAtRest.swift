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
import WireCryptobox

extension NSManagedObjectContext {
    
    enum EncryptionError: LocalizedError {

        case missingDatabaseKey
        case cryptobox(error: ChaCha20Poly1305.AEADEncryption.EncryptionError)

        var errorDescription: String? {
            switch self {
            case .missingDatabaseKey:
                return "Database key not found. Perhaps the database is locked."
            case .cryptobox(let error):
                return error.errorDescription
            }
        }

    }

}

extension NSManagedObjectContext {
    
    public var encryptMessagesAtRest: Bool {
        set {
            setPersistentStoreMetadata(NSNumber(booleanLiteral: newValue),
                                       key: PersistentMetadataKey.encryptMessagesAtRest.rawValue)
        }
        get {
            (persistentStoreMetadata(forKey: PersistentMetadataKey.encryptMessagesAtRest.rawValue) as? NSNumber)?.boolValue ?? false
        }
    }
    
    // MARK: - Encryption / Decryption
    
    func encryptData(data: Data) throws -> (data: Data, nonce: Data) {
        guard let key = encryptionKeys?.databaseKey else { throw EncryptionError.missingDatabaseKey }
        let context = contextData()

        do {
            let (ciphertext, nonce) = try ChaCha20Poly1305.AEADEncryption.encrypt(message: data, context: context, key: key._storage)
            return (ciphertext, nonce)
        } catch let error as ChaCha20Poly1305.AEADEncryption.EncryptionError {
            throw EncryptionError.cryptobox(error: error)
        }

    }
    
    func decryptData(data: Data, nonce: Data) throws -> Data {
        guard let key = encryptionKeys?.databaseKey else { throw EncryptionError.missingDatabaseKey }
        let context = contextData()

        do {
            return try ChaCha20Poly1305.AEADEncryption.decrypt(ciphertext: data, nonce: nonce, context: context, key: key._storage)
        } catch let error as ChaCha20Poly1305.AEADEncryption.EncryptionError {
            throw EncryptionError.cryptobox(error: error)
        }
    }
    
    private func contextData() -> Data {
        let selfUser = ZMUser.selfUser(in: self)

        guard
            let selfClient = selfUser.selfClient(),
            let selfUserId = selfUser.remoteIdentifier?.transportString(),
            let selfClientId = selfClient.remoteIdentifier,
            let context = (selfUserId + selfClientId).data(using: .utf8)
        else {
            fatalError("Could not obtain self user id and self client id")
        }

        return context
    }

    // MARK: - Database Key

    private static let encryptionKeysUserInfoKey = "encryptionKeys"

    public var encryptionKeys: EncryptionKeys? {
        set { userInfo[Self.encryptionKeysUserInfoKey] = newValue }
        get { userInfo[Self.encryptionKeysUserInfoKey] as? EncryptionKeys }
    }

}
