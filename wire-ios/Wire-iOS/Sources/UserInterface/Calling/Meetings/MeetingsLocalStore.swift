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
import WireCallingDomain
import WireDataModel
import WireFoundation

/// Stores meetings in Core Data using the `StoredMeeting` entity.
struct MeetingsLocalStore: MeetingsLocalStoreProtocol, @unchecked Sendable {

    let context: NSManagedObjectContext

    func storedMeetings() async -> [Meeting] {
        await context.perform { [context] in
            let request = StoredMeeting.fetchRequest()
            let storedMeetings = (try? context.fetch(request)) ?? []
            return storedMeetings.compactMap { $0.toDomainMeeting() }
        }
    }

    func storeMeetings(_ meetings: [Meeting]) async {
        await context.perform { [context] in
            for meeting in meetings {
                Self.upsert(meeting, in: context)
            }
            _ = context.saveOrRollback()
        }
    }

    func storeMeeting(_ meeting: Meeting) async {
        await context.perform { [context] in
            Self.upsert(meeting, in: context)
            _ = context.saveOrRollback()
        }
    }

    private static func upsert(_ meeting: Meeting, in context: NSManagedObjectContext) {
        let storedMeeting = fetchOrCreateStoredMeeting(id: meeting.id, in: context)
        storedMeeting.title = meeting.title
        storedMeeting.start = meeting.start
        storedMeeting.end = meeting.end
        storedMeeting.recurrenceFrequency = meeting.recurrence?.frequency.toStoredFrequency()
        storedMeeting.recurrenceInterval = Int64(meeting.recurrence?.interval ?? 0)
        storedMeeting.recurrenceUntil = meeting.recurrence?.until
        storedMeeting.conversation = ZMConversation.fetch(
            with: meeting.conversationID.id,
            domain: meeting.conversationID.domain,
            in: context
        )
    }

    private static func fetchOrCreateStoredMeeting(
        id: WireFoundation.QualifiedID,
        in context: NSManagedObjectContext
    ) -> StoredMeeting {
        let request = StoredMeeting.fetchRequest()
        request.predicate = NSPredicate(
            format: "remoteIdentifier == %@ AND domain == %@",
            id.id as CVarArg,
            id.domain
        )
        request.fetchLimit = 1
        if let existing = try? context.fetch(request).first {
            return existing
        }

        let storedMeeting = NSEntityDescription.insertNewObject(
            forEntityName: StoredMeeting.entityName,
            into: context
        ) as! StoredMeeting
        storedMeeting.remoteIdentifier = id.id
        storedMeeting.domain = id.domain
        return storedMeeting
    }

}

// MARK: - Mapping

private extension StoredMeeting {

    func toDomainMeeting() -> Meeting? {
        guard
            let remoteIdentifier,
            let title,
            let start,
            let end,
            let conversationID = conversation?.qualifiedID
        else { return nil }

        return Meeting(
            id: WireFoundation.QualifiedID(id: remoteIdentifier, domain: domain ?? ""),
            title: title,
            start: start,
            end: end,
            recurrence: toDomainRecurrence(),
            members: [],
            conversationID: WireFoundation.QualifiedID(
                id: conversationID.uuid,
                domain: conversationID.domain
            )
        )
    }

    private func toDomainRecurrence() -> MeetingRecurrence? {
        guard let recurrenceFrequency else { return nil }

        let frequency: MeetingRecurrence.Frequency = switch recurrenceFrequency {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
        return MeetingRecurrence(
            frequency: frequency,
            interval: Int(recurrenceInterval),
            until: recurrenceUntil
        )
    }

}

private extension MeetingRecurrence.Frequency {

    func toStoredFrequency() -> StoredMeetingRecurrenceFrequency {
        switch self {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
    }

}
