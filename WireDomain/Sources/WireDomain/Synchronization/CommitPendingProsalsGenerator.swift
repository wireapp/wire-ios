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
import WireData
import WireDataModel
import WireLogging

public final class CommitPendingProposalsGenerator: NSObject, LiveGeneratorProtocol {

    private struct ScheduledCommit {
        let fireDate: Date
        let task: Task<Void, Never>
    }

    private static let logDateStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: true)

    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<PendingProposalTimer>?
    private let repository: ConversationRepositoryProtocol
    private let mlsService: MLSServiceInterface
    private let isMLSGroupBroken: (MLSGroupID) -> Bool
    private var onCommitPendingProposals: (CommitPendingProposalItem) -> Void

    private var scheduledCommits: [Data: ScheduledCommit] = [:]

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
                WireLogger.conversation.error("error fetching pending proposal timers: \(String(describing: error))")
            }

            let timers = fetchedResultsController?.fetchedObjects ?? []
            for timer in timers {
                scheduleCommitIfNeeded(for: timer)
            }
        }
    }

    public func stop() async {
        // Cancel all scheduled commits on the context queue to avoid race conditions
        await context.perform { [self] in
            fetchedResultsController = nil
            for (_, scheduled) in scheduledCommits {
                scheduled.task.cancel()
            }
            scheduledCommits.removeAll()
        }
    }

    private func createFetchedResultsController() -> NSFetchedResultsController<PendingProposalTimer> {
        let request = PendingProposalTimer.fetchRequest()
        request.sortDescriptors = [PendingProposalTimer.fireDateSortDescriptor]
        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }

    private func cancelScheduledCommit(for groupData: Data) {
        scheduledCommits[groupData]?.task.cancel()
        scheduledCommits[groupData] = nil
    }

    private func scheduleCommitIfNeeded(for timer: PendingProposalTimer) {
        let groupData = timer.mlsGroupID
        let mlsGroupID = MLSGroupID(groupData)
        let fireDate = timer.fireDate
        let logAttributes: LogAttributes = [.mlsGroupID: mlsGroupID.safeForLoggingDescription]

        guard
            let conversation = ZMConversation.fetch(with: mlsGroupID, in: context),
            let conversationID = conversation.qualifiedID,
            conversation.isSelfAnActiveMember,
            !isMLSGroupBroken(mlsGroupID)
        else {
            // If the conversation no longer qualifies, cancel any existing schedule.
            cancelScheduledCommit(for: groupData)
            return
        }

        // The timer is only reported as updated when its own date changed, but stay idempotent anyway.
        if let existing = scheduledCommits[groupData], existing.fireDate == fireDate {
            WireLogger.workAgent.debug("pending proposal timer unchanged, skipping", attributes: logAttributes)
            return
        }

        if let existing = scheduledCommits[groupData] {
            WireLogger.workAgent.info(
                "pending proposal timer rescheduled (old: \(existing.fireDate.formatted(Self.logDateStyle)), new: \(fireDate.formatted(Self.logDateStyle)))",
                attributes: logAttributes
            )
        }

        // Reschedule (cancel previous if any)
        cancelScheduledCommit(for: groupData)

        // we create a task that will generate a workItem in time because we don't want to block the WorkAgent from
        // executing other workItems
        let task = Task { [repository, mlsService, onCommitPendingProposals] in

            let delay = fireDate.timeIntervalSinceNow
            if delay > 0 {
                do { try await Task.sleep(for: .seconds(delay)) } catch { return } // cancelled
            }

            // Re-check membership right before enqueuing the actual work item
            let stillMember = await repository.isSelfAnActiveMember(in: conversationID)
            guard stillMember else { return }

            // Enqueue parent group item
            onCommitPendingProposals(
                CommitPendingProposalItem(
                    repository: repository,
                    conversationID: conversationID,
                    groupID: mlsGroupID,
                    isSubconversation: false,
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
                        isSubconversation: true,
                        mlsService: mlsService
                    )
                )
            }
        }

        scheduledCommits[groupData] = ScheduledCommit(fireDate: fireDate, task: task)

        WireLogger.workAgent.debug("scheduled commit pending proposal work-item", attributes: logAttributes)
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
        guard let timer = anObject as? PendingProposalTimer else {
            fatal("unexpected object, expected PendingProposalTimer")
        }

        switch type {
        case .insert, .update, .move:
            // `.move` is reported when a changed `fireDate` reorders the results sorted by it.
            scheduleCommitIfNeeded(for: timer)

        case .delete:
            cancelScheduledCommit(for: timer.mlsGroupID)

        @unknown default:
            break
        }
    }
}
