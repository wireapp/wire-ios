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

@preconcurrency import CoreData
@preconcurrency import WireDataModel
import WireMessagingDomain

final class LoadConversationMessagesRepository: LoadConversationMessagesRepositoryProtocol {

    private let conversationObjectID: NSManagedObjectID
    private let context: NSManagedObjectContext

    private var conversation: ZMConversation?

    init(
        conversationObjectID: NSManagedObjectID,
        context: NSManagedObjectContext
    ) {
        self.conversationObjectID = conversationObjectID
        self.context = context
    }

    private func getConversation() async -> ZMConversation? {
        if let conversation {
            return conversation
        }

        conversation = await context.perform { [conversationObjectID, context] in
            try? context.existingObject(with: conversationObjectID) as? ZMConversation
        }
        return conversation
    }

    func loadMessages(offset: Int, limit: Int) async -> [MessageModel] {
        guard let conversation = await getConversation() else {
            return []
        }

        return await context.perform { [unowned self] in
            let fetchRequest = fetchRequest(conversation: conversation)

            // We need to fetch a bit more than requested so that there is overlap between messages in different
            fetchRequest.fetchLimit = limit + 5

            fetchRequest.fetchOffset = offset

            let fetchController = NSFetchedResultsController<ZMMessage>(
                fetchRequest: fetchRequest,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )

            //        fetchController?.delegate = self
            try! fetchController.performFetch()

            return (fetchController.fetchedObjects ?? [])
                .map { $0.toDomain() }
        }
    }

    private func fetchRequest(conversation: ZMConversation) -> NSFetchRequest<ZMMessage> {
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        fetchRequest.predicate = conversation.visibleMessagesPredicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(ZMMessage.serverTimestamp), ascending: false)]
        return fetchRequest
    }

}

extension ZMMessage {
    func toDomain() -> MessageModel {
        MessageModel(
            sender: sender?.toDomain(),
            kind: getMessageKind()
        )
    }

    func getMessageKind() -> MessageModel.Kind {
        if let textMessageData {
            return .text(TextMessageModel(text: textMessageData.messageText))
        }
        return .text(TextMessageModel(text: "Not supported message type yet"))
    }
}

extension ZMUser {
    func toDomain() -> UserModel {
        UserModel(
            remoteIdentifier: remoteIdentifier,
            name: name,
            handle: handle
        )
    }
}
