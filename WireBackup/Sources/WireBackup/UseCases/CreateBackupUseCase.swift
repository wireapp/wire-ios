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

@preconcurrency import KaliumBackup

public struct CreateBackupUseCase<
    UserStore: UserStoreProtocol,
    ConversationStore: ConversationStoreProtocol,
    MessageStore: MessageStoreProtocol,
    FileArchiver: FileArchiverProtocol
>: CreateBackupUseCaseProtocol {

    typealias UserEntity = UserStore.UserEntity
    typealias ConversationEntity = ConversationStore.ConversationEntity

    let userStore: UserStore
    let conversationStore: ConversationStore
    let messageStore: MessageStore

    let eventProcessorHandle: any InterruptEventProcessingProtocol
    let selfUserID: QualifiedID
    let selfUserHandle: String?
    let fileArchiver: FileArchiver
    let currentDateProvider: any CurrentDateProviding
    let logger: @Sendable () -> any LoggerProtocol

    public init(
        userStore: UserStore,
        conversationStore: ConversationStore,
        messageStore: MessageStore,
        eventProcessorHandle: any InterruptEventProcessingProtocol,
        fileArchiver: FileArchiver,
        currentDateProvider: any CurrentDateProviding,
        selfUserID: QualifiedID,
        selfUserHandle: String?,
        logger: @escaping @autoclosure @Sendable () -> any LoggerProtocol
    ) {
        self.userStore = userStore
        self.conversationStore = conversationStore
        self.messageStore = messageStore
        self.eventProcessorHandle = eventProcessorHandle
        self.fileArchiver = fileArchiver
        self.currentDateProvider = currentDateProvider
        self.selfUserID = selfUserID
        self.selfUserHandle = selfUserHandle
        self.logger = logger
    }

    public func invoke(password: String) -> AsyncThrowingStream<CreateBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task<Void, Never> { [
                userStore,
                conversationStore,
                messageStore,
                currentDateProvider,
                eventProcessorHandle,
                fileArchiver,
                logger,
                selfUserID,
                selfUserHandle
            ] in

                let workDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)
                let outputDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)

                let fileManager = FileManager.default
                defer { try? fileManager.removeItem(at: workDirectoryURL) }

                do {
                    let logger = logger()
                    let reportProgress: (Int, Int) -> Void = { current, total in
                        guard current % 50 == 0 || current == total else { return } // debounce
                        logger.debug("reporting overall process: \(current)/\(total)")
                        continuation.yield(.progress(current, total))
                    }

                    reportProgress(0, 0)

                    logger.debug("initializing backup creator")
                    let backupCreator = BackupCreator(
                        selfUserID: selfUserID,
                        workDirectoryURL: workDirectoryURL,
                        outputDirectoryURL: outputDirectoryURL,
                        fileArchiver: fileArchiver
                    )

                    try Task.checkCancellation()

                    // finish processing incoming events and then stop
                    logger.debug("pausing event processing")
                    await eventProcessorHandle.pauseProcessingEvents()
                    defer { eventProcessorHandle.continueProcessingEvents() }

                    // get the counts of users, messages and conversations in order to report progress accurately
                    logger.debug("calculating entity counts")
                    let userCount = try await userStore.totalUserCount()
                    let conversationCount = try await conversationStore.totalConversationCount()
                    let messageCount = try await messageStore.totalMessageCount()
                    let total = userCount + conversationCount + messageCount
                    logger.debug([
                        "userCount: \(userCount)",
                        "conversationCount: \(conversationCount)",
                        "messageCount: \(messageCount)",
                        "total: \(total)"
                    ].joined(separator: ", "))

                    // fetch the data and pass it into the backup exporter
                    let allUsers = try await userStore.fetchAllUsers()
                    for userIndex in 0 ..< allUsers.count {
                        backupCreator.addUser(allUsers[userIndex])
                        if userIndex % 50 == 0 { try Task.checkCancellation() }
                        reportProgress(userIndex + 1, total)
                    }

                    try Task.checkCancellation()

                    let conversationProgressOffset = userCount
                    let allConversations = try await conversationStore.fetchAllConversations()
                    for conversationIndex in 0 ..< allConversations.count {
                        backupCreator.addConversation(allConversations[conversationIndex])
                        if conversationIndex % 50 == 0 { try Task.checkCancellation() }
                        reportProgress(conversationProgressOffset + conversationIndex + 1, total)
                    }

                    try Task.checkCancellation()

                    let messageProgressOffset = userCount + conversationCount
                    let allMessages = try await messageStore.fetchAllMessages()
                    for messageIndex in 0 ..< allMessages.count {
                        backupCreator.addMessage(allMessages[messageIndex])
                        if messageIndex % 50 == 0 { try Task.checkCancellation() }
                        reportProgress(messageProgressOffset + messageIndex + 1, total)
                    }

                    try Task.checkCancellation()

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
