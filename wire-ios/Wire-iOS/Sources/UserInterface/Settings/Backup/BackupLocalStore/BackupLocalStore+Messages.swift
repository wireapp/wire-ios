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

extension BackupLocalStore {

    private var messageFetchRequest: NSFetchRequest<any NSFetchRequestResult> {
        let fetchRequest = ZMMessage.fetchRequest()
        fetchRequest.fetchBatchSize = 50
        fetchRequest.returnsObjectsAsFaults = true
        fetchRequest.includesPropertyValues = false
        return fetchRequest
    }

    func fetchAllMessages() -> AsyncThrowingStream<MessageBackupModel, any Error> {
        AsyncThrowingStream { continuation in
            Task<Void, Never> {
                do {
                    try await context.perform {
                        let messages = try context.fetch(messageFetchRequest) as! [ZMMessage]
                        for message in messages {
                            autoreleasepool {
                                if let backupMessage = MessageBackupModel(message) {
                                    continuation.yield(backupMessage)
                                }
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func addMessage(_ backupMessage: MessageBackupModel) async throws {
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
