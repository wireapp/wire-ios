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
import WireAnalytics
import WireCryptobox
import WireDataModel
import WireUtilities
import ZipArchive

extension SessionManager {

    static private let workerQueue = DispatchQueue(label: "history-backup")

    // MARK: - Export

    public enum BackupError: Error {
        case notAuthenticated
        case noActiveAccount
        case compressionError
        case invalidFileExtension
        case keyCreationFailed
        case decryptionError
        case unknown
    }

    public func backupActiveAccount(password: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard
            let userId = accountManager.selectedAccount?.userIdentifier,
            let clientId = activeUserSession?.selfUserClient?.remoteIdentifier,
            let handle = activeUserSession.flatMap(ZMUser.selfUser)?.handle,
            let activeUserSession
        else {
            return completion(.failure(BackupError.noActiveAccount))
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
                    let exportBackupFailed = BackupExportFailedAnalyticsEvent()
                    activeUserSession.analyticsSession?.trackEvent(exportBackupFailed)
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

    // MARK: - Import

    /// Restores the account database from the Wire iOS database back up file.
    /// @param completion called when the restoration is ended. If success, Result.success with the new restored account
    /// is called.
    public func restoreFromBackup(at location: URL, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        func complete(_ result: Result<Void, Error>) {
                DispatchQueue.main.async(group: dispatchGroup) {
                    switch result {
                    case .success:
                        let restoreBackupSucceeded = RestoreBackupAnalyticsEvent(result: .succeeded)
                        self.activeUserSession?.analyticsSession?.trackEvent(restoreBackupSucceeded)
                    case .failure:
                        let restoreBackupFailed = RestoreBackupAnalyticsEvent(result: .failed)
                        self.activeUserSession?.analyticsSession?.trackEvent(restoreBackupFailed)
                    }
                    completion(result)
                }
            }

        guard let userId = unauthenticatedSession?.authenticationStatus.authenticatedUserIdentifier else { return completion(.failure(BackupError.notAuthenticated)) }

        // Verify the imported file has the correct file extension.
        guard BackupFileExtensions.allCases.contains(where: { $0.rawValue == location.pathExtension }) else { return completion(.failure(BackupError.invalidFileExtension)) }

        SessionManager.workerQueue.async(group: dispatchGroup) { [weak self] in
            guard let self else {
                completion(.failure(NSError(userSessionErrorCode: .unknownError, userInfo: ["reason": "SessionManager.self is `nil` in restoreFromBackup"])))
                return
            }

            let decryptedURL = SessionManager.temporaryURL(for: location)

            WireLogger.localStorage.debug("coordinated file access at: \(location.absoluteString)")

            do {
                try SessionManager.decrypt(from: location, to: decryptedURL, password: password, accountId: userId)
            } catch {
                switch error {
                case ChaCha20Poly1305.StreamEncryption.EncryptionError.decryptionFailed:
                    return complete(.failure(BackupError.decryptionError))
                case ChaCha20Poly1305.StreamEncryption.EncryptionError.keyGenerationFailed:
                    return complete(.failure(BackupError.keyCreationFailed))
                default: return complete(.failure(error))
                }
            }

            let url = SessionManager.unzippedBackupURL(for: location)
            guard decryptedURL.unzip(to: url) else { return complete(.failure(BackupError.compressionError)) }
            CoreDataStack.importLocalStorage(
                accountIdentifier: userId,
                from: url,
                applicationContainer: self.sharedContainerURL,
                dispatchGroup: self.dispatchGroup
            ) { result in
                completion(result.map { _ in })
            }
        }
    }

    // MARK: - Encryption & Decryption

    static func encrypt(from input: URL, to output: URL, password: String, accountId: UUID) throws {
        guard let inputStream = InputStream(url: input) else { throw BackupError.unknown }
        guard let outputStream = OutputStream(url: output, append: false) else { throw BackupError.unknown }
        let passphrase = ChaCha20Poly1305.StreamEncryption.Passphrase(password: password, uuid: accountId)
        try ChaCha20Poly1305.StreamEncryption.encrypt(input: inputStream, output: outputStream, passphrase: passphrase)
    }

    static func decrypt(from input: URL, to output: URL, password: String, accountId: UUID) throws {
        guard let inputStream = InputStream(url: input) else { throw BackupError.unknown }
        guard let outputStream = OutputStream(url: output, append: false) else { throw BackupError.unknown }
        let passphrase = ChaCha20Poly1305.StreamEncryption.Passphrase(password: password, uuid: accountId)
        try ChaCha20Poly1305.StreamEncryption.decrypt(input: inputStream, output: outputStream, passphrase: passphrase)
    }

    // MARK: - Helper

    /// Deletes all previously exported and imported backups.
    public func clearPreviousBackups() {
        CoreDataStack.clearBackupDirectory(dispatchGroup: dispatchGroup)
    }

    // MARK: - Static Helpers

    private static func unzippedBackupURL(for url: URL) -> URL {
        let filename = url.deletingPathExtension().lastPathComponent
        return CoreDataStack.importsDirectory.appendingPathComponent(filename)
    }

    private static func compress(backup: CoreDataStack.BackupInfo) throws -> URL {
        let url = temporaryURL(for: backup.url)
        guard backup.url.zipDirectory(to: url) else { throw BackupError.compressionError }
        return url
    }

    private static func targetBackupURL(for backup: CoreDataStack.BackupInfo, handle: String) -> URL {
        let component = backup.metadata.backupFilename(for: handle)
        return backup.url.deletingLastPathComponent().appendingPathComponent(component)
    }

    private static func temporaryURL(for url: URL) -> URL {
        return url.deletingLastPathComponent().appendingPathComponent(UUID().uuidString)
    }
}

// MARK: - Compressed Filename

/// There are some external apps that users can use to transfer backup files, which can modify their attachments and change the underscore with a dash. For this reason, we accept 2 types of file extensions to restore conversations.
private enum BackupFileExtensions: String, CaseIterable {
    case fileExtensionWithUnderscore = "ios_wbu"
    case fileExtensionWithHyphen = "ios-wbu"
}

fileprivate extension BackupMetadata {

    static let nameAppName = "Wire"
    static let nameFileName = "Backup"
    static let fileExtension = BackupFileExtensions.fileExtensionWithUnderscore.rawValue

    private static let formatter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    func backupFilename(for handle: String) -> String {
        return "\(BackupMetadata.nameAppName)-\(handle)-\(BackupMetadata.nameFileName)_\(BackupMetadata.formatter.string(from: creationTime)).\(BackupMetadata.fileExtension)"
    }
}

// MARK: - Zip Helper

extension URL {
    func zipDirectory(to url: URL) -> Bool {
        return SSZipArchive.createZipFile(atPath: url.path, withContentsOfDirectory: path)
    }

    func unzip(to url: URL) -> Bool {
        return SSZipArchive.unzipFile(atPath: path, toDestination: url.path)
    }
}
