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
import Foundation
import WireDataModel
import WireLogging

public final class ConversationUpdatesGenerator: NSObject, IncrementalGeneratorProtocol {

    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<ZMConversation>?
    private let repository: ConversationRepositoryProtocol
    private var onConversationUpdated: (UpdateConversationItem) -> Void

    init(
        repository: ConversationRepositoryProtocol,
        context: NSManagedObjectContext,
        onConversationUpdated: @escaping (UpdateConversationItem) -> Void
    ) {
        self.context = context
        self.onConversationUpdated = onConversationUpdated
        self.repository = repository
        super.init()
    }

    /// Starts monitoring and triggers pulls for any needingToBeUpdatedFromBackend conversations.
    public func start() async {
        if fetchedResultsController == nil {
            fetchedResultsController = createFetchedResultsController()
            fetchedResultsController?.delegate = self
        }

        do {
            try fetchedResultsController?.performFetch()
        } catch {
            WireLogger.conversation.error("error fetching conversations: \(String(describing: error))")
        }

        let conversations = fetchedResultsController?.fetchedObjects ?? []
        for conversation in conversations {
            await context.perform {
                if let id = conversation.qualifiedID {
                    self.onConversationUpdated(UpdateConversationItem(
                        repository: self.repository,
                        conversationID: id.toAPIModel()
                    ))
                }
            }
        }
    }

    public func stop() {
        fetchedResultsController = nil
    }

    private func createFetchedResultsController() -> NSFetchedResultsController<ZMConversation> {
        let request = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
        request.predicate = ZMConversation.predicateForNeedingToBeUpdatedFromBackend()
        request.sortDescriptors = [NSSortDescriptor(key: ZMConversationLastServerTimeStampKey, ascending: true)]
        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension ConversationUpdatesGenerator: NSFetchedResultsControllerDelegate {

    public func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        guard let conversation = anObject as? ZMConversation else {
            fatal("unexpected object, expected ZMConversation")
        }

        switch type {
        case .insert:
            // Insert == flag flipped to true (matches predicate now)
            if let qualifiedID = conversation.qualifiedID {
                onConversationUpdated(UpdateConversationItem(
                    repository: repository,
                    conversationID: qualifiedID.toAPIModel()
                ))
            }

        case .update:
            // Already in the "true" set; we only act on the transition handled by `.insert`.
            break

        case .move, .delete:
            break

        @unknown default:
            break
        }
    }
}
