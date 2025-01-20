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

    let userSession: () -> ZMUserSession?
    let dispatchGroup: ZMSDispatchGroup
    let fileArchiver: ImportBackupFileArchiverProtocol
    let entityStorage: ImportBackupEntityStorageProtocol
    let appStateUpdater: ImportBackupAppStateUpdaterProtocol

    let sharedContainerURL: URL
    let logger: WireLogger

    private let workerQueue = DispatchQueue(label: "import-backup")

    func invoke(url: URL, password: String) async throws {

        switch BackupFileExtensions(rawValue: url.pathExtension) {

        case .fileExtensionWithUnderscore, .fileExtensionWithHyphen:
            try await importIOSBackup(url, password)

        case nil:
            throw BackupError.invalidFileExtension
        }
    }

    private func importIOSBackup(_ url: URL, _ password: String) async throws {

        let selfClientBackup: [String : Any]
        let account: Account
        if let userSession = userSession() {

            account = userSession.account

            appStateUpdater.reportImportProgress(progress: 0.5)

            let unzippedURL = try await decryptAndUnzipBackup(
                url: url,
                password: password,
                accountID: userSession.account.userIdentifier
            )

            selfClientBackup = await userSession.managedObjectContext.perform {
                userSession.selfUserClient?.backup() ?? [:]
            }

            await appStateUpdater.reportMigrationNeeded()

            // user session will be destroyed now
            _ = try await entityStorage.replacePersistentStore(
                accountIdentifier: userSession.account.userIdentifier,
                from: unzippedURL,
                applicationContainer: sharedContainerURL,
                dispatchGroup: dispatchGroup
            )

        } else {
            throw BackupError.noActiveAccount
        }

        let temporaryStack = try await entityStorage.contextProvider(
            account: account,
            applicationContainer: sharedContainerURL,
            dispatchGroup: dispatchGroup
        )
        try await temporaryStack.viewContext.perform {
            _ = UserClient.restore(from: selfClientBackup, context: temporaryStack.viewContext)
            try temporaryStack.viewContext.save()
        }

        // TODO: mark A as self client in persistentstore metadata?

        await appStateUpdater.selectAccountAndTriggerSlowSync(account)
    }

    private func decryptAndUnzipBackup(url: URL, password: String, accountID: UUID) async throws -> URL {
        logger.debug("coordinated file access at: \(url.absoluteString)")

        let decryptedURL = url
            .deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString)
        let unzippedURL = CoreDataStack.importsDirectory
            .appendingPathComponent(url.deletingPathExtension().lastPathComponent)

        return try await withCheckedThrowingContinuation { continuation in
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
                    return continuation.resume(throwing: BackupError.decryptionError)

                } catch ChaCha20Poly1305.StreamEncryption.EncryptionError.keyGenerationFailed {
                    return continuation.resume(throwing: BackupError.keyCreationFailed)

                } catch {
                    return continuation.resume(throwing: error)
                }

                if fileArchiver.unzipFile(at: decryptedURL.path, to: unzippedURL.path) {
                    return continuation.resume(returning: unzippedURL)
                } else {
                    return continuation.resume(throwing: BackupError.compressionError)
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
    // TODO: remove if not needed
//    case notAuthenticated
    case noActiveAccount
    case compressionError
    case invalidFileExtension
    case keyCreationFailed
    case decryptionError
    case unknown
}

// MARK: -

private extension UserClient {

    func backup() -> [String: Any] {
        var dict: [String: Any] = [:]
        for key in entity.attributesByName.keys {
            dict[key] = value(forKey: key)
        }
        return dict
    }

    static func restore(from dict: [String: Any], context: NSManagedObjectContext) -> Self {
        let userClient = insertNewObject(in: context)
        for (key, value) in dict {
            userClient.setValue(value, forKey: key)
        }
        return userClient
    }
}
