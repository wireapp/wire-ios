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
import WireDomainPkg
import ZipArchive

extension SessionManager {

    private static let workerQueue = DispatchQueue(label: "history-backup")

    // MARK: - Export

    public func backupActiveAccount(password: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard
            let userId = accountManager.selectedAccount?.userIdentifier,
            let clientId = activeUserSession?.selfUserClient?.remoteIdentifier,
            let handle = activeUserSession.flatMap(ZMUser.selfUser)?.handle,
            let activeUserSession
        else {
            return completion(.failure(CreateLegacyBackupError.noActiveAccountForExport))
        }

        CoreDataStack.backupLocalStorage(
            accountIdentifier: userId,
            clientIdentifier: clientId,
            applicationContainer: sharedContainerURL,
            dispatchGroup: dispatchGroup,
            databaseKey: activeUserSession.managedObjectContext.databaseKey,
            completion: { [dispatchGroup] result in
                switch result {
                case .success:
                    break
                case .failure:
                    activeUserSession.analyticsEventTracker?.trackEvent(.Backup.exportFailed)
                }

                SessionManager.handle(
                    result: result,
                    password: password,
                    accountId: userId,
                    dispatchGroup: dispatchGroup,
                    completion: completion,
                    handle: handle
                )
            }
        )
    }

    private static func handle(
        result: Result<CoreDataStack.BackupInfo, Error>,
        password: String,
        accountId: UUID,
        dispatchGroup: ZMSDispatchGroup,
        completion: @escaping (Result<URL, Error>) -> Void,
        handle: String
    ) {
        workerQueue.async(group: dispatchGroup) {
            let encrypted = result.flatMap { info in
                do {
                    // 1. Compress the backup
                    let compressed = try compress(backup: info)

                    // 2. Encrypt the backup
                    let url = targetBackupURL(for: info, handle: handle)
                    try encrypt(from: compressed, to: url, password: password, accountId: accountId)
                    return .success(url)
                } catch {
                    return .failure(error)
                }
            }

            DispatchQueue.main.async(group: dispatchGroup) {
                completion(encrypted)
            }
        }
    }

    // MARK: - Encryption

    static func encrypt(from input: URL, to output: URL, password: String, accountId: UUID) throws {
        guard let inputStream = InputStream(url: input)
        else { throw CreateLegacyBackupError.failedToCreateStreamsForEncryption }
        guard let outputStream = OutputStream(url: output, append: false)
        else { throw CreateLegacyBackupError.failedToCreateStreamsForEncryption }
        let passphrase = ChaCha20Poly1305.StreamEncryption.Passphrase(password: password, uuid: accountId)
        try ChaCha20Poly1305.StreamEncryption.encrypt(input: inputStream, output: outputStream, passphrase: passphrase)
    }

    // MARK: - Helper

    /// Deletes all previously exported and imported backups.
    public func clearPreviousBackups() {
        CoreDataStack.clearBackupDirectory(dispatchGroup: dispatchGroup)
    }

    private static func compress(backup: CoreDataStack.BackupInfo) throws -> URL {
        let url = temporaryURL(for: backup.url)
        guard backup.url.zipDirectory(to: url) else { throw CreateLegacyBackupError.compressionError }
        return url
    }

    private static func targetBackupURL(for backup: CoreDataStack.BackupInfo, handle: String) -> URL {
        let component = backup.metadata.backupFilename(for: handle)
        return backup.url.deletingLastPathComponent().appendingPathComponent(component)
    }

    private static func temporaryURL(for url: URL) -> URL {
        url.deletingLastPathComponent().appendingPathComponent(UUID().uuidString)
    }
}

// MARK: - Compressed Filename

/// There are some external apps that users can use to transfer backup files, which can modify their attachments and
/// change the underscore with a dash. For this reason, we accept 2 types of file extensions to restore conversations.
private enum BackupFileExtensions: String, CaseIterable {
    case fileExtensionWithUnderscore = "ios_wbu"
    case fileExtensionWithHyphen = "ios-wbu"
}

private extension BackupMetadata {

    static let nameAppName = "Wire"
    static let nameFileName = "Backup"
    static let fileExtension = BackupFileExtensions.fileExtensionWithUnderscore.rawValue

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    func backupFilename(for handle: String) -> String {
        "\(BackupMetadata.nameAppName)-\(handle)-\(BackupMetadata.nameFileName)_\(BackupMetadata.formatter.string(from: creationTime)).\(BackupMetadata.fileExtension)"
    }
}

// MARK: - Zip Helper

private extension URL {
    func zipDirectory(to url: URL) -> Bool {
        SSZipArchive.createZipFile(atPath: url.path, withContentsOfDirectory: path)
    }
}
