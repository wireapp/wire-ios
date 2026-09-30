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
import Testing

@testable import WireCallingDomain

@Suite("MeetingReminder Tests")
struct MeetingReminderTests {

    private let accountID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    private let meetingID = QualifiedID(
        id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
        domain: "example.com"
    )
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("fires ten minutes before the occurrence starts")
    func fireDate() {
        let reminder = MeetingReminder(accountID: accountID, meetingID: meetingID, occurrenceStart: start)

        #expect(reminder.fireDate == start.addingTimeInterval(-600))
    }

    @Test("the same account, meeting, and occurrence produce the same identifier")
    func stableIdentifier() {
        let first = MeetingReminder(accountID: accountID, meetingID: meetingID, occurrenceStart: start)
        let second = MeetingReminder(accountID: accountID, meetingID: meetingID, occurrenceStart: start)

        #expect(first.identifier == second.identifier)
        #expect(first.identifier.hasPrefix("wire.meeting-reminder.v1|"))
    }

    @Test("identifiers distinguish accounts, qualified meetings, and occurrences")
    func distinctIdentifiers() {
        let reminder = MeetingReminder(accountID: accountID, meetingID: meetingID, occurrenceStart: start)
        let otherAccount = MeetingReminder(accountID: UUID(), meetingID: meetingID, occurrenceStart: start)
        let otherMeeting = MeetingReminder(
            accountID: accountID,
            meetingID: QualifiedID(id: UUID(), domain: meetingID.domain),
            occurrenceStart: start
        )
        let otherDomain = MeetingReminder(
            accountID: accountID,
            meetingID: QualifiedID(id: meetingID.id, domain: "other.example.com"),
            occurrenceStart: start
        )
        let otherOccurrence = MeetingReminder(
            accountID: accountID,
            meetingID: meetingID,
            occurrenceStart: start.addingTimeInterval(3600)
        )

        #expect(Set([
            reminder.identifier,
            otherAccount.identifier,
            otherMeeting.identifier,
            otherDomain.identifier,
            otherOccurrence.identifier
        ]).count == 5)
    }

}
