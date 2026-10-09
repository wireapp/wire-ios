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
import UserNotifications
import WireCallingDomain

@testable import WireDomain

@Suite("MeetingReminderNotificationContentBuilder Tests")
struct MeetingReminderNotificationContentBuilderTests {

    private let accountID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    private let occurrenceStart = Date(timeIntervalSince1970: 1_900_000_000)
    private let meeting = Meeting(
        id: QualifiedID(id: UUID(), domain: "example.com"),
        title: "Team planning",
        start: Date(timeIntervalSince1970: 1_900_000_000),
        end: Date(timeIntervalSince1970: 1_900_003_600),
        recurrence: nil,
        conversationID: QualifiedID(id: UUID(), domain: "example.com"),
        creatorID: QualifiedID(id: UUID(), domain: "example.com")
    )

    @Test("shows the meeting title and the local start time")
    func showsMeetingDetails() {
        let timeZone = TimeZone(secondsFromGMT: 3600)!
        let content = MeetingReminderNotificationContentBuilder(
            locale: Locale(identifier: "en_US"),
            timeZone: timeZone
        ).build(
            meeting: meeting,
            occurrenceStart: occurrenceStart,
            accountID: accountID,
            showMeetingTitle: true
        )

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US")
        timeFormatter.timeZone = timeZone
        timeFormatter.timeStyle = .short

        #expect(content.title == meeting.title)
        #expect(content.body == "Starts at \(timeFormatter.string(from: occurrenceStart))")
        #expect(content.categoryIdentifier == NotificationCategory.meetingReminder.rawValue)
        #expect(content.userInfo[NotificationUserInfoKey.selfUserID] as? String == accountID.uuidString)
        #expect(content.userInfo[MeetingReminderUserInfoKey.conversationID] as? String
            == meeting.conversationID.id.uuidString)
        #expect(content.userInfo[MeetingReminderUserInfoKey.conversationDomain] as? String
            == meeting.conversationID.domain)
        #expect(content.sound == UNNotificationSound(named: .init("new_message.caf")))
    }

    @Test("hides the meeting title when details are not allowed")
    func hidesMeetingTitle() {
        let content = MeetingReminderNotificationContentBuilder().build(
            meeting: meeting,
            occurrenceStart: occurrenceStart,
            accountID: accountID,
            showMeetingTitle: false
        )

        #expect(content.title == "Meeting reminder")
        #expect(!content.body.contains(meeting.title))
    }

}
