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

import Foundation
import WireNetwork

public final class PullAllConversationsSync: PullAllConversationsSyncProtocol {

    private let localDomain: String
    private let isFederationEnabled: Bool
    private let isMLSEnabled: Bool
    private let api: any ConversationsAPI
    private let store: any ConversationLocalStoreProtocol
    private var journal: any JournalProtocol

    public init(
        localDomain: String,
        isFederationEnabled: Bool,
        isMLSEnabled: Bool,
        api: any ConversationsAPI,
        store: any ConversationLocalStoreProtocol,
        journal: any JournalProtocol
    ) {
        self.localDomain = localDomain
        self.isFederationEnabled = isFederationEnabled
        self.isMLSEnabled = isMLSEnabled
        self.api = api
        self.store = store
        self.journal = journal
    }

    public func pull() async throws {
        var conversationIDs = [QualifiedID]()
        do {
            for try await ids in try await api.getConversationIdentifiers() {
                conversationIDs.append(contentsOf: ids)
            }
        } catch ConversationsAPIError.notImplemented {
            // Fallback
            for try await ids in try await api.getLegacyConversationIdentifiers() {
                conversationIDs.append(contentsOf: ids.map {
                    .init(id: $0, domain: localDomain)
                })
            }
        }

        guard !conversationIDs.isEmpty else {
            return
        }

        // We'll fetch the conversations in chunks and let them run in
        // parallel.
        try await withThrowingTaskGroup { group in
            // Backend allows fetching max 1000 at a time.
            let chunks = stride(
                from: conversationIDs.startIndex,
                to: conversationIDs.endIndex,
                by: 1000
            ).map { startIndex in
                let endIndex = min(startIndex + 1000, conversationIDs.endIndex)
                return Array(conversationIDs[startIndex ..< endIndex])
            }

            // Enqueue each task.
            for chunk in chunks {
                group.addTask { [weak self] in
                    try await self?.pullConversations(ids: chunk)
                }
            }

            // Wait for all tasks to complete, if any fail the
            // group will fail.
            while try await group.next() != nil {}
        }

        journal[.isConversationSyncRequired] = false
    }

    private func pullConversations(ids: [QualifiedID]) async throws {
        let conversations = try await api.getConversations(for: ids)

        for conversation in conversations.found {
            await store.storeConversation(
                conversation.toDomainModel(),
                timestamp: Date.distantPast,
                isFederationEnabled: isFederationEnabled,
                isMLSEnabled: isMLSEnabled
            )
        }

        for id in conversations.notFound {
            await store.storeConversation(
                needsBackendUpdate: true,
                conversationID: id.id,
                conversationDomain: id.domain
            )
        }

        for id in conversations.failed {
            await store.storeFailedConversation(
                conversationID: id.id,
                conversationDomain: id.domain
            )
        }
    }

}
