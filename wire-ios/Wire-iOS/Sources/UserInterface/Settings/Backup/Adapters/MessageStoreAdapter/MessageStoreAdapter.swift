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
import Foundation
import WireAPI
import WireBackup
import WireDataModel
import WireDomain
import WireFoundation
import WireProtos

struct MessageStoreAdapter<MessageLocalStore>: MessageStoreProtocol, @unchecked Sendable
    where MessageLocalStore: MessageLocalStoreProtocol {
    typealias QualifiedID = WireFoundation.QualifiedID

    /// The context to call `perform(schedule:_:)` on if needed.
    private let context: NSManagedObjectContext
    private let messageLocalStore: MessageLocalStore

    private let processor: any ConversationProtobufMessageProcessorProtocol

    func totalMessageCount() async throws -> Int {
        try await messageLocalStore.totalMessageCountForBackup()
    }

    func fetchAllMessageIDs() async throws -> [BackupMessageModel.ID] {
        try await messageLocalStore.fetchAllMessageIDsForBackup().map(\.uuidString)
    }

    func fetchAllMessages() async throws -> [BackupMessageModel] {
        let messages = try await messageLocalStore.fetchAllMessagesForBackup()
        return await context.perform {
            messages.compactMap { message in
                if let message = BackupMessageModel(message) { message } else { nil }
            }
        }
    }

    func addMessage(_ backupMessage: BackupMessageModel) async throws {
        let conversationID = backupMessage.conversationID
        let conversation = await context.perform {
            ZMConversation.fetch(with: conversationID.id, domain: conversationID.domain, in: context)
        }
        guard
            let conversation,
            let nonce = UUID(transportString: backupMessage.id),
            let genericMessage = GenericMessage(nonce: nonce, messageContent: backupMessage.content)
        else { return }

        try await processor.processProtobufMessage(
            genericMessage,
            content: genericMessage.content!,
            conversation: conversation,
            conversationID: WireAPI.QualifiedID(conversationID),
            senderID: WireAPI.QualifiedID(backupMessage.senderUserID),
            senderClientID: backupMessage.senderClientID,
            date: backupMessage.creationDate,
            eventMessage: ""
        )
    }

}

extension MessageStoreAdapter where MessageLocalStore == WireDomain.MessageLocalStore {

    init(context: NSManagedObjectContext) {
        self.context = context
        self.messageLocalStore = MessageLocalStore(context: context)

        self.processor = TEMP_ConversationProtobufMessageProcessor(
            context: context,
            mlsService: context.performAndWait { context.mlsService },
            userDefaults: .standard
        )
    }

}
