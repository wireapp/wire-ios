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

@preconcurrency import WireBackup

public struct ImportBackupUseCase<
    UserEntity: ImportBackupUserEntityProtocol
//    ConversationAdapter: CreateBackupConversationEntityProtocol,
//    MessageAdapter: CreateBackupMessageEntityProtocol
>: ImportBackupUseCaseProtocol {

    let context: @Sendable () -> NSManagedObjectContext
    let fileManager: @Sendable () -> FileManager = { .default }
    let fileArchiver: any ImportBackupFileArchiverProtocol
    let logger: @Sendable () -> any LoggerProtocol

    public init(
        context: @escaping @autoclosure @Sendable () -> NSManagedObjectContext,
        fileArchiver: any ImportBackupFileArchiverProtocol,
        logger: @escaping @autoclosure @Sendable () -> any LoggerProtocol
    ) {
        self.context = context
        self.fileArchiver = fileArchiver
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

                        // TODO: lazy fetch request

                        while pager.usersPager.hasMorePages() {
                            let users = pager.usersPager.nextPage()
                            for current in 0 ..< users.size {
                                guard let user = users.get(index: current), let userID = QualifiedID(user.id) else {
                                    continue
                                }

                                let userEntity = UserEntity(context: context)
                                userEntity.id = userID
                                userEntity.name = user.name
                                userEntity.handle = user.handle
                                logger.error("TODO: import user \(user)")

                                if current % 50 == 0 || current == users.size - 1 {
                                    try Task.checkCancellation()
                                    reportProgress(Int(exactly: current) ?? 0, total)
                                }
                            }
                        }
                    }

                    try await context.perform {
                        while pager.conversationsPager.hasMorePages() {
                            let conversations = pager.conversationsPager.nextPage()
                            for current in 0 ..< conversations.size {
                                guard let conversation = conversations.get(index: current) else { continue }

                                fatalError("TODO")
                                conversation.id
                                conversation.name
                                logger.error("TODO: import conversation \(conversation)")

                                if current % 50 == 0 || current == conversations.size - 1 {
                                    try Task.checkCancellation()
                                    reportProgress(Int(exactly: current) ?? 0, total)
                                }
                            }
                        }
                    }

                    try await context.perform {
                        while pager.messagesPager.hasMorePages() {
                            let messages = pager.messagesPager.nextPage()
                            for current in 0 ..< messages.size {
                                guard let message = messages.get(index: current) else { continue }

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
                    }

                    try context.save()

                    continuation.yield(.done)
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
