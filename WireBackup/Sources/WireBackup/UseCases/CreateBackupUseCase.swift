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
    UserEntity: UserEntityProtocol,
    ConversationAdapter: ConversationEntityProtocol,
    MessageAdapter: MessageEntityProtocol,
    FileArchiver: FileArchiverProtocol
>: CreateBackupUseCaseProtocol {

    /*
    let context: @Sendable () -> NSManagedObjectContext
     */
    let eventProcessorHandle: any InterruptEventProcessingProtocol
    let selfUserID: QualifiedID
    let selfUserHandle: String?
    let fileArchiver: FileArchiver
    let currentDateProvider: any CurrentDateProviding
    let logger: @Sendable () -> any LoggerProtocol // TODO: make LoggerProtocol Sendable instead of injecting a closure

    public init(
        /*
        context: @escaping @autoclosure @Sendable () -> NSManagedObjectContext,
        userAdapterType _: UserAdapter.Type = UserAdapter.self,
        conversationAdapterType _: ConversationAdapter.Type = ConversationAdapter.self,
        messageAdapterType _: MessageAdapter.Type = MessageAdapter.self,
         */
        eventProcessorHandle: any InterruptEventProcessingProtocol,
        fileArchiver: FileArchiver,
        currentDateProvider: any CurrentDateProviding,
        selfUserID: QualifiedID,
        selfUserHandle: String?,
        logger: @escaping @autoclosure @Sendable () -> any LoggerProtocol
    ) {
//        self.context = context
        self.eventProcessorHandle = eventProcessorHandle
        self.fileArchiver = fileArchiver
        self.currentDateProvider = currentDateProvider
        self.selfUserID = selfUserID
        self.selfUserHandle = selfUserHandle
        self.logger = logger
    }

    public func invoke(password: String) -> AsyncThrowingStream<CreateBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task<Void, Never> { [/*context,*/ currentDateProvider, eventProcessorHandle, fileArchiver, logger, selfUserID, selfUserHandle] in

                let workDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)
                let outputDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)

                let fileManager = FileManager.default
                defer { try? fileManager.removeItem(at: workDirectoryURL) }

                do {
                    let logger = logger()
                    //let context = context()

                    let reportProgress: (Int, Int) -> Void = { current, total in
                        logger.debug("reporting overall process: \(current)/\(total)")
                        continuation.yield(.progress(current, total))
                    }

                    reportProgress(0, 0)
                    logger.debug("initializing backup creator")
                    let exporter = BackupCreator(
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

                    /*
                    // get the counts of users, messages and conversations in order to report progress accurately
                    logger.debug("calculating entity counts")
                    let (userCount, messageCount, conversationCount) = try await context.perform {
                        try Self.fetchCounts(in: context)
                    }
                    let total = userCount + conversationCount + messageCount
                    logger.debug([
                        "userCount: \(userCount)",
                        "conversationCount: \(conversationCount)",
                        "messageCount: \(messageCount)",
                        "total: \(total)"
                    ].joined(separator: ", "))

                    // fetch the data and pass it into the backup exporter
                    try await context.perform {
                        try Self.exportUsers(from: context, using: exporter, reportProgress: { current in
                            reportProgress(current, total)
                        })
                    }

                    let conversationProgressOffset = userCount
                    try await context.perform {
                        try Self.exportConversations(from: context, using: exporter, reportProgress: { current in
                            reportProgress(conversationProgressOffset + current, total)
                        })
                    }

                    let messageProgressOffset = userCount + conversationCount
                    try await context.perform {
                        try Self.exportMessages(from: context, using: exporter, reportProgress: { current in
                            reportProgress(messageProgressOffset + current, total)
                        })
                    }

                    // create the file
                    let outputFileURL = try await exporter.finalize(password: password)
                    // rename
                    let iso8601Date = Date.ISO8601FormatStyle(timeSeparator: .omitted).format(currentDateProvider.now)
                    let filename = "Wire-" + (selfUserHandle.map { "\($0)-" } ?? "") + "Backup_" + iso8601Date + ".wbu"
                    let finalPath = outputFileURL
                        .deletingLastPathComponent()
                        .appending(path: filename, directoryHint: .notDirectory)
                    try fileManager.moveItem(at: outputFileURL, to: finalPath)

                    continuation.yield(.done(finalPath))
                    continuation.finish()

                     */
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

/*
    private static func fetchCounts(
        in context: NSManagedObjectContext
    ) throws -> (userCount: Int, messageCount: Int, conversationCount: Int) {

        let userCount = try context.count(for: UserAdapter.fetchRequest())
        let conversationCount = try context.count(for: ConversationAdapter.fetchRequest())
        let messageCount = try context.count(for: MessageAdapter.fetchRequest())

        return (userCount, conversationCount, messageCount)
    }

    private static func exportUsers(
        from context: NSManagedObjectContext,
        using backupExporter: MPBackupExporter,
        reportProgress: (Int) -> Void
    ) throws {
        try exportRecored(context: context, entityType: UserAdapter.self, export: { user in
            backupExporter.add(
                user: BackupUser(
                    id: BackupQualifiedId(user.id),
                    name: user.name,
                    handle: user.handle
                )
            )
        }, reportProgress: reportProgress)
    }

    private static func exportConversations(
        from context: NSManagedObjectContext,
        using backupExporter: MPBackupExporter,
        reportProgress: (Int) -> Void
    ) throws {
        try exportRecored(context: context, entityType: ConversationAdapter.self, export: { conversation in
            backupExporter.add(
                conversation: BackupConversation(
                    id: BackupQualifiedId(conversation.id),
                    name: conversation.name
                )
            )
        }, reportProgress: reportProgress)
    }

    private static func exportMessages(
        from context: NSManagedObjectContext,
        using backupExporter: MPBackupExporter,
        reportProgress: (Int) -> Void
    ) throws {
        try exportRecored(context: context, entityType: MessageAdapter.self, export: { message in
            backupExporter.add(
                message: BackupMessage(
                    id: message.id,
                    conversationId: BackupQualifiedId(message.conversationID),
                    senderUserId: BackupQualifiedId(message.senderUserID),
                    senderClientId: message.senderClientID ?? "", // TODO: make optional
                    creationDate: BackupDateTime(message.creationDate),
                    content: .from(message.content),
                    webPrimaryKey: nil // TODO: remove
                )
            )
        }, reportProgress: reportProgress)
    }

    private static func exportRecored<Entity: CreateBackupEntityProtocol>(
        context: NSManagedObjectContext,
        entityType: Entity.Type,
        export: (Entity) -> Void,
        reportProgress: (Int) -> Void
    ) throws {

        let fetchRequest = entityType.fetchRequest()
        fetchRequest.fetchBatchSize = 50
        let records = try context.fetch(fetchRequest)
        let recordCount = records.count

        for (index, record) in records.enumerated() {
            guard let entity = entityType.init(record) else { continue }

            autoreleasepool { export(entity) }

            if index % 50 == 0 || index == recordCount - 1 {
                try Task.checkCancellation()
                reportProgress(index + 1)
            }
        }
    */


}
