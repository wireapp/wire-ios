//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
public import Foundation

// sourcery: AutoMockable
public protocol BackupLocalStoreProtocol: Sendable {

    /// Returns the number of all stored users, conversations and messages in the local data store, including deleted
    /// ones.
    func countModels() async throws -> (userCount: Int, conversationCount: Int, messageCount: Int)

    // MARK: -

    /// Returns the IDs of all users stored in the local database, including deleted ones.
    func fetchAllUserIDs() async throws -> Set<QualifiedID>

    /// Returns all users stored in the local database, including deleted ones.
    func fetchAllUsers() -> AsyncThrowingStream<UserBackupModel, any Error>

    /// Adds a user from the backup file to the local data store.
    func addUser(_ user: UserBackupModel) async throws

    // MARK: -

    /// Returns the IDs of all conversations stored in the local database, including deleted ones.
    func fetchAllConversationIDs() async throws -> Set<QualifiedID>

    /// Returns all conversations stored in the local database, including deleted ones.
    func fetchAllConversations() -> AsyncThrowingStream<ConversationBackupModel, any Error>

    // MARK: -

    /// Returns the IDs of all messages stored in the local database, including deleted ones.
    func fetchAllMessageIDs() async throws -> Set<UUID>

    /// Returns all messages stored in the local database, including deleted ones.
    func fetchAllMessages() -> AsyncThrowingStream<MessageBackupModel, any Error>

    /// Adds a batch of messages from the backup file to the local data store.
    func addMessages(_ backupMessages: [MessageBackupModel]) async throws -> BackupMessagesImportResult

    /// Refreshes the managed objects in the view context
    func refreshViewContext() async throws
}
