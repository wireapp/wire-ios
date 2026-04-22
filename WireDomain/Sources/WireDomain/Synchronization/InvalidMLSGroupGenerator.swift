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

import Foundation
import WireDataModel
import WireLogging

/// Observes conversations whose MLS group has become invalid and submits a `WipeMLSGroupItem`
/// for each one. Once the group ID is cleared by the work item, the conversation leaves
/// the result set and will not be processed again.
public final class InvalidMLSGroupGenerator: NSObject, IncrementalGeneratorProtocol {

    private let context: NSManagedObjectContext
    private let mlsService: any MLSServiceInterface
    private let conversationLocalStore: any ConversationLocalStoreProtocol
    private var fetchedResultsController: NSFetchedResultsController<ZMConversation>?
    private let onInvalidMLSGroup: (WipeMLSGroupItem) -> Void

    init(
        context: NSManagedObjectContext,
        mlsService: any MLSServiceInterface,
        conversationLocalStore: any ConversationLocalStoreProtocol,
        onInvalidMLSGroup: @escaping (WipeMLSGroupItem) -> Void
    ) {
        self.context = context
        self.mlsService = mlsService
        self.conversationLocalStore = conversationLocalStore
        self.onInvalidMLSGroup = onInvalidMLSGroup
        super.init()
    }

    public func start() async {
        await context.perform { [self] in
            if fetchedResultsController == nil {
                fetchedResultsController = createFetchedResultsController()
                fetchedResultsController?.delegate = self
            }

            do {
                try fetchedResultsController?.performFetch()
            } catch {
                WireLogger.mls.error(
                    "InvalidMLSGroupGenerator: error fetching conversations: \(String(describing: error))"
                )
            }

            let conversations = fetchedResultsController?.fetchedObjects ?? []
            for conversation in conversations {
                submitWorkItem(for: conversation)
            }
        }
    }

    public func stop() async {
        await context.perform { [self] in
            fetchedResultsController = nil
        }
    }

    private func createFetchedResultsController() -> NSFetchedResultsController<ZMConversation> {
        let request = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
        request.predicate = ZMConversation.predicateForInvalidMLSGroup()
        request.sortDescriptors = [NSSortDescriptor(key: ZMConversationLastServerTimeStampKey, ascending: true)]
        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }

    private func submitWorkItem(for conversation: ZMConversation) {
        guard let groupID = conversation.mlsGroupID else { return }
        onInvalidMLSGroup(WipeMLSGroupItem(
            groupID: groupID,
            mlsService: mlsService,
            conversationLocalStore: conversationLocalStore
        ))
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension InvalidMLSGroupGenerator: NSFetchedResultsControllerDelegate {

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
            submitWorkItem(for: conversation)

        case .update, .move, .delete:
            break

        @unknown default:
            break
        }
    }
}
