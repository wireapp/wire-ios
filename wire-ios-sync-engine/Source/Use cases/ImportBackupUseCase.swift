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
import WireSystem

struct ImportBackupUseCase: ImportBackupUseCaseProtocol {

    var activeUserSession: ZMUserSession
    var dispatchGroup: ZMSDispatchGroup

    private let workerQueue = DispatchQueue(label: "import-backup")

    func invoke(url: URL, password: String) async throws {

        let account = activeUserSession.account

        // Verify the imported file has the correct file extension.
        guard BackupFileExtensions(rawValue: url.pathExtension) != nil else {
            throw BackupError.invalidFileExtension
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            workerQueue.async(group: dispatchGroup) { [weak self] in
//                guard let self else {
//                    completion(.failure(NSError(
//                        userSessionErrorCode: .unknownError,
//                        userInfo: ["reason": "SessionManager.self is `nil` in restoreFromBackup"]
//                    )))
//                    return
//                }
//
//                let decryptedURL = SessionManager.temporaryURL(for: location)
//
//                WireLogger.localStorage.debug("coordinated file access at: \(location.absoluteString)")
//
//                do {
//                    try SessionManager.decrypt(
//                        from: location,
//                        to: decryptedURL,
//                        password: password,
//                        accountId: userId
//                    )
//                } catch ChaCha20Poly1305.StreamEncryption.EncryptionError.decryptionFailed {
//                    return complete(.failure(BackupError.decryptionError))
//
//                } catch ChaCha20Poly1305.StreamEncryption.EncryptionError.keyGenerationFailed {
//                    return complete(.failure(BackupError.keyCreationFailed))
//
//                } catch {
//                    return complete(.failure(error))
//                }
//
//                let url = SessionManager.unzippedBackupURL(for: location)
//
//                guard decryptedURL.unzip(to: url) else {
//                    return complete(.failure(BackupError.compressionError))
//                }
//
//                CoreDataStack.importLocalStorage(
//                    accountIdentifier: userId,
//                    from: url,
//                    applicationContainer: sharedContainerURL,
//                    dispatchGroup: dispatchGroup
//                ) { result in
//                    completion(result.map { _ in })
//                }
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
//    case compressionError
    case invalidFileExtension
//    case keyCreationFailed
//    case decryptionError
//    case unknown
}
