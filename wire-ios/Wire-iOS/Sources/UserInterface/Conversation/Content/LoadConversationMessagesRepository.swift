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

import WireMessagingDomain
import CoreData
@preconcurrency import WireDataModel

final class LoadConversationMessagesRepository: LoadConversationMessagesRepositoryProtocol {
    
    private let conversation: ZMConversation
    
    init(conversation: ZMConversation) {
        self.conversation = conversation
    }
    
    func loadMessages(offset: Int, limit: Int) async -> [MessageModel] {
        
        // FIX ME: use background thread
        await conversation.managedObjectContext!.perform { [unowned self] in
            let fetchRequest = fetchRequest()
            fetchRequest
                .fetchLimit = limit +
                5 // We need to fetch a bit more than requested so that there is overlap between messages in different
            // fetches
            fetchRequest.fetchOffset = offset

            let fetchController = NSFetchedResultsController<ZMMessage>(
                fetchRequest: fetchRequest,
                managedObjectContext: conversation.managedObjectContext!,
                sectionNameKeyPath: nil,
                cacheName: nil
            )

    //        fetchController?.delegate = self
            try! fetchController.performFetch()

            let objects = (fetchController.fetchedObjects ?? [])
                .map { $0.toDomain()}
            return objects
        }
    }
    
    private func fetchRequest() -> NSFetchRequest<ZMMessage> {
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
