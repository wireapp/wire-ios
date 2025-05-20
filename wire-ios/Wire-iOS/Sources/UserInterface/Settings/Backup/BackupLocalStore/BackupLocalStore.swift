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

import CoreData
import WireBackup
import WireDataModel
import WireDomain
import WireFoundation

struct BackupLocalStore<
    UserLocalStore, ConversationLocalStore, MessageLocalStore
>: BackupLocalStoreProtocol, @unchecked Sendable where
    UserLocalStore: UserLocalStoreProtocol,
    MessageLocalStore: MessageLocalStoreProtocol,
    ConversationLocalStore: ConversationLocalStoreProtocol {

    /// The context to call `perform(schedule:_:)` on if needed.
    private let context: NSManagedObjectContext

    private let userLocalStore: UserLocalStore
    private let conversationLocalStore: ConversationLocalStore
    private let messageLocalStore: MessageLocalStore

    func countModels() async throws -> (userCount: Int, conversationCount: Int, messageCount: Int) {
        let userCount = try await userLocalStore.totalUserCountForBackup()
        let conversationCount = try await conversationLocalStore.totalConversationCountForBackup()
        let messageCount = try await messageLocalStore.totalMessageCountForBackup()
        return (userCount, conversationCount, messageCount)
    }

    // MARK: -

    func fetchAllUsers() -> AsyncThrowingStream<UserBackupModel, any Error> {
        AsyncThrowingStream { continuation in
            Task<Void, Never> {
                do {
                    let users = try await userLocalStore.fetchAllUsersForBackup()
                    await context.perform {
                        for user in users {
                            autoreleasepool {
                                if let backupUser = UserBackupModel(user) {
                                    continuation.yield(backupUser)
                                }
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: -

    func fetchAllConversations() -> AsyncThrowingStream<ConversationBackupModel, any Error> {
        AsyncThrowingStream { continuation in
            Task<Void, Never> {
                do {
                    let conversations = try await conversationLocalStore.fetchAllConversationsForBackup()
                    await context.perform {
                        for conversation in conversations {
                            autoreleasepool {
                                if let backupConversation = ConversationBackupModel(conversation) {
                                    continuation.yield(backupConversation)
                                }
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: -

    func fetchAllMessages() -> AsyncThrowingStream<MessageBackupModel, any Error> {
        AsyncThrowingStream { continuation in
            Task<Void, Never> {
                do {
                    let messages = try await messageLocalStore.fetchAllMessagesForBackup()
                    await context.perform {
                        for message in messages {
                            autoreleasepool {
                                if let backupMessage = MessageBackupModel(message) {
                                    continuation.yield(backupMessage)
                                }
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

}

// MARK: -

extension BackupLocalStore where
    UserLocalStore == WireDomain.UserLocalStore,
    ConversationLocalStore == WireDomain.ConversationLocalStore,
    MessageLocalStore == WireDomain.MessageLocalStore {

    init(context: NSManagedObjectContext) {
        self.context = context
        self.messageLocalStore = MessageLocalStore(context: context)
        self.userLocalStore = UserLocalStore(
            context: context,
            messageLocalStore: messageLocalStore
        )
        self.conversationLocalStore = ConversationLocalStore(
            context: context,
            mlsService: context.performAndWait { context.mlsService },
            messageLocalStore: messageLocalStore
        )
    }

}

// MARK: -

private extension UserBackupModel {

    init?(_ user: ZMUser) {
        guard let qualifiedID = user.qualifiedID else { return nil }

        self.init(
            qualifiedID: QualifiedID(qualifiedID),
            name: user.name ?? "",
            handle: user.handle ?? ""
        )
    }

}

private extension ConversationBackupModel {

    init?(_ conversation: ZMConversation) {
        guard let qualifiedID = conversation.qualifiedID else { return nil }

        self.init(
            qualifiedID: QualifiedID(qualifiedID),
            name: conversation.name ?? ""
        )
    }

}
