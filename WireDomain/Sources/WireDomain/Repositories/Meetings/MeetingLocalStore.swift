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
import WireDataModel
import WireNetwork

final class MeetingLocalStore: MeetingLocalStoreProtocol {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func storeMeeting(_ meeting: MeetingResponse) async {
        await context.perform { [context] in
            let storedMeeting = Self.fetchOrCreateStoredMeeting(
                id: meeting.id.id,
                domain: meeting.id.domain,
                in: context
            )
            storedMeeting.title = meeting.title
            storedMeeting.start = meeting.startTime
            storedMeeting.end = meeting.endTime
            storedMeeting.recurrenceFrequency = meeting.recurrence?.frequency.toStoredFrequency()
            storedMeeting.recurrenceInterval = Int64(meeting.recurrence?.interval ?? 0)
            storedMeeting.recurrenceUntil = meeting.recurrence?.until
            storedMeeting.conversation = ZMConversation.fetch(
                with: meeting.conversationID.id,
                domain: meeting.conversationID.domain,
                in: context
            )
            storedMeeting.creator = ZMUser.fetch(
                with: meeting.creatorID.id,
                domain: meeting.creatorID.domain,
                in: context
            )
            _ = context.saveOrRollback()
        }
    }

    func deleteMeeting(id: UUID, domain: String) async {
        await context.perform { [context] in
            let request = StoredMeeting.fetchRequest()
            request.predicate = Self.predicate(id: id, domain: domain)
            request.fetchLimit = 1
            guard let storedMeeting = try? context.fetch(request).first else { return }

            context.delete(storedMeeting)
            _ = context.saveOrRollback()
        }
    }

    // MARK: - Private

    private static func fetchOrCreateStoredMeeting(
        id: UUID,
        domain: String,
        in context: NSManagedObjectContext
    ) -> StoredMeeting {
        let request = StoredMeeting.fetchRequest()
        request.predicate = predicate(id: id, domain: domain)
        request.fetchLimit = 1
        if let existing = try? context.fetch(request).first {
            return existing
        }

        let storedMeeting = NSEntityDescription.insertNewObject(
            forEntityName: StoredMeeting.entityName,
            into: context
        ) as! StoredMeeting
        storedMeeting.remoteIdentifier = id
        storedMeeting.domain = domain
        return storedMeeting
    }

    private static func predicate(id: UUID, domain: String) -> NSPredicate {
        NSPredicate(
            format: "remoteIdentifier == %@ AND domain == %@",
            id as CVarArg,
            domain
        )
    }

}

// MARK: - Mapping

private extension MeetingFrequency {

    func toStoredFrequency() -> StoredMeetingRecurrenceFrequency {
        switch self {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
    }

}
