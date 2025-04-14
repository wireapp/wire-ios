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

public import CoreData
public import WireFoundation
public import WireLogging

@preconcurrency import WireBackup

public struct CreateBackupUseCase<
    UserAdapter: CreateBackupUserEntityProtocol,
    ConversationAdapter: CreateBackupConversationEntityProtocol,
    MessageAdapter: CreateBackupMessageEntityProtocol
>: CreateBackupUseCaseProtocol {

    let context: @Sendable () -> NSManagedObjectContext
    let eventProcessorHandle: any CreateBackupEventProcessorHandleProtocol
    let fileManager: @Sendable () -> FileManager = { .default }
    let selfUserID: QualifiedID
    let fileArchiver: any CreateBackupFileArchiverProtocol
    let currentDateProvider: any CurrentDateProviding
    let logger: @Sendable () -> any LoggerProtocol

    public init(
        context: @escaping @autoclosure @Sendable () -> NSManagedObjectContext,
        userAdapterType _: UserAdapter.Type = UserAdapter.self,
        conversationAdapterType _: ConversationAdapter.Type = ConversationAdapter.self,
        messageAdapterType _: MessageAdapter.Type = MessageAdapter.self,
        eventProcessorHandle: any CreateBackupEventProcessorHandleProtocol,
        fileArchiver: any CreateBackupFileArchiverProtocol,
        currentDateProvider: any CurrentDateProviding,
        selfUserID: QualifiedID,
        logger: @escaping @autoclosure @Sendable () -> any LoggerProtocol
    ) {
        self.context = context
        self.eventProcessorHandle = eventProcessorHandle
        self.fileArchiver = fileArchiver
        self.currentDateProvider = currentDateProvider
        self.selfUserID = selfUserID
        self.logger = logger
    }

    public func invoke(password: String) -> AsyncThrowingStream<CreateBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task<Void, Never> { [context, currentDateProvider, eventProcessorHandle, fileManager, fileArchiver, logger, selfUserID] in

                let fileManager = fileManager()
                let workDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)
                let outputDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)

                do {
                    let logger = logger()
                    let context = context()
                    let reportProgress: (Float) -> Void = { progressValue in
                        logger.debug("reporting overall process: \(progressValue * 100)%")
                        continuation.yield(.progress(progressValue))
                        Thread.sleep(forTimeInterval: 1) // TODO: delete this line
                    }

                    reportProgress(0)
                    logger.debug("initializing MPBackupExporter")
                    let backupExporter = Self.createBackupExporter(
                        selfUserID: selfUserID,
                        workDirectoryURL: workDirectoryURL,
                        outputDirectoryURL: outputDirectoryURL,
                        fileManager: fileManager,
                        fileArchiver: fileArchiver,
                        currentDateProvider: currentDateProvider
                    )

                    try Task.checkCancellation()

                    // finish processing incoming events and then stop
                    logger.debug("pausing event processing")
                    await eventProcessorHandle.pauseProcessingEvents()
                    defer { eventProcessorHandle.continueProcessingEvents() }

                    // get the counts of users, messages and conversations in order to report progress accurately
                    logger.debug("calculating entity counts")
                    let (userCount, messageCount, conversationCount) = try await context.perform {
                        try Self.fetchCounts(in: context)
                    }
                    logger.debug("""
                    userCount: \(userCount), messageCount: \(messageCount), conversationCount: \(conversationCount)
                    """)

                    // fetch the data and pass it into the backup exporter
                    let userProgressOffset = Float()
                    let userProgressMultiplier = Float(userCount) / Float(userCount + messageCount + conversationCount)
                    try await context.perform {
                        try Self.exportUsers(from: context, using: backupExporter) { progress in
                            reportProgress(userProgressOffset + userProgressMultiplier * progress)
                        }
                    }

                    let conversationProgressOffset = Float(userCount)
                    let conversationProgressMultiplier = Float(conversationCount) / Float(userCount + messageCount + conversationCount)
                    try await context.perform {
                        try Self.exportConversations(from: context, using: backupExporter) { progress in
                            reportProgress(conversationProgressOffset + conversationProgressMultiplier * progress)
                        }
                    }

                    let messageProgressOffset = Float(userCount + conversationCount)
                    let messageProgressMultiplier = Float(messageCount) / Float(userCount + messageCount + conversationCount)
                    try await context.perform {
                        try Self.exportMessages(from: context, using: backupExporter) { progress in
                            reportProgress(messageProgressOffset + messageProgressMultiplier * progress)
                        }
                    }

                    let outputFileURL = try await backupExporter.finalize(password: password)
                    continuation.yield(.done(outputFileURL))
                    continuation.finish()

                } catch {
                    try? fileManager.removeItem(at: workDirectoryURL)
                    try? fileManager.removeItem(at: outputDirectoryURL)
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private static func createBackupExporter(
        selfUserID: QualifiedID,
        workDirectoryURL: URL,
        outputDirectoryURL: URL,
        fileManager: FileManager,
        fileArchiver: any CreateBackupFileArchiverProtocol,
        currentDateProvider: any CurrentDateProviding
    ) -> MPBackupExporter {
        MPBackupExporter(
            selfUserId: BackupQualifiedId(selfUserID),
            workDirectory: workDirectoryURL.path(),
            outputDirectory: outputDirectoryURL.path(),
            fileZipper: CreateBackupFileZipper2FileZipperAdapter(
                fileManager: fileManager,
                fileArchiver: fileArchiver,
                currentDateProvider: currentDateProvider
            )
        )
    }

    private static func fetchCounts(
        in context: NSManagedObjectContext
    ) throws -> (userCount: Int, messageCount: Int, conversationCount: Int) {

        let userFetchRequest = UserAdapter.fetchRequest()
        let userCount = try context.count(for: userFetchRequest)

        let conversationFetchRequest = ConversationAdapter.fetchRequest()
        let conversationCount = try context.count(for: conversationFetchRequest)

        let messageFetchRequest = MessageAdapter.fetchRequest()
        let messageCount = try context.count(for: messageFetchRequest)

        return (userCount, conversationCount, messageCount)

    }

    private static func exportUsers(
        from context: NSManagedObjectContext,
        using backupExporter: MPBackupExporter,
        reportingProgress: (Float) -> Void
    ) throws {

        let fetchRequest = UserAdapter.fetchRequest()
        fetchRequest.fetchBatchSize = 50
        let records = try context.fetch(fetchRequest)
        let recordCount = records.count
        for (index, record) in records.enumerated() {
            guard let user = UserAdapter(record) else { continue }
            autoreleasepool {
                let backupUser = BackupUser(
                    id: BackupQualifiedId(user.id),
                    name: user.name,
                    handle: user.handle
                )
                backupExporter.add(user: backupUser)
            }
            if index % 50 == 0 || index == recordCount - 1 {
                try Task.checkCancellation()
                reportingProgress(Float(index + 1) / Float(recordCount))
            }
        }

    }

    private static func exportConversations(
        from context: NSManagedObjectContext,
        using backupExporter: MPBackupExporter,
        reportingProgress: (Float) -> Void
    ) throws {

        let fetchRequest = ConversationAdapter.fetchRequest()
        fetchRequest.fetchBatchSize = 50
        let records = try context.fetch(fetchRequest)
        let recordCount = records.count
        for (index, record) in records.enumerated() {
            guard let conversation = ConversationAdapter(record) else { continue }
            autoreleasepool {
                let backupConversation = BackupConversation(
                    id: BackupQualifiedId(conversation.id),
                    name: conversation.name
                )
                backupExporter.add(conversation: backupConversation)
            }
            if index % 50 == 0 || index == recordCount - 1 {
                try Task.checkCancellation()
                reportingProgress(Float(index + 1) / Float(recordCount))
            }
        }

    }

    private static func exportMessages(
        from context: NSManagedObjectContext,
        using backupExporter: MPBackupExporter,
        reportingProgress: (Float) -> Void
    ) throws {

        let fetchRequest = MessageAdapter.fetchRequest()
        fetchRequest.fetchBatchSize = 50
        let records = try context.fetch(fetchRequest)
        let recordCount = records.count
        for (index, record) in records.enumerated() {
            guard let message = MessageAdapter(record) else {
                continue
            }
            autoreleasepool {
                let backupMessage = BackupMessage(
                    id: message.id,
                    conversationId: BackupQualifiedId(message.conversationID),
                    senderUserId: BackupQualifiedId(message.senderUserID),
                    senderClientId: message.senderClientID,
                    creationDate: BackupDateTime(message.creationDate),
                    content: .from(message.content),
                    webPrimaryKey: nil // TODO: remove
                )
                backupExporter.add(message: backupMessage)
            }
            if index % 50 == 0 || index == recordCount - 1 {
                try Task.checkCancellation()
                reportingProgress(Float(index + 1) / Float(recordCount))
            }
        }

    }

}
