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

        let conversations = try await api.getConversations(for: conversationIDs)

        for conversation in conversations.found {
            await store.storeConversation(
                conversation.toDomainModel(),
                timestamp: .now,
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

        journal[.isConversationSyncRequired] = false
    }

}
