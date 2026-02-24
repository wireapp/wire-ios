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

public import Foundation

// sourcery: AutoMockable
/// Access to conversations API.
public protocol ConversationsAPI {

    /// Fetch all conversation identifiers in batches for ``APIVersion`` v0.
    func getLegacyConversationIdentifiers() throws -> PayloadPager<[UUID]>

    /// Fetch all conversation identifiers in batches available from ``APIVersion`` v1.
    #if DEBUG
        func getConversationIdentifiers() throws -> PayloadPager<[QualifiedID]>
    #endif

    /// Fetch conversation list with qualified identifiers.
    func getConversations(for identifiers: [QualifiedID]) async throws -> ConversationList

    /// Fetches a user MLS one to one conversation.
    /// - Parameters:
    ///   - userID: The user ID to fetch the MLS one to one conversation for.
    ///   - domain: The domain of the one to one conversation.
    /// - Returns: The 1:1 mls conversation and it's mls public keys (from ``APIVersion`` v6)

    func getMLSOneToOneConversation(
        userID: String,
        in domain: String
    ) async throws -> (Conversation, MLSPublicKeys?)

    /// Fetches the guest link for a given conversation.
    /// - parameter conversationID: The conversation identifier.
    /// - returns: The conversation guest link.

    func getConversationGuestLink(
        conversationID: String
    ) async throws -> String?

    /// Creates a group conversation given provided parameters.
    /// - parameter parameters: API body parameters required to create the group.
    /// - returns: The created group conversation.
    #if DEBUG
        func createGroupConversation(
            parameters: CreateGroupConversationParameters
        ) async throws -> Conversation
    #endif
    /// Add channel permission.
    /// - parameter conversationID: The conversation ID.
    /// - parameter conversationDomain: The conversation domain.
    /// - parameter permission: Channel permission to add (`admins` or `everyone`)
    /// - returns: The updated channel permission.

    @discardableResult
    func addChannelPermission(
        conversationID: String,
        conversationDomain: String,
        permission: ChannelPermission
    ) async throws -> ChannelPermission

    func updateConversationAccess(
        conversationID: QualifiedID,
        allowGuests: Bool,
        allowApps: Bool
    ) async throws

}
