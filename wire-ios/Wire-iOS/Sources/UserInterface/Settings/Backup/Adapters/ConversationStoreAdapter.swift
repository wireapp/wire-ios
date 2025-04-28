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

import WireBackup
import WireDataModel
import WireFoundation
import WireDomain

struct ConversationStoreAdapter: ConversationStoreProtocol {

    let conversationLocalStore: any ConversationLocalStoreProtocol

    init(conversationLocalStore: any ConversationLocalStoreProtocol) {
        self.conversationLocalStore = conversationLocalStore
    }

    func totalConversationCount() async throws -> Int {
        try await conversationLocalStore.totalBackupableConversationCount()
    }

    func fetchAllConversations() async throws -> [ConversationEntity] {
        let conversations = try await conversationLocalStore.fetchAllBackupableConversations()
        return await conversationLocalStore.context.perform {
            conversations.compactMap { conversation in
                guard let conversation = ConversationEntity(conversation) else {
                    assertionFailure()
                    return nil
                }
                return conversation
            }
        }
    }

    // MARK: -

    struct ConversationEntity: ConversationEntityProtocol {
        typealias QualifiedID = WireFoundation.QualifiedID

        let id: QualifiedID
        let name: String

        init?(_ conversation: ZMConversation) {
            guard let qualifiedID = conversation.qualifiedID else { return nil }

            id = QualifiedID(qualifiedID)
            name = conversation.name ?? ""
        }

    }

}
