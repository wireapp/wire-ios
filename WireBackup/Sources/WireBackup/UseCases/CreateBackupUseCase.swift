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

public import WireUtilitiesPackage
public import WireFoundation
public import WireLegacyLogging

import Foundation
@preconcurrency import KaliumBackup

public struct CreateBackupUseCase: CreateBackupUseCaseProtocol {

    private let selfUserID: QualifiedID
    private let backupLocalStore: any BackupLocalStoreProtocol
    private let fileArchiver: any FileArchiverProtocol
    // TODO: [WPB-14297] Try making LoggerProtocol `Sendable` (implementations might be @unchecked Sendable) and
    // then the `logger` can be injected without closure.
    private let logger: @Sendable () -> any LoggerProtocol

    public init(
        selfUserID: QualifiedID,
        backupLocalStore: any BackupLocalStoreProtocol,
        fileArchiver: any FileArchiverProtocol,
        logger: @escaping @autoclosure @Sendable () -> any LoggerProtocol
    ) {
        self.backupLocalStore = backupLocalStore
        self.fileArchiver = fileArchiver
        self.selfUserID = selfUserID
        self.logger = logger
    }

    public func invoke(password: String) -> AsyncThrowingStream<CreateBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task<Void, Never> { [fileArchiver, logger, selfUserID] in

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
                    continuation.yield(.done(outputFileURL))
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
