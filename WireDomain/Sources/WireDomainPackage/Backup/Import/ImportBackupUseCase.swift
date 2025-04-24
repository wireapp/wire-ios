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
public import Foundation
public import WireLogging

@preconcurrency import KaliumBackup
import WireFoundation

public struct ImportBackupUseCase<
    UserEntity: ImportBackupUserEntityProtocol,
    ConversationEntity: ImportBackupConversationEntityProtocol,
    MessageEntity: ImportBackupMessageEntityProtocol
>: ImportBackupUseCaseProtocol {

    let context: @Sendable () -> NSManagedObjectContext
    let fileManager: @Sendable () -> FileManager = { .default }
    let fileArchiver: any ImportBackupFileArchiverProtocol
    let syncTrigger: @Sendable () -> Void
    let logger: @Sendable () -> any LoggerProtocol

    public init(
        context: @escaping @autoclosure @Sendable () -> NSManagedObjectContext, // TODO: delete if possible
        fileArchiver: any ImportBackupFileArchiverProtocol,
        syncTrigger: @escaping @Sendable () -> Void,
        logger: @escaping @autoclosure @Sendable () -> any LoggerProtocol
    ) {
        self.context = context
        self.fileArchiver = fileArchiver
        self.syncTrigger = syncTrigger
        self.logger = logger
    }

    public func invoke(url: URL, password: String) -> AsyncThrowingStream<ImportBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task<Void, Never> { [context, fileArchiver] in

                let fileManager = fileManager()
                let workDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)

                defer {
                    try? fileManager.removeItem(at: workDirectoryURL)
                }

                // TODO: disable event processing?

                do {
                    let logger = logger()
                    let context = context()
                    let reportProgress: (Int, Int) -> Void = { current, total in
                        logger.debug("reporting overall process: \(current)/\(total)")
                        continuation.yield(.progress(current, total))
                    }

                    reportProgress(0, 0)
                    logger.debug("initializing MPBackupImporter")
                    let importer = MPBackupImporter(
                        pathToWorkDirectory: workDirectoryURL.path(),
                        backupFileUnzipper: ImportBackupFileArchiverToBackupFileUnzipper(
                            fileManager: fileManager,
                            fileArchiver: fileArchiver
                        )
                    )

                    try Task.checkCancellation()

                    let peekResult = try await importer.peek(into: url)
                    if password.isEmpty, peekResult.isEncrypted {
                        throw ImportBackupError.passwordRequired
                    }

                    try Task.checkCancellation()

                    let pager = try await importer.importBackup(from: url, using: password)
                    let total = Int(exactly: pager.totalPagesCount) ?? 0

                    try await context.perform {

                        let userFetchRequest = UserEntity.fetchRequest()
                        userFetchRequest.propertiesToFetch = ["remoteIdentifier_data", "domain"] // qualified id properties
                        let storedUserIDs = try context.fetch(userFetchRequest)
                            .compactMap(UserEntity.init)
                            .map(\.id)

                        while pager.usersPager.hasMorePages() {
                            let backupUsers = pager.usersPager.nextPage()
                            for current in 0 ..< backupUsers.size {
                                guard
                                    let backupUser = backupUsers.get(index: current),
                                    let userID = QualifiedID(backupUser.id)
                                else { continue }

                                if !storedUserIDs.contains(userID) {
                                    let user = UserEntity.create(id: userID, context: context)
                                    user.name = backupUser.name
                                    user.handle = backupUser.handle
                                }

                                if current % 50 == 0 || current == backupUsers.size - 1 {
                                    try Task.checkCancellation()
                                    reportProgress(Int(exactly: current) ?? 0, total)
                                }
                            }
                        }

                        let conversationFetchRequest = ConversationEntity.fetchRequest()
                        conversationFetchRequest.propertiesToFetch = ["remoteIdentifier_data", "domain"] // qualified id properties
                        let storedConversationIDs = try context.fetch(conversationFetchRequest)
                            .compactMap(ConversationEntity.init)
                            .map(\.id)

                        while pager.conversationsPager.hasMorePages() {
                            let backupConversations = pager.conversationsPager.nextPage()
                            for current in 0 ..< backupConversations.size {
                                guard
                                    let backupConversation = backupConversations.get(index: current),
                                    let conversationID = QualifiedID(backupConversation.id)
                                else { continue }

                                if !storedConversationIDs.contains(conversationID) { // TODO: what if it is in the db but marked as deleted?
                                    let conversation = ConversationEntity.create(id: conversationID, context: context)
                                    conversation.name = backupConversation.name
                                }

                                if current % 50 == 0 || current == backupConversations.size - 1 {
                                    try Task.checkCancellation()
                                    reportProgress(Int(exactly: current) ?? 0, total)
                                }
                            }
                        }

                        /*
                        let storedMessages = try context.fetch(MessageAdapter.fetchRequest())
                            .compactMap(MessageAdapter.init)

                        while pager.messagesPager.hasMorePages() {
                            let messages = pager.messagesPager.nextPage()
                            for current in 0 ..< messages.size {
                                guard let message = messages.get(index: current) else { continue }

                                // if !storedMessages.contains(where: { $0.id == }) {

                                fatalError("TODO")
                                message.id
                                message.conversationId
                                message.content
                                message.creationDate
                                message.senderClientId
                                message.senderUserId
                                logger.error("TODO: import message \(message)")

                                if current % 50 == 0 || current == messages.size - 1 {
                                    try Task.checkCancellation()
                                    reportProgress(Int(exactly: current) ?? 0, total)
                                }
                            }
                        }
                         */

                        try context.save()
                    }

                    syncTrigger()

                    continuation.yield(.done)
                    continuation.finish()

                } catch {
                    // TODO: roll back?
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

}
