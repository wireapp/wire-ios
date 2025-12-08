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

public final class CommitPendingProposalsGenerator: NSObject, LiveGeneratorProtocol {

    private let context: NSManagedObjectContext
    private let fetchedResultsController: NSFetchedResultsController<ZMConversation>
    private let repository: ConversationRepositoryProtocol
    private let mlsService: MLSServiceInterface
    private var onCommitPendingProposals: (CommitPendingProposalItem) -> Void

    init(
        repository: ConversationRepositoryProtocol,
        mlsService: MLSServiceInterface,
        context: NSManagedObjectContext,
        onCommitPendingProposals: @escaping (CommitPendingProposalItem) -> Void
    ) {
        let request = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
        request.predicate = ZMConversation.commitPendingProposalDatePredicate()
        request.sortDescriptors = [ZMConversation.sortCommitPendingProsalsByDateAscending()]
        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        self.context = context
        self.onCommitPendingProposals = onCommitPendingProposals
        self.repository = repository
        self.mlsService = mlsService
        super.init()
    }

    /// Starts monitoring and triggers work for any conversations with commitPendingProposalDate not nil.
    public func start() async {
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            WireLogger.conversation
                .error("error fetching conversations with pending commit proposals: \(String(describing: error))")
        }

        let conversations = fetchedResultsController.fetchedObjects ?? []
        for conversation in conversations {
            await context.perform {
                self.commitPendingProposalItem(for: conversation)
            }
        }
    }

    private func commitPendingProposalItem(for conversation: ZMConversation) {
        if let id = conversation.qualifiedID,
           let timestamp = conversation.commitPendingProposalDate,
           let mlsGroupID = conversation.mlsGroupID,
           conversation.isSelfAnActiveMember {
            // TODO: review skipping brokenGroupIDs
            // there are 2 sources of brokenGroup the journal backed one (currently filled by mls reset groups when FF
            // is disabled
            Task {
                await generateItemForSubconversation(
                    parentID: mlsGroupID,
                    timestamp: timestamp,
                    conversationID: id
                )
            }

            WireLogger.workAgent.debug(
                "generate commit pending proposal work-item",
                attributes: [.mlsGroupID: mlsGroupID.safeForLoggingDescription]
            )
            onCommitPendingProposals(
                CommitPendingProposalItem(
                    repository: repository,
                    conversationID: id,
                    groupID: mlsGroupID,
                    timestamp: timestamp,
                    mlsService: mlsService
                )
            )
        }
    }

    func generateItemForSubconversation(
        parentID: MLSGroupID,
        timestamp: Date,
        conversationID: QualifiedID
    ) async {

        if let subgroupID = await mlsService.subConferenceConversation(
            parentGroupID: parentID
        ) {
            WireLogger.workAgent.debug(
                "generate subconversation commit pending proposal work-item for \(parentID.safeForLoggingDescription)",
                attributes: [.mlsGroupID: subgroupID.safeForLoggingDescription]
            )
            onCommitPendingProposals(
                CommitPendingProposalItem(
                    repository: repository,
                    conversationID: conversationID,
                    groupID: subgroupID,
                    timestamp: timestamp,
                    mlsService: mlsService
                )
            )
        }
    }

    public func stop() {
        fetchedResultsController.delegate = nil
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension CommitPendingProposalsGenerator: NSFetchedResultsControllerDelegate {

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
            commitPendingProposalItem(for: conversation)

        case .update:
            break

        case .move, .delete:
            break

        @unknown default:
            break
        }
    }
}
