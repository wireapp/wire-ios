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
import CoreData
import Foundation

/// Records when the pending MLS proposals of a group must be committed.
///
/// This is deliberately a separate entity rather than an attribute of the conversation. Observers of
/// this entity are only notified when a timer is created, rescheduled or removed, and not whenever
/// an unrelated property of the conversation (read receipts, unread count, name, ...) is saved.

public final class PendingProposalTimer: NSManagedObject {

    /// The name of the associated Core Data entity.

    public static let entityName = "PendingProposalTimer"

    /// The MLS group whose pending proposals must be committed. Unique.

    @NSManaged public var mlsGroupID: Data

    /// The identifier of the conversation backed by the group.

    @NSManaged public var conversationID: UUID

    /// The domain of the conversation, if any.

    @NSManaged public var conversationDomain: String?

    /// The date at which the pending proposals must be committed.

    @NSManaged public var fireDate: Date

    // MARK: - Fetching

    public static func fetchRequest() -> NSFetchRequest<PendingProposalTimer> {
        NSFetchRequest<PendingProposalTimer>(entityName: entityName)
    }

    public static func fetch(
        mlsGroupID: Data,
        in context: NSManagedObjectContext
    ) -> PendingProposalTimer? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "mlsGroupID == %@", mlsGroupID as NSData)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    // MARK: - Updating

    /// Creates the timer of a group, or reschedules it. The date is only written when it changed, so
    /// that observers are not notified needlessly.

    @discardableResult
    public static func schedule(
        mlsGroupID: Data,
        conversationID: UUID,
        conversationDomain: String?,
        fireDate: Date,
        in context: NSManagedObjectContext
    ) -> PendingProposalTimer {
        guard let timer = fetch(mlsGroupID: mlsGroupID, in: context) else {
            let timer = PendingProposalTimer(
                entity: NSEntityDescription.entity(forEntityName: entityName, in: context)!,
                insertInto: context
            )
            timer.mlsGroupID = mlsGroupID
            timer.conversationID = conversationID
            timer.conversationDomain = conversationDomain
            timer.fireDate = fireDate
            return timer
        }

        if timer.conversationID != conversationID { timer.conversationID = conversationID }
        if timer.conversationDomain != conversationDomain { timer.conversationDomain = conversationDomain }
        if timer.fireDate != fireDate { timer.fireDate = fireDate }
        return timer
    }

    /// Removes the timer of a group, if any.

    public static func remove(mlsGroupID: Data, in context: NSManagedObjectContext) {
        if let timer = fetch(mlsGroupID: mlsGroupID, in: context) {
            context.delete(timer)
        }
    }
}
