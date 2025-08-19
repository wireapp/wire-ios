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
import WireLogging
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
    
    private let batchSize: Int

    private var conversation: ZMConversation?

    init(
        batchSize: Int,
        conversationObjectID: NSManagedObjectID,
        syncContext: NSManagedObjectContext,
        backgroundContext: NSManagedObjectContext
    ) {
        self.batchSize = batchSize
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
    
    private func makeFRC(
        conversation: ZMConversation,
        offset: Int,
        limit: Int
    ) -> NSFetchedResultsController<ZMMessage> {
        let fetchRequest = fetchRequest(conversation: conversation)

        fetchRequest.fetchLimit = limit

        fetchRequest.fetchOffset = offset

        let fetchController = NSFetchedResultsController<ZMMessage>(
            fetchRequest: fetchRequest,
            managedObjectContext: backgroundContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        fetchController.delegate = self

        try! fetchController.performFetch()
        return fetchController
    }

    var fetchController: NSFetchedResultsController<ZMMessage>?
    var hasOlderMessagesToLoad: Bool = true // fix-me: maybe optional
    func loadMessages(offset: Int) async -> [MessageModel] {
        // We need to fetch a bit more than requested so that there is overlap between messages in different
        let limit = batchSize + 5
        guard let conversation = await getConversation() else {
            WireLogger.conversation.error("Failed to fetch conversation to load more messages")
            return []
        }
        
        messagesToMonitorCurrentLimit = limit
        messagesToMonitorCurrentOffset = offset
        
        return await backgroundContext.perform { [unowned self] in
            self.fetchController = makeFRC(
                conversation: conversation,
                offset: offset,
                limit: limit
            )
            let objects = fetchController?.fetchedObjects ?? []
            print("DS: fetchedObjects count \(objects.count), limit: \(limit), hasOlderMessages: \(hasOlderMessagesToLoad)")
            return objects.map { $0.toDomain() }
        }
    }
    
    func loadOlderMessages(lastMessageTimestamp: Date) async -> [MessageModel] {
        print(
            "DS:  repo: load older messages: lastMessageTimestamp: \(lastMessageTimestamp.timeIntervalSince1970)"
        )
        guard let conversation = await getConversation() else {
            WireLogger.conversation.error("Failed to fetch conversation to load more messages")
            return []
        }
        
        do {
            let messages = try await backgroundContext.perform { [backgroundContext, batchSize, unowned self] in
                let fetchRequest = self.olderThenRequest(
                    conversation: conversation,
                    batchSize: batchSize,
                    lastMessageTimestamp: lastMessageTimestamp
                )
                
                let result = try backgroundContext.fetch(fetchRequest)
                return result.map { $0.toDomain() }
            }
            let loadedCount = messages.count
            hasOlderMessagesToLoad = loadedCount == batchSize
            Task { // no need to wait
                await recreatedFRCForUpdates(
                    olderMessagesLoadedCount: loadedCount,
                    conversation: conversation
                )
            }
            return messages
        } catch {
            return []
        }
    }
    
    private var messagesToMonitorCurrentOffset = 0
    private var messagesToMonitorCurrentLimit = 0
    private func recreatedFRCForUpdates(
        olderMessagesLoadedCount: Int,
        conversation: ZMConversation
    ) async {
        return await backgroundContext.perform { [unowned self] in
            
            messagesToMonitorCurrentLimit += olderMessagesLoadedCount
            
            self.fetchController = makeFRC(
                conversation: conversation,
                offset: messagesToMonitorCurrentOffset,
                limit: messagesToMonitorCurrentLimit
            )
        }
    }
    
    private func sortDescriptors() -> [NSSortDescriptor] {
        [NSSortDescriptor(key: #keyPath(ZMMessage.serverTimestamp), ascending: false)]
    }
    
    private func olderThenRequest(
        conversation: ZMConversation,
        batchSize: Int,
        lastMessageTimestamp: Date
    ) -> NSFetchRequest<ZMMessage> {
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        let validMessage = conversation.visibleMessagesPredicate!

        let beforeGivenMessage = NSPredicate(format: "%K < %@", ZMMessageServerTimestampKey, lastMessageTimestamp as NSDate)

        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [validMessage, beforeGivenMessage])
        fetchRequest.sortDescriptors = sortDescriptors()
        fetchRequest.fetchLimit = batchSize
        return fetchRequest
    }

    private func fetchRequest(conversation: ZMConversation) -> NSFetchRequest<ZMMessage> {
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        fetchRequest.predicate = conversation.visibleMessagesPredicate
        fetchRequest.sortDescriptors = sortDescriptors()
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
        print("DS: didChange sectionInfo")
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // no-op
    }
}
