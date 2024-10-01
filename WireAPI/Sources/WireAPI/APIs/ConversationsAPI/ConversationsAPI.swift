//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import Foundation

// sourcery: AutoMockable
/// Access to conversations API.
public protocol ConversationsAPI {

    /// Fetch all conversation identifiers in batches for ``APIVersion`` v0.
    func getLegacyConversationIdentifiers() async throws -> PayloadPager<UUID>

    /// Fetch all conversation identifiers in batches available from ``APIVersion`` v1.
    func getConversationIdentifiers() async throws -> PayloadPager<QualifiedID>

    /// Fetch conversation list with qualified identifiers.
    func getConversations(for identifiers: [QualifiedID]) async throws -> ConversationList
    
    /// Fetches a user MLS one to one conversation.
    /// - parameters:
    ///     - userID: The user ID to fetch the MLS one to one conversation for.
    ///     - domain: The domain of the one to one conversation.
    
    func getMLSOneToOneConversation(
        userID: String,
        in domain: String
    ) async throws -> Conversation

}
