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
import WireDataModel
import WireLogging
import WireNetwork

struct UpdateConversationItem: WorkItem {
    private let repository: ConversationRepositoryProtocol

    var id = UUID()
    var priority: WorkItemPriority {
        .medium
    }

    var conversationID: WireNetwork.QualifiedID

    public init(
        repository: ConversationRepositoryProtocol,
        conversationID: WireNetwork.QualifiedID,
    ) {
        self.repository = repository
        self.conversationID = conversationID
    }

    func start() async throws {
        do {
            WireLogger.conversation.debug(
                "updating conversation",
                attributes: [.conversationId: conversationID.id.uuidString],
                .init(self)
            )
            try await repository.pullConversation(id: conversationID.id, domain: conversationID.domain)

        } catch ConversationRepositoryError.conversationNotFound {
            WireLogger.conversation.warn(
                "conversation does not on backend, delete locally",
                attributes: [.conversationId: conversationID.id.uuidString],
                .init(self)
            )
            try await repository.deleteConversation(id: conversationID.id, domain: conversationID.domain)

        } catch {
            // giving more context to the error
            WireLogger.conversation.error(
                "error updating conversation from the backend: \(String(describing: error))",
                attributes: [.conversationId: conversationID.id.uuidString],
                .init(self)
            )
            throw error
        }

    }

    func cancel() async {
        // do nothing
    }
}
