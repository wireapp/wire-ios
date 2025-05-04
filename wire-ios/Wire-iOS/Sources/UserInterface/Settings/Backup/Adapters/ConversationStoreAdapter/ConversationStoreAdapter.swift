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

import CoreData
import WireBackup
import WireDataModel
import WireDomain
import WireFoundation

struct ConversationStoreAdapter<ConversationLocalStore>: ConversationStoreProtocol, @unchecked Sendable
where ConversationLocalStore: ConversationLocalStoreProtocol {
    typealias QualifiedID = WireFoundation.QualifiedID

    /// The context to call `perform(schedule:_:)` on.
    let context: NSManagedObjectContext
    let conversationLocalStore: ConversationLocalStore

    func totalConversationCount() async throws -> Int {
        try await conversationLocalStore.totalBackupableConversationCount()
    }

    func fetchAllConversationIDs() async throws -> Set<QualifiedID> {
        let conversationIDs = try await conversationLocalStore.fetchAllBackupableConversationIDs()
            .map(WireFoundation.QualifiedID.init)
        return Set(conversationIDs)
    }

    func fetchAllConversations() async throws -> [ConversationEntity] {
        let conversations = try await conversationLocalStore.fetchAllBackupableConversations()
        return await context.perform {
            conversations.compactMap { conversation in
                guard let conversation = ConversationEntity(conversation) else {
                    assertionFailure()
                    return nil
                }
                return conversation
            }
        }
    }

    func addConversation(id: QualifiedID, name: String) async throws {
        let conversation = await conversationLocalStore.fetchOrCreateConversation(
            id: id.id,
            domain: id.domain
        )
        await conversation.managedObjectContext?.perform {
            conversation.userDefinedName = name
        }
        await conversationLocalStore.storeConversation(
            needsBackendUpdate: true,
            conversationID: id.id,
            conversationDomain: id.domain
        )
    }

    // MARK: -

    struct ConversationEntity: ConversationEntityProtocol {

        let id: QualifiedID
        let name: String

        init?(_ conversation: ZMConversation) {
            guard let qualifiedID = conversation.qualifiedID else { return nil }

            self.id = QualifiedID(qualifiedID)
            self.name = conversation.name ?? ""
        }

    }

}

extension ConversationStoreAdapter where ConversationLocalStore == WireDomain.ConversationLocalStore {

    init(context: NSManagedObjectContext) {
        self.context = context
        self.conversationLocalStore = ConversationLocalStore(
            context: context,
            mlsService: context.mlsService,
            messageLocalStore: MessageLocalStore(context: context)
        )
    }

}
