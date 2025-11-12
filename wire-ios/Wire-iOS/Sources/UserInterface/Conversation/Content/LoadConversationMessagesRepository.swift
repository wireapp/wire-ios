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

final class LoadConversationMessagesRepository: NSObject, LoadConversationMessagesRepositoryProtocol,
    MonitorMessagesRepositoryProtocol {

    private let conversationObjectID: NSManagedObjectID
    private let backgroundContext: NSManagedObjectContext
    private let viewContext: NSManagedObjectContext

    private var updatesStreamContinuation: AsyncStream<MessagesUpdate>.Continuation?
    lazy var messagesUpdatesStream: AsyncStream<MessagesUpdate> = {
        let (stream, continuation) = AsyncStream.makeStream(of: MessagesUpdate.self)
        updatesStreamContinuation = continuation
        return stream
    }()

    private var conversation: ZMConversation?

    init(
        conversationObjectID: NSManagedObjectID,
        syncContext: NSManagedObjectContext,
        backgroundContext: NSManagedObjectContext
    ) {
        self.conversationObjectID = conversationObjectID
        self.backgroundContext = backgroundContext
        self.viewContext = syncContext
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave),
            name: .NSManagedObjectContextDidSave,
            object: syncContext
        )
    }

    @objc
    private func contextDidSave(notification: Notification) {
        backgroundContext.perform { [weak self] in
            self?.backgroundContext.mergeChanges(fromContextDidSave: notification)
        }
    }

    private func getConversation() async -> ZMConversation? {
        if let conversation {
            return conversation
        }

        conversation = await backgroundContext.perform { [conversationObjectID, backgroundContext] in
            try? backgroundContext.existingObject(with: conversationObjectID) as? ZMConversation
        }
        return conversation
    }

    var fetchController: NSFetchedResultsController<ZMMessage>?

    func loadMessages(offset: Int, limit: Int) async -> [MessageModel] {
        guard let conversation = await getConversation() else {
            return []
        }

        return await backgroundContext.perform { [unowned self] in
            let fetchRequest = fetchRequest(conversation: conversation)

            // We need to fetch a bit more than requested so that there is overlap between messages in different
            fetchRequest.fetchLimit = limit + 5

            fetchRequest.fetchOffset = offset

            let fetchController = NSFetchedResultsController<ZMMessage>(
                fetchRequest: fetchRequest,
                managedObjectContext: backgroundContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )

            fetchController.delegate = self
            self.fetchController = fetchController

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

extension LoadConversationMessagesRepository: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // no-op
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for changeType: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        if let message = anObject as? ZMConversationMessage, changeType == .insert {
            /// VoiceOver will output the announcement string from the message
            message.postAnnouncementIfNeeded()
        }

        switch changeType {
        case .insert:
            if let message = anObject as? ZMMessage {
                updatesStreamContinuation?.yield(.inserted(message.toDomain()))
            }
        default:
            break
        }
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange sectionInfo: NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for changeType: NSFetchedResultsChangeType
    ) {
        // no-op
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // no-op
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
            objectID: objectID,
            remoteIdentifier: remoteIdentifier,
            name: name,
            handle: handle
        )
    }
}
