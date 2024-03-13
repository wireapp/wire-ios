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
import WireCryptobox

// sourcery: AutoMockable
public protocol EAREncryptorProtocol {

    func encryptData(
        _ data: Data
    ) throws -> (ciphertext: Data, nonce: Data)

    func decryptData(
        _ data: Data,
        nonce: Data
    ) throws -> Data

}

public enum EAREncryptorError: Error {

    case missingKey
    case missingSalt
    case failedToEncrypt(Error)
    case failedToDecrypt(Error)

}

// TODO: doc comments
public class EAREncryptor: EAREncryptorProtocol {

    var key: VolatileData?
    var salt: Data?

    public init() {
        
    }

    public func encryptData(
        _ data: Data
    ) throws -> (ciphertext: Data, nonce: Data) {
        guard let key else {
            throw EAREncryptorError.missingKey
        }

        guard let salt else {
            throw EAREncryptorError.missingSalt
        }

        do {
            return try ChaCha20Poly1305.AEADEncryption.encrypt(
                message: data,
                context: salt,
                key: key._storage
            )
        } catch {
            throw EAREncryptorError.failedToEncrypt(error)
        }
    }

    public func decryptData(
        _ data: Data,
        nonce: Data
    ) throws -> Data {
        guard let key else {
            throw EAREncryptorError.missingKey
        }

        guard let salt else {
            throw EAREncryptorError.missingSalt
        }

        do {
            return try ChaCha20Poly1305.AEADEncryption.decrypt(
                ciphertext: data,
                nonce: nonce,
                context: salt,
                key: key._storage
            )
        } catch {
            throw EAREncryptorError.failedToEncrypt(error)
        }
    }

}
