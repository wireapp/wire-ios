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

public import WireFoundation
public import WireLogging

import Foundation
@preconcurrency import KaliumBackup

public struct CreateBackupUseCase<
    BackupLocalStore: BackupLocalStoreProtocol,
    FileArchiver: FileArchiverProtocol
>: CreateBackupUseCaseProtocol {

    private let selfUserID: QualifiedID
    private let selfUserHandle: String?
    private let backupLocalStore: BackupLocalStore
    private let fileArchiver: FileArchiver
    private let currentDateProvider: any CurrentDateProviding
    private let logger: @Sendable () -> any LoggerProtocol

    public init(
        selfUserID: QualifiedID,
        selfUserHandle: String?,
        backupLocalStore: BackupLocalStore,
        fileArchiver: FileArchiver,
        currentDateProvider: any CurrentDateProviding,
        logger: @escaping @autoclosure @Sendable () -> any LoggerProtocol
    ) {
        self.backupLocalStore = backupLocalStore
        self.fileArchiver = fileArchiver
        self.currentDateProvider = currentDateProvider
        self.selfUserID = selfUserID
        self.selfUserHandle = selfUserHandle
        self.logger = logger
    }

    public func invoke(password: String) -> AsyncThrowingStream<CreateBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task<Void, Never> { [
                // swiftlint:disable closure_parameter_position
                currentDateProvider,
                fileArchiver,
                logger,
                selfUserID,
                selfUserHandle
                // swiftlint:enable closure_parameter_position
            ] in

                let workDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)
                let outputDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)

                let fileManager = FileManager.default
                defer { try? fileManager.removeItem(at: workDirectoryURL) }

                do {
                    let logger = logger()
                    let checkCancellationAndReportProgress: (Int, Int) throws -> Void = { current, total in
                        guard current % 50 == 0 || current == total else { return }
                        try Task.checkCancellation()
                        logger.debug("reporting overall process: \(current)/\(total)")
                        continuation.yield(.progress(current, total))
                    }

                    try checkCancellationAndReportProgress(0, 0)

                    logger.debug("initializing backup creator")
                    let backupCreator = BackupCreator(
                        selfUserID: selfUserID,
                        workDirectoryURL: workDirectoryURL,
                        outputDirectoryURL: outputDirectoryURL,
                        fileArchiver: fileArchiver
                    )

                    // get the counts of users, messages and conversations in order to report progress accurately
                    let (userCount, conversationCount, messageCount) = try await backupLocalStore.countModels()
                    let total = userCount + conversationCount + messageCount

                    // fetch the data and pass it into the backup exporter
                    var processedItems = 0
                    for try await user in backupLocalStore.fetchAllUsers() {
                        backupCreator.addUser(user)
                        processedItems += 1
                        try checkCancellationAndReportProgress(processedItems, total)
                    }

                    let conversationProgressOffset = userCount
                    processedItems = 0
                    for try await conversation in backupLocalStore.fetchAllConversations() {
                        backupCreator.addConversation(conversation)
                        processedItems += 1
                        try checkCancellationAndReportProgress(conversationProgressOffset + processedItems, total)
                    }

                    let messageProgressOffset = userCount + conversationCount
                    processedItems = 0
                    for try await message in backupLocalStore.fetchAllMessages() {
                        backupCreator.addMessage(message)
                        processedItems += 1
                        try checkCancellationAndReportProgress(messageProgressOffset + processedItems, total)
                    }

                    // create the file
                    let outputFileURL = try await backupCreator.finalize(password: password)
                    // rename
                    let iso8601Date = Date.ISO8601FormatStyle(timeSeparator: .omitted).format(currentDateProvider.now)
                    let filename = "Wire-" + (selfUserHandle.map { "\($0)-" } ?? "") + "Backup_" + iso8601Date + ".wbu"
                    let finalPath = outputFileURL
                        .deletingLastPathComponent()
                        .appending(path: filename, directoryHint: .notDirectory)
                    try fileManager.moveItem(at: outputFileURL, to: finalPath)

                    continuation.yield(.done(finalPath))
                    continuation.finish()

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
