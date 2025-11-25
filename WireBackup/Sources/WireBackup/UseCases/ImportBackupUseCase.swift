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
public import WireUtilitiesPackage

@preconcurrency import KaliumBackup

public struct ImportBackupUseCase: ImportBackupUseCaseProtocol {

    let url: URL
    let selfUserID: QualifiedID
    let backupLocalStore: any BackupLocalStoreProtocol
    let fileUnarchiver: any FileUnarchiverProtocol
    let syncTrigger: @Sendable () -> Void
    let logger: WireTaggedLogger

    public let isImportDestructive = false

    public init(
        url: URL,
        selfUserID: QualifiedID,
        backupLocalStore: any BackupLocalStoreProtocol,
        fileUnarchiver: any FileUnarchiverProtocol,
        syncTrigger: @escaping @Sendable () -> Void,
        logger: WireTaggedLogger = WireLogger.importBackup
    ) {
        self.url = url
        self.selfUserID = selfUserID
        self.backupLocalStore = backupLocalStore
        self.fileUnarchiver = fileUnarchiver
        self.syncTrigger = syncTrigger
        self.logger = logger
    }

    public func invoke(password: String) -> AsyncThrowingStream<ImportBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task<Void, Never> { [fileUnarchiver, logger, selfUserID] in

                let workDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)

                defer {
                    try? FileManager.default.removeItem(at: workDirectoryURL)
                }

                do {
                    let reportProgress: (Int, Int) -> Void = { current, total in
                        let progress = BackupProgress(current, total)
                        logger.debug("reporting overall process: \(progress)")
                        continuation.yield(.progress(progress))
                    }

                    reportProgress(0, 0)

                    logger.debug("initializing MPBackupImporter")
                    let importer = BackupImporter(
                        selfUserID: selfUserID,
                        workDirectoryURL: workDirectoryURL,
                        fileUnarchiver: fileUnarchiver
                    )

                    let peekResult = try await importer.peek(into: url)
                    if password.isEmpty, peekResult.isEncrypted {
                        throw ImportBackupError.passwordRequired
                    }

                    let pagers = try await importer.importBackup(from: url, using: password)
                    let usersPager = pagers.usersPager
                    let messagesPager = pagers.messagesPager
                    var current = 0
                    let total = usersPager.totalPages + messagesPager.totalPages

                    logger.info(
                        "Starting importing users from backup... Pages: \(usersPager.totalPages)",
                        attributes: .safePublic
                    )

                    // users
                    let storedUserIDs = try await backupLocalStore.fetchAllUserIDs()
                    while usersPager.hasMorePages() {
                        logger.info("Importing users page \(current)/\(total)", attributes: .safePublic)
                        let backupUsers = usersPager.nextPage()
                        for current in 0 ..< backupUsers.size {
                            guard
                                let backupUser = backupUsers.get(index: current),
                                let userID = QualifiedID(backupUser.id)
                            else { continue }

                            if !storedUserIDs.contains(userID), let user = UserBackupModel(backupUser) {
                                try await backupLocalStore.addUser(user)
                            }
                        }
                        try Task.checkCancellation()
                        current += 1
                        reportProgress(current, Int(exactly: total) ?? 1)
                    }

                    // conversations
                    // Ignoring conversations in the backup file for now.
                    // Any conversation that has been left or deleted will not be restored from the backup in the first
                    // version. All other conversations where the self-user is participant will already be available.

                    logger.info(
                        "Starting importing messages from backup... Pages: \(messagesPager.totalPages)",
                        attributes: .safePublic
                    )

                    // messages
                    var totalSuccessCount = 0
                    var totalFailureCount = 0
                    let storedMessageIDs = try await backupLocalStore.fetchAllMessageIDs()
                    while messagesPager.hasMorePages() {
                        logger.info("Importing messages page \(current)/\(total)", attributes: .safePublic)

                        // Map messages from kotlin array to swift array,
                        // filtering out messages that already exist in DB
                        let backupMessages = mapBackupMessages(
                            fromPage: messagesPager.nextPage(),
                            storedMessageIDs: storedMessageIDs
                        )

                        do {
                            let result = try await backupLocalStore.addMessages(backupMessages)
                            let successCount = result.rehydrationCount.successCount
                            let failureCount = backupMessages.count - successCount
                            totalSuccessCount += successCount
                            totalFailureCount += failureCount

                            logger.info(
                                "Page (\(current)/\(total)): Imported \(successCount) messages, \(failureCount) failed to import",
                                attributes: .safePublic
                            )

                        } catch {
                            // Catch and log the error but don't stop execution, as we should
                            // still be able to continue importing the other pages
                            logger.warn(
                                "Page (\(current)/\(total)) import error: \(String(describing: error))",
                                attributes: .safePublic
                            )
                        }

                        try Task.checkCancellation()
                        current += 1
                        reportProgress(current, Int(exactly: total) ?? 1)
                    }

                    logger.info(
                        "Imported total of \(totalSuccessCount) messages, \(totalFailureCount) failed to import",
                        attributes: .safePublic
                    )

                    try await backupLocalStore.refreshViewContext()

                    if total > 0 {
                        syncTrigger()
                    }

                    logger.info("Completed backup import", attributes: .safePublic)

                    continuation.yield(.done)
                    continuation.finish()

                } catch BackupImporter.OpenBackupError.incorrectPassword {
                    continuation.finish(throwing: ImportBackupError.incorrectPassword)
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

    private func mapBackupMessages(
        fromPage page: KotlinArray<BackupMessage>,
        storedMessageIDs: Set<UUID>
    ) -> [MessageBackupModel] {
        var backupMessages: [MessageBackupModel] = []

        for current in 0 ..< page.size {
            guard
                let backupMessage = page.get(index: current),
                let backupMessageID = UUID(uuidString: backupMessage.id)
            else { continue }

            if !storedMessageIDs.contains(backupMessageID),
               let message = MessageBackupModel(backupMessage) {
                backupMessages.append(message)
            }
        }

        return backupMessages
    }

}
