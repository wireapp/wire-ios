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

public struct ImportBackupUseCase<
    UserStore: UserStoreProtocol,
    ConversationStore: ConversationStoreProtocol,
    MessageStore: MessageStoreProtocol,
    FileUnarchiver: FileUnarchiverProtocol
>: ImportBackupUseCaseProtocol {

    let selfUserID: QualifiedID
    let userStore: UserStore
    let conversationStore: ConversationStore
    let messageStore: MessageStore
    let fileUnarchiver: FileUnarchiver
    let syncTrigger: @Sendable () -> Void
    let logger: @Sendable () -> any LoggerProtocol

    public init(
        selfUserID: QualifiedID,
        userStore: UserStore,
        conversationStore: ConversationStore,
        messageStore: MessageStore,
        fileUnarchiver: FileUnarchiver,
        syncTrigger: @escaping @Sendable () -> Void,
        logger: @escaping @autoclosure @Sendable () -> any LoggerProtocol
    ) {
        self.selfUserID = selfUserID
        self.userStore = userStore
        self.conversationStore = conversationStore
        self.messageStore = messageStore
        self.fileUnarchiver = fileUnarchiver
        self.syncTrigger = syncTrigger
        self.logger = logger
    }

    public func invoke(url: URL, password: String) -> AsyncThrowingStream<ImportBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task<Void, Never> { [fileUnarchiver, logger, selfUserID] in

                let workDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString)

                defer {
                    try? FileManager.default.removeItem(at: workDirectoryURL)
                }

                do {
                    let logger = logger()
                    let reportProgress: (Int, Int) -> Void = { current, total in
                        guard current % 50 == 0 || current == total else { return }
                        logger.debug("reporting overall process: \(current)/\(total)")
                        continuation.yield(.progress(current, total))
                    }

                    reportProgress(0, 0)
                    logger.debug("initializing MPBackupImporter")
                    let importer = BackupImporter(
                        selfUserID: selfUserID,
                        workDirectoryURL: workDirectoryURL,
                        fileUnarchiver: fileUnarchiver
                    )

                    try Task.checkCancellation()

                    let peekResult = try await importer.peek(into: url)
                    if password.isEmpty, peekResult.isEncrypted {
                        throw ImportBackupError.passwordRequired
                    }

                    try Task.checkCancellation()

                    let pagers = try await importer.importBackup(from: url, using: password)
                    let total = Int(exactly: pagers.totalPagesCount) ?? 0

                    let storedUserIDs = try await userStore.fetchAllUserIDs()
                    let usersPager = pagers.usersPager
                    while usersPager.hasMorePages() {
                        let backupUsers = usersPager.nextPage()
                        for current in 0 ..< backupUsers.size {
                            guard
                                let backupUser = backupUsers.get(index: current),
                                let userID = QualifiedID(backupUser.id)
                            else { continue }

                            if !storedUserIDs.contains(userID) {
                                let user = BackupUserModel(
                                    id: userID,
                                    name: backupUser.name,
                                    handle: backupUser.handle
                                )
                                try await userStore.addUser(user)
                            }

                            if current % 50 == 0 || current == backupUsers.size - 1 {
                                try Task.checkCancellation()
                                reportProgress(Int(exactly: current) ?? 0, total)
                            }
                        }
                    }

                    let storedConversationIDs = try await conversationStore.fetchAllConversationIDs()
                    let conversationsPager = pagers.conversationsPager
                    while conversationsPager.hasMorePages() {
                        let backupConversations = conversationsPager.nextPage()
                        for current in 0 ..< backupConversations.size {
                            guard
                                let backupConversation = backupConversations.get(index: current),
                                let conversationID = QualifiedID(backupConversation.id)
                            else { continue }

                            if !storedConversationIDs.contains(conversationID) {
                                let conversation = BackupConversationModel(
                                    id: conversationID,
                                    name: backupConversation.name
                                )
                                try await conversationStore.addConversation(conversation)
                            }

                            if current % 50 == 0 || current == backupConversations.size - 1 {
                                try Task.checkCancellation()
                                reportProgress(Int(exactly: current) ?? 0, total)
                            }
                        }
                    }

                    let storedMessageIDs = try await messageStore.fetchAllMessageIDs()
                    let messagesPager = pagers.messagesPager
                    while messagesPager.hasMorePages() {
                        let backupMessages = messagesPager.nextPage()
                        for current in 0 ..< backupMessages.size {
                            guard
                                let backupMessage = backupMessages.get(index: current),
                                let conversationID = QualifiedID(backupMessage.conversationId),
                                let senderUserID = QualifiedID(backupMessage.senderUserId),
                                let content = WireBackup.MessageContent(backupMessage.content)
                            else { continue }

                            if !storedMessageIDs
                                .contains(backupMessage.id) {
                                let message = BackupMessageModel(
                                    id: backupMessage.id,
                                    conversationID: conversationID,
                                    senderUserID: senderUserID,
                                    senderClientID: backupMessage.senderClientId,
                                    creationDate: Date(backupMessage.creationDate),
                                    content: content
                                )
                                try await messageStore.addMessage(message)
                            }

                            if current % 50 == 0 || current == backupMessages.size - 1 {
                                try Task.checkCancellation()
                                reportProgress(Int(exactly: current) ?? 0, total)
                            }
                        }
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
