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

private let kWorkerID = UUID()

struct UpdateConversationTicket: WorkTicket {
    var id = UUID()
    var workerID: UUID {
        kWorkerID
    }

    var priority: WorkTicketPriority

    var conversationID: WireNetwork.QualifiedID
}

final class SyncConversationsWorker: Worker {
    var id: UUID {
        kWorkerID
    }

    private let repository: ConversationRepositoryProtocol

    public init(repository: ConversationRepositoryProtocol) {
        self.repository = repository
    }

    func performWork(for ticket: UpdateConversationTicket) async throws {
        let qualifiedID = ticket.conversationID

        do {
            WireLogger.conversation.debug(
                "updating conversation",
                attributes: [.conversationId: qualifiedID.id.uuidString],
                .init(ticket)
            )
            try await repository.pullConversation(id: qualifiedID.id, domain: qualifiedID.domain)

        } catch ConversationRepositoryError.conversationNotFound {
            WireLogger.conversation.warn(
                "conversation does not on backend, delete locally",
                attributes: [.conversationId: qualifiedID.id.uuidString],
                .init(ticket)
            )
            try await repository.deleteConversation(id: qualifiedID.id, domain: qualifiedID.domain)

        } catch {
            // giving more context to the error
            WireLogger.conversation.error(
                "error updating conversation from the backend: \(String(describing: error))",
                attributes: [.conversationId: qualifiedID.id.uuidString],
                .init(ticket)
            )
            throw error
        }
    }
}
