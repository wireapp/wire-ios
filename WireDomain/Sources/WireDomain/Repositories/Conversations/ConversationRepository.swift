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
import WireAPI
import WireDataModel

// sourcery: AutoMockable
/// Facilitate access to conversations related domain objects.
public protocol ConversationRepositoryProtocol {

    /// Fetch and persist all conversations

    func pullConversations() async throws

    /// Delete conversations with qualified conversations ids.
    /// - Parameter qualifiedIds: The qualified conversations IDs.

    func deleteConversations(
        withQualifiedIds qualifiedIds: Set<WireAPI.QualifiedID>
    ) async throws

    /// Remove `SelfUser` from the specified conversations IDs.
    /// - Parameter qualifiedIds: The qualified conversations IDs.

    func removeSelfUserFromConversations(
        withQualifiedIds qualifiedIds: Set<WireAPI.QualifiedID>
    ) async throws

    /// Mark specified conversations as fetched.
    /// - Parameter qualifiedIds: The qualified conversations IDs.

    func markConversationsAsFetched(
        qualifiedIds: Set<WireAPI.QualifiedID>
    ) async throws

}

public final class ConversationRepository: ConversationRepositoryProtocol {

    // MARK: - Properties

    private let conversationsAPI: any ConversationsAPI
    private var conversationsLocalStore: any ConversationLocalStoreProtocol
    private let domain: String

    // MARK: - Object lifecycle

    public init(
        conversationsAPI: any ConversationsAPI,
        conversationsLocalStore: any ConversationLocalStoreProtocol,
        domain: String
    ) {
        self.conversationsAPI = conversationsAPI
        self.conversationsLocalStore = conversationsLocalStore
        self.domain = domain
    }

    // MARK: - Public

    public func pullConversations() async throws {
        let result = try await conversationsAPI.getLegacyConversationIdentifiers()
        let uuids = try await result.reduce([UUID](), +)
        let qualifiedIds = uuids.map { WireAPI.QualifiedID(uuid: $0, domain: domain) }
        let conversationList = try await conversationsAPI.getConversations(for: qualifiedIds)

        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            let foundConversations = conversationList.found
            let missingConversations = conversationList.notFound
            let failedConversations = conversationList.failed

            for foundConversation in foundConversations {
                guard let conversationID = foundConversation.id ?? foundConversation.qualifiedID?.uuid else {
                    throw ConversationRepositoryError.conversationIdNotFound
                }

                taskGroup.addTask { [self] in
                    try await conversationsLocalStore.storeConversation(foundConversation, withId: conversationID)
                }
            }

            for missingConversation in missingConversations {
                taskGroup.addTask { [self] in
                    try await conversationsLocalStore.storeNeedsToBeUpdatedFromBackend(
                        requiresUpdate: true,
                        conversation: missingConversation
                    )
                }
            }

            for failedConversation in failedConversations {
                taskGroup.addTask { [self] in
                    try await conversationsLocalStore.storeFailedConversationStatus(failedConversation)
                }
            }
        }
    }

    public func deleteConversations(
        withQualifiedIds qualifiedIds: Set<WireAPI.QualifiedID>
    ) async throws {
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for qualifiedId in qualifiedIds {
                taskGroup.addTask { [self] in
                    try await conversationsLocalStore.deleteConversation(withQualifiedId: qualifiedId)
                }
            }
        }
    }

    public func removeSelfUserFromConversations(
        withQualifiedIds qualifiedIds: Set<WireAPI.QualifiedID>
    ) async throws {
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for qualifiedId in qualifiedIds {
                taskGroup.addTask { [self] in
                    await conversationsLocalStore.removeSelfUserFromConversation(withQualifiedId: qualifiedId)
                }
            }
        }
    }

    public func markConversationsAsFetched(
        qualifiedIds: Set<WireAPI.QualifiedID>
    ) async throws {
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for qualifiedId in qualifiedIds {
                taskGroup.addTask { [self] in
                    await conversationsLocalStore.storeNeedsToBeUpdatedFromBackend(
                        requiresUpdate: false,
                        conversation: qualifiedId
                    )
                }
            }
        }
    }

}
