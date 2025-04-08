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
                do {
                    let logger = logger()
                    let context = context()
                    let reportProgress: (Float) -> Void = { progressValue in
                        logger.debug("reporting overall process: \(progressValue * 100)%")
                        continuation.yield(.progress(progressValue))
                    }

                    reportProgress(0)

                    logger.debug("initializing MPBackupExporter")
                    let backupExporter = Self.createBackupExporter(
                        selfUserID: selfUserID,
                        fileManager: fileManager,
                        fileArchiver: fileArchiver,
                        currentDateProvider: currentDateProvider
                    )

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
                    try await context.perform {
                        // backupExporter.add(conversation: <#T##BackupConversation#>)
                    }
                    try await context.perform {
                        // backupExporter.add(message: <#T##BackupMessage#>)
                    }

                    let outputFileURL = try await backupExporter.finalize(password: password)
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

    private static func createBackupExporter(
        selfUserID: QualifiedID,
        fileManager: () -> FileManager,
        fileArchiver: any CreateBackupFileArchiverProtocol,
        currentDateProvider: any CurrentDateProviding
    ) -> MPBackupExporter {

        let fileManager = fileManager()
        let workDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        let outputDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)

        return MPBackupExporter(
            selfUserId: BackupQualifiedId(selfUserID),
            workDirectory: workDirectoryURL.path(),
            outputDirectory: outputDirectoryURL.path(),
            fileZipper: ExportBackupFileZipper2FileZipperAdapter(
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
        let conversationCount = 0

        let messageFetchRequest = MessageAdapter.fetchRequest()
        let messageCount = 0

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
                    id: BackupQualifiedId(user.qualifiedID),
                    name: user.name,
                    handle: user.handle
                )
                backupExporter.add(user: backupUser)
            }
            if index % 100 == 0 || index == recordCount - 1 {
                reportingProgress(Float(index + 1) / Float(recordCount))
            }
        }

    }

}
