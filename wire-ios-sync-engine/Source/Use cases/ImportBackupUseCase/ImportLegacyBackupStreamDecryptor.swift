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
import WireCrypto
import WireDomainPackage

struct ImportLegacyBackupStreamDecryptor: ImportLegacyBackupStreamDecryptorProtocol {

    func decrypt(
        input: InputStream,
        output: OutputStream,
        accountID: UUID,
        password: String
    ) throws {

        do {

            let passphrase = ChaCha20Poly1305.StreamEncryption.Passphrase(
                password: password,
                uuid: accountID
            )

            try ChaCha20Poly1305.StreamEncryption.decrypt(
                input: input,
                output: output,
                passphrase: passphrase
            )

        } catch ChaCha20Poly1305.StreamEncryption.EncryptionError.decryptionFailed {
            if password.isEmpty {
                throw ImportLegacyBackupError.passwordRequired
            } else {
                throw ImportLegacyBackupError.decryptionError
            }

        } catch ChaCha20Poly1305.StreamEncryption.EncryptionError.keyGenerationFailed {
            throw ImportLegacyBackupError.keyCreationFailed
        }

    }

}
