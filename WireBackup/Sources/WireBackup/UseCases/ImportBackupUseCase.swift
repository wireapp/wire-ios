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

public import Foundation
public import WireLogging
public import WireFoundation

public struct ImportBackupUseCase<
    BackupLocalStore: BackupLocalStoreProtocol,
    FileUnarchiver: FileUnarchiverProtocol
>: ImportBackupUseCaseProtocol {

    let selfUserID: QualifiedID
    let backupLocalStore: BackupLocalStore
    let fileUnarchiver: FileUnarchiver
    let syncTrigger: @Sendable () -> Void
    let logger: @Sendable () -> any LoggerProtocol

    public init(
        selfUserID: QualifiedID,
        backupLocalStore: BackupLocalStore,
        fileUnarchiver: FileUnarchiver,
        syncTrigger: @escaping @Sendable () -> Void,
        logger: @escaping @autoclosure @Sendable () -> any LoggerProtocol
    ) {
        self.selfUserID = selfUserID
        self.backupLocalStore = backupLocalStore
        self.fileUnarchiver = fileUnarchiver
        self.syncTrigger = syncTrigger
        self.logger = logger
    }

    public func invoke(url: URL, password: String) -> AsyncThrowingStream<ImportBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task<Void, Never> { [fileUnarchiver, logger, selfUserID] in

                let workDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)

                defer {
                    try? FileManager.default.removeItem(at: workDirectoryURL)
                }

                do {
                    let logger = logger()
                    let reportProgress: (Int, Int) -> Void = { current, total in
                        guard current % 50 == 0 || current == total else { return }
                        logger.debug("reporting overall process: \(current)/\(total)")
                        continuation.yield(.progress(current, total))
                    }

                    reportProgress(0, 0)
                    logger.debug("initializing MPBackupImporter")
                    let importer = BackupImporter(
                        selfUserID: selfUserID,
                        workDirectoryURL: workDirectoryURL,
                        fileUnarchiver: fileUnarchiver
                    )

                    try Task.checkCancellation()

                    let peekResult = try await importer.peek(into: url)
                    if password.isEmpty, peekResult.isEncrypted {
                        throw ImportBackupError.passwordRequired
                    }

                    try Task.checkCancellation()

                    let pagers = try await importer.importBackup(from: url, using: password)
                    let total = Int(exactly: pagers.totalPagesCount) ?? 0

                    let storedUserIDs = try await backupLocalStore.fetchAllUserIDs()
                    let usersPager = pagers.usersPager
                    while usersPager.hasMorePages() {
                        let backupUsers = usersPager.nextPage()
                        for current in 0 ..< backupUsers.size {
                            guard
                                let backupUser = backupUsers.get(index: current),
                                let userID = QualifiedID(backupUser.id)
                            else { continue }

                            if !storedUserIDs.contains(userID), let user = BackupUserModel(backupUser) {
                                try await backupLocalStore.addUser(user)
                            }

                            if current % 50 == 0 || current == backupUsers.size - 1 {
                                try Task.checkCancellation()
                                reportProgress(Int(exactly: current) ?? 0, total)
                            }
                        }
                    }

                    // Ignoring conversations in the backup file for now.
                    // Any conversation that has been left or deleted will not be restored from the backup in the first
                    // version. All other conversations where the self-user is participant will already be available.

                    let storedMessageIDs = try await backupLocalStore.fetchAllMessageIDs()
                    let messagesPager = pagers.messagesPager
                    while messagesPager.hasMorePages() {
                        let backupMessages = messagesPager.nextPage()
                        for current in 0 ..< backupMessages.size {
                            guard let backupMessage = backupMessages.get(index: current) else { continue }

                            if !storedMessageIDs.contains(backupMessage.id),
                               let message = BackupMessageModel(backupMessage) {
                                try await backupLocalStore.addMessage(message)
                            }

                            if current % 50 == 0 || current == backupMessages.size - 1 {
                                try Task.checkCancellation()
                                reportProgress(Int(exactly: current) ?? 0, total)
                            }
                        }
                    }

                    syncTrigger()

                    continuation.yield(.done)
                    continuation.finish()

                } catch BackupImporter.OpenBackupError.parsingFailed {
                    continuation.finish(throwing: ImportBackupError.incompatibleFileFormat)
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }

        }
    }

}
