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

/// sourcery: AutoMockable
public protocol CommitPendingProposalsGeneratorProtocol {
    func start() async
    func stop()
}

public final class CommitPendingProposalsGenerator: NSObject, CommitPendingProposalsGeneratorProtocol {

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
            WireLogger.conversation.error("error fetching conversations with pending commit proposals: \(String(describing: error))")
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
           let mlsGroupID = conversation.mlsGroupID {
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

    // private func sortedGroupsWithPendingCommits() async -> [(MLSGroupID, Date)] {
    //    guard let context else {
    //        return []
    //    }
    //
    //    var result: [(MLSGroupID, Date)] = []
    //
    //    let groupIDsAndProposalDatesArray: [(MLSGroupID, Date)] = await context.perform {
    //        ZMConversation.fetchConversationsWithPendingProposals(
    //            in: context
    //        ).filter(
    //            \.isSelfAnActiveMember
    //        ).compactMap {
    //            guard
    //                let groupID = $0.mlsGroupID,
    //                let proposalDate = $0.commitPendingProposalDate
    //            else {
    //                return nil
    //            }
    //            return (groupID, proposalDate)
    //        }
    //    }
    //
    //    for (groupID, timestamp) in groupIDsAndProposalDatesArray {
    //        // The pending proposal will always fail and cause
    //        // recovery too many recovery syncs.
    //        guard !brokenGroupIDs.contains(groupID) else {
    //            continue
    //        }
    //
    //        result.append((groupID, timestamp))
    //
    //        // The pending proposal might be for the subconversation,
    //        // so include it just in case.
    //        if let subgroupID = await subconversationGroupIDRepository.fetchSubconversationGroupID(
    //            forType: .conference,
    //            parentGroupID: groupID
    //        ) {
    //            result.append((subgroupID, timestamp))
    //        }
    //    }
    //
    //    return result.sorted { lhs, rhs in
    //        let (lhsCommitDate, rhsCommitDate) = (lhs.1, rhs.1)
    //        return lhsCommitDate <= rhsCommitDate
    //    }
    // }
    
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
