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

/// Moves the `commitPendingProposalDate` of conversations into the `PendingProposalTimer` entity introduced in
/// model version 2.143.0, so that proposals pending at the time of the upgrade are still committed.
final class PendingProposalTimerMigrationAction: CoreDataMigrationAction {

    override func execute(in context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
        request.predicate = ZMConversation.commitPendingProposalDatePredicate()
        request.fetchBatchSize = 100

        for conversation in try context.fetch(request) {
            if let date = conversation.commitPendingProposalDate,
               let groupID = conversation.mlsGroupID,
               let conversationID = conversation.remoteIdentifier {
                PendingProposalTimer.schedule(
                    mlsGroupID: groupID.data,
                    conversationID: conversationID,
                    conversationDomain: conversation.domain,
                    fireDate: date,
                    in: context
                )
            }
            conversation.commitPendingProposalDate = nil
        }
    }
}
