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
    private var fetchedResultsController: NSFetchedResultsController<ZMConversation>?
    private let repository: ConversationRepositoryProtocol
    private let mlsService: MLSServiceInterface
    private let isMLSGroupBroken: (MLSGroupID) -> Bool
    private var onCommitPendingProposals: (CommitPendingProposalItem) -> Void

    private var scheduledTasks: [QualifiedID: Task<Void, Never>] = [:]

    init(
        repository: ConversationRepositoryProtocol,
        mlsService: MLSServiceInterface,
        context: NSManagedObjectContext,
        isMLSGroupBroken: @escaping (MLSGroupID) -> Bool,
        onCommitPendingProposals: @escaping (CommitPendingProposalItem) -> Void
    ) {
        self.context = context
        self.onCommitPendingProposals = onCommitPendingProposals
        self.repository = repository
        self.mlsService = mlsService
        self.isMLSGroupBroken = isMLSGroupBroken
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
                WireLogger.conversation.error("error fetching conversations: \(String(describing: error))")
            }

            let conversations = fetchedResultsController?.fetchedObjects ?? []
            for conversation in conversations {
                scheduleCommitIfNeeded(for: conversation)
            }
        }
    }

    public func stop() async {
        // Cancel all scheduled commits on the context queue to avoid race conditions
        await context.perform { [self] in
            fetchedResultsController = nil
            for (_, task) in scheduledTasks {
                task.cancel()
            }
            scheduledTasks.removeAll()
        }
    }

    private func createFetchedResultsController() -> NSFetchedResultsController<ZMConversation> {
        let request = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
        request.predicate = ZMConversation.commitPendingProposalDatePredicate()
        request.sortDescriptors = [ZMConversation.sortCommitPendingProsalsByDateAscending()]
        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }

    private func scheduleCommitIfNeeded(for conversation: ZMConversation) {
        guard
            let conversationID = conversation.qualifiedID,
            let timestamp = conversation.commitPendingProposalDate,
            let mlsGroupID = conversation.mlsGroupID,
            conversation.isSelfAnActiveMember,
            !isMLSGroupBroken(mlsGroupID)
        else {
            // If the conversation no longer qualifies, cancel any existing schedule.
            if let id = conversation.qualifiedID {
                scheduledTasks[id]?.cancel()
                scheduledTasks[id] = nil
            }
            return
        }

        // Reschedule (cancel previous if any)
        scheduledTasks[conversationID]?.cancel()

        // we create a task that will generate a workItem in time because we don't want to block the WorkAgent from
        // executing other workItems
        let task = Task { [repository, mlsService, onCommitPendingProposals] in

            let delay = timestamp.timeIntervalSinceNow
            if delay > 0 {
                do { try await Task.sleep(for: .seconds(delay)) } catch { return } // cancelled
            }

            // Re-check membership right before enqueuing the actual work item
            let stillMember = await repository.isSelfAnActiveMember(in: mlsGroupID)
            guard stillMember else { return }

            // Enqueue parent group item
            onCommitPendingProposals(
                CommitPendingProposalItem(
                    repository: repository,
                    conversationID: conversationID,
                    groupID: mlsGroupID,
                    mlsService: mlsService
                )
            )

            // Enqueue subconversation item if any
            if let subgroupID = await mlsService.conferenceSubconversation(parentGroupID: mlsGroupID) {
                onCommitPendingProposals(
                    CommitPendingProposalItem(
                        repository: repository,
                        conversationID: conversationID,
                        groupID: subgroupID,
                        mlsService: mlsService
                    )
                )
            }
        }

        scheduledTasks[conversationID] = task

        WireLogger.workAgent.debug(
            "scheduled commit pending proposal work-item",
            attributes: [.mlsGroupID: mlsGroupID.safeForLoggingDescription]
        )
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
        case .insert, .update:
            scheduleCommitIfNeeded(for: conversation)

        case .move, .delete:
            // Best effort cancel if we can identify it
            if let id = conversation.qualifiedID {
                scheduledTasks[id]?.cancel()
                scheduledTasks[id] = nil
            }

        @unknown default:
            break
        }
    }
}
