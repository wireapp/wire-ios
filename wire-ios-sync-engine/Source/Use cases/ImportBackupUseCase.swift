//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireLogging
import WireSystem
import ZipArchive

struct ImportBackupUseCase: ImportBackupUseCaseProtocol {

    var activeUserSession: ZMUserSession
    var dispatchGroup: ZMSDispatchGroup
    var logger: WireLogger = .localStorage

    private let workerQueue = DispatchQueue(label: "import-backup")

    func invoke(url: URL, password: String) async throws {

        let account = activeUserSession.account

        try verifyFileExtension(url)

        let decryptedURL = try await decryptAndUnzipBackup(
            url: url,
            password: password,
            accountID: account.userIdentifier
        )

    }

    private func verifyFileExtension(_ url: URL) throws {
        guard BackupFileExtensions(rawValue: url.pathExtension) != nil else {
            throw BackupError.invalidFileExtension
        }
    }

    private func decryptAndUnzipBackup(url: URL, password: String, accountID: UUID) async throws -> URL {
        logger.debug("coordinated file access at: \(url.absoluteString)")

        let decryptedURL = url
            .deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString)
        let unzippedURL = CoreDataStack.importsDirectory
            .appendingPathComponent(url.deletingPathExtension().lastPathComponent)

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, any Error>) in
            workerQueue.async(group: dispatchGroup) {
                do {

                    guard
                        let inputStream = InputStream(url: url),
                        let outputStream = OutputStream(url: decryptedURL, append: false)
                    else { throw BackupError.unknown }

                    let passphrase = ChaCha20Poly1305.StreamEncryption.Passphrase(password: password, uuid: accountID)
                    try ChaCha20Poly1305.StreamEncryption.decrypt(
                        input: inputStream,
                        output: outputStream,
                        passphrase: passphrase
                    )

                } catch ChaCha20Poly1305.StreamEncryption.EncryptionError.decryptionFailed {
                    continuation.resume(throwing: BackupError.decryptionError)

                } catch ChaCha20Poly1305.StreamEncryption.EncryptionError.keyGenerationFailed {
                    continuation.resume(throwing: BackupError.keyCreationFailed)

                } catch {
                    continuation.resume(throwing: error)
                }

                if SSZipArchive.unzipFile(atPath: decryptedURL.path, toDestination: unzippedURL.path) {
                    continuation.resume(returning: unzippedURL)
                } else {
                    continuation.resume(throwing: BackupError.compressionError)
                }
            }
        }
    }
}

// MARK: -

/// There are some external apps that users can use to transfer backup files, which can modify their attachments and
/// change the underscore with a dash. For this reason, we accept 2 types of file extensions to restore conversations.
private enum BackupFileExtensions: String, CaseIterable {
    case fileExtensionWithUnderscore = "ios_wbu"
    case fileExtensionWithHyphen = "ios-wbu"
}

// MARK: -

private enum BackupError: Error {
//    case notAuthenticated
//    case noActiveAccount
    case compressionError
    case invalidFileExtension
    case keyCreationFailed
    case decryptionError
    case unknown
}
