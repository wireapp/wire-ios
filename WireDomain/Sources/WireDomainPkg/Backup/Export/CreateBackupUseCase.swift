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
    UserAdapter: CreateBackupUserEntityProtocol
>: CreateBackupUseCaseProtocol {

    let context: @Sendable () -> NSManagedObjectContext
    let eventProcessorHandle: any CreateBackupEventProcessorHandleProtocol
    let fileArchiver: any CreateBackupFileArchiverProtocol
    let currentDateProvider: any CurrentDateProviding
    let selfUserID: QualifiedID
    let logger: @Sendable () -> any LoggerProtocol

    public init(
        context: @escaping @autoclosure @Sendable () -> NSManagedObjectContext,
        userAdapterType _: UserAdapter.Type = UserAdapter.self,
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
            let task = Task<Void, Never> { [context, currentDateProvider, eventProcessorHandle, fileArchiver, logger, selfUserID] in
                do {
                    let logger = logger()
                    let context = context()

                    continuation.yield(CreateBackupProgress.progress(0))

                    let workDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent(UUID().uuidString)
                    let outputDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent(UUID().uuidString)

                    logger.debug("initializing MPBackupExporter")
                    let backupExporter = MPBackupExporter(
                        selfUserId: BackupQualifiedId(selfUserID),
                        workDirectory: workDirectoryURL.path(),
                        outputDirectory: outputDirectoryURL.path(),
                        fileZipper: ExportBackupFileZipper2FileZipperAdapter(
                            fileManager: .default,
                            fileArchiver: fileArchiver,
                            currentDateProvider: currentDateProvider
                        )
                    )

                    // finish processing incoming events and then stop
                    await eventProcessorHandle.pauseProcessingEvents()
                    defer { eventProcessorHandle.continueProcessingEvents() }

                    // TODO: [WPB-14592] fetch from CoreData and call these methods:
                    try await context.perform {
                        try Self.exportUsers(from: context, using: backupExporter)
                        // backupExporter.add(message: <#T##BackupMessage#>)
                        // backupExporter.add(conversation: <#T##BackupConversation#>)
                    }

                    // TODO: [WPB-14592] report accurate progress
                    continuation.yield(.progress(0.25))

                    // TODO: [WPB-14592] then finalize:
                    // try await backupExporter.finalize(password: password)

                    // TODO: [WPB-14592] send correct URL
                    continuation.yield(.done(URL(fileURLWithPath: "", isDirectory: false)))
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

    private static func exportUsers(
        from context: NSManagedObjectContext,
        using backupExporter: MPBackupExporter
    ) throws {

        let fetchRequest = UserAdapter.fetchRequest()
        fetchRequest.fetchBatchSize = 50
        let records = try context.fetch(fetchRequest)
        for record in records {
            guard let user = UserAdapter(record) else { continue }
            autoreleasepool {
                let backupUser = BackupUser(
                    id: BackupQualifiedId(user.qualifiedID),
                    name: user.name,
                    handle: user.handle
                )
                backupExporter.add(user: backupUser)
            }
        }

    }

}
