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
import WireCallingData
import WireCallingDomain
import WireDataModel
import WireFoundation

final class MeetingLocalStore: MeetingLocalStoreProtocol, @unchecked Sendable {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func storedMeetings() async -> [Meeting] {
        await context.perform { [context] in
            let request = StoredMeeting.fetchRequest()
            let storedMeetings = (try? context.fetch(request)) ?? []
            return storedMeetings.compactMap { $0.toDomainMeeting() }
        }
    }

    func storedMeeting(id: WireCallingDomain.QualifiedID) async -> Meeting? {
        await context.perform { [context] in
            let request = StoredMeeting.fetchRequest()
            request.predicate = Self.predicate(id: .init(uuid: id.id, domain: id.domain))
            request.fetchLimit = 1
            return (try? context.fetch(request).first)?.toDomainMeeting()
        }
    }

    func storeMeeting(_ meeting: Meeting) async {
        await context.perform { [context] in
            Self.upsert(meeting, in: context)
            _ = context.saveOrRollback()
        }
    }

    func replaceAllMeetings(with meetings: [Meeting]) async {
        await context.perform { [context] in
            let newIDs = Set(meetings.map(\.id))
            let request = StoredMeeting.fetchRequest()
            let existing = (try? context.fetch(request)) ?? []
            for storedMeeting in existing {
                guard let remoteIdentifier = storedMeeting.remoteIdentifier else { continue }
                let id = QualifiedID(
                    id: remoteIdentifier,
                    domain: storedMeeting.domain ?? ""
                )
                if !newIDs.contains(id) {
                    context.delete(storedMeeting)
                }
            }
            for meeting in meetings {
                Self.upsert(meeting, in: context)
            }
            _ = context.saveOrRollback()
        }
    }

    func deleteMeeting(id: WireCallingDomain.QualifiedID) async {
        await context.perform { [context] in
            let request = StoredMeeting.fetchRequest()
            request.predicate = Self.predicate(id: .init(uuid: id.id, domain: id.domain))
            request.fetchLimit = 1
            guard let storedMeeting = try? context.fetch(request).first else { return }

            context.delete(storedMeeting)
            _ = context.saveOrRollback()
        }
    }

    // MARK: - Private

    private static func upsert(_ meeting: Meeting, in context: NSManagedObjectContext) {
        let storedMeeting = fetchOrCreateStoredMeeting(
            id: .init(uuid: meeting.id.id, domain: meeting.id.domain),
            in: context
        )
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
        storedMeeting.creator = ZMUser.fetch(
            with: meeting.creatorID.id,
            domain: meeting.creatorID.domain,
            in: context
        )
    }

    private static func fetchOrCreateStoredMeeting(
        id: WireDataModel.QualifiedID,
        in context: NSManagedObjectContext
    ) -> StoredMeeting {
        let request = StoredMeeting.fetchRequest()
        request.predicate = predicate(id: id)
        request.fetchLimit = 1
        if let existing = try? context.fetch(request).first {
            return existing
        }

        let storedMeeting = NSEntityDescription.insertNewObject(
            forEntityName: StoredMeeting.entityName(),
            into: context
        ) as! StoredMeeting
        storedMeeting.remoteIdentifier = id.uuid
        storedMeeting.domain = id.domain
        return storedMeeting
    }

    private static func predicate(id: WireDataModel.QualifiedID) -> NSPredicate {
        NSPredicate(
            format: "remoteIdentifier == %@ AND domain == %@",
            id.uuid as NSUUID,
            id.domain
        )
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
            let creatorID = creator?.qualifiedID
        else { return nil }

        guard let conversation, let conversationID = conversation.qualifiedID else { return nil }

        return Meeting(
            id: QualifiedID(id: remoteIdentifier, domain: domain ?? ""),
            title: title,
            start: start,
            end: end,
            recurrence: toDomainRecurrence(),
            members: conversation.toDomainMembers(),
            conversationID: QualifiedID(id: conversationID.uuid, domain: conversationID.domain),
            creatorID: QualifiedID(id: creatorID.uuid, domain: creatorID.domain)
        )
    }

    private func toDomainRecurrence() -> WireCallingDomain.MeetingRecurrence? {
        guard let recurrenceFrequency else { return nil }

        let frequency: WireCallingDomain.MeetingRecurrence.Frequency = switch recurrenceFrequency {
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

private extension ZMConversation {

    /// The meeting's members are not part of the backend's meeting responses;
    /// the participants of the meeting's conversation are the source of truth.
    /// The self user is excluded, matching the participant selection in the
    /// meeting forms, where the creator is implicit.
    func toDomainMembers() -> [MeetingMember] {
        localParticipantsExcludingSelf
            .compactMap { user -> MeetingMember? in
                guard let id = user.remoteIdentifier else { return nil }
                return MeetingMember(
                    qualifiedID: QualifiedID(id: id, domain: user.domain ?? ""),
                    name: user.name ?? "",
                    handle: user.handle ?? ""
                )
            }
            .sorted { $0.name < $1.name }
    }

}

private extension WireCallingDomain.MeetingRecurrence.Frequency {

    func toStoredFrequency() -> StoredMeetingRecurrenceFrequency {
        switch self {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
    }

}
