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

import WireAPI
import WireDataModel
import WireSystem

/// Process conversation delete events.

protocol ConversationDeleteEventProcessorProtocol {

    /// Process a conversation delete event.
    ///
    /// - Parameter event: A conversation delete event.

    func processEvent(_ event: ConversationDeleteEvent) async throws

}

struct ConversationDeleteEventProcessor: ConversationDeleteEventProcessorProtocol {

    enum Error: Swift.Error {
        case failedToDeleteMLSConversation(Swift.Error)
    }

    let repository: any ConversationRepositoryProtocol

    func processEvent(_ event: ConversationDeleteEvent) async throws {
        let id = event.conversationID.uuid
        let domain = event.conversationID.domain

        let conversation = await repository.fetchConversation(
            with: id,
            domain: domain
        )

        guard let conversation else {
            return WireLogger.eventProcessing.warn(
                "Cannot delete a conversation that doesn't exist locally: \(id.safeForLoggingDescription)"
            )
        }

        if conversation.messageProtocol == .mls {
            do {
                try await repository.deleteMLSConversation(with: id, domain: domain)
            } catch {
                throw Error.failedToDeleteMLSConversation(error)
            }
        } else {
            await repository.deleteConversation(with: id, domain: domain)
        }
    }

}
