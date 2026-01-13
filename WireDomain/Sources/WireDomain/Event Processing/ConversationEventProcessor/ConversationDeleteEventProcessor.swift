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

import WireDataModel
import WireNetwork
import WireSystem

struct ConversationDeleteEventProcessor: ConversationDeleteEventProcessorProtocol {

    enum Error: Swift.Error {
        case failedToDeleteConversation(Swift.Error)
    }

    let repository: any ConversationRepositoryProtocol

    func processEvent(_ event: ConversationDeleteEvent) async throws {
        let id = event.conversationID.id
        let domain = event.conversationID.domain

        do {
            try await repository.deleteConversation(
                id: id,
                domain: domain
            )
        } catch {
            throw Error.failedToDeleteConversation(error)
        }
    }

}
