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

    func fetchAllUserIDs() async throws -> Set<WireFoundation.QualifiedID> {
        let userIDs = try await userLocalStore.fetchAllUserIDsForBackup()
            .map(WireFoundation.QualifiedID.init)
        return Set(userIDs)
    }

    func fetchAllUsers() async throws -> Set<WireBackup.UserBackupModel> {
        let users = try await userLocalStore.fetchAllUsersForBackup()
        return await context.perform {
            Set(users.compactMap { user in
                guard let user = BackupUserModel(user) else {
                    assertionFailure()
                    return nil
                }
                return user
            })
        }
    }

    // MARK: -

    func fetchAllConversationIDs() async throws -> Set<WireFoundation.QualifiedID> {
        let conversationIDs = try await conversationLocalStore.fetchAllConversationIDsForBackup()
            .map(WireFoundation.QualifiedID.init)
        return Set(conversationIDs)
    }

    func fetchAllConversations() async throws -> Set<WireBackup.ConversationBackupModel> {
        let conversations = try await conversationLocalStore.fetchAllConversationsForBackup()
        return await context.perform {
            Set(conversations.compactMap { conversation in
                guard let conversation = BackupConversationModel(conversation) else {
                    assertionFailure()
                    return nil
                }
                return conversation
            })
        }
    }

    // MARK: -

    func fetchAllMessageIDs() async throws -> Set<WireBackup.BackupMessageModel.ID> {
        let messageIDs = try await messageLocalStore.fetchAllMessageIDsForBackup().map(\.uuidString)
        return Set(messageIDs)
    }

    func fetchAllMessages() async throws -> Set<WireBackup.MessageBackupModel> {
        let messages = try await messageLocalStore.fetchAllMessagesForBackup()
        return await context.perform {
            Set(messages.compactMap { message in
                if let message = BackupMessageModel(message) { message } else { nil }
            })
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

extension BackupUserModel {

    fileprivate init?(_ user: ZMUser) {
        guard let qualifiedID = user.qualifiedID else { return nil }

        self.init(
            id: QualifiedID(qualifiedID),
            name: user.name ?? "",
            handle: user.handle ?? ""
        )
    }

}

extension BackupConversationModel {

    fileprivate init?(_ conversation: ZMConversation) {
        guard let qualifiedID = conversation.qualifiedID else { return nil }

        self.init(
            id: QualifiedID(qualifiedID),
            name: conversation.name ?? ""
        )
    }

}
