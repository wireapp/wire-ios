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
import UserNotifications
import WireCallingDomain
import WireFoundation

struct MeetingReminderNotificationContentBuilder {

    var locale: Locale = .autoupdatingCurrent
    var timeZone: TimeZone = .autoupdatingCurrent

    func build(
        meeting: Meeting,
        occurrenceStart: Date,
        accountID: UUID,
        showMeetingTitle: Bool
    ) -> UNMutableNotificationContent {
        let timeFormatter = DateFormatter()
        timeFormatter.locale = locale
        timeFormatter.timeZone = timeZone
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        let content = UNMutableNotificationContent()
        content.title = showMeetingTitle && !meeting.title.isEmpty
            ? meeting.title
            : String.localized(key: "meeting_reminder.title", bundle: .module)
        content.body = String.formated(
            key: "meeting_reminder.body",
            bundle: .module,
            timeFormatter.string(from: occurrenceStart)
        )
        content.categoryIdentifier = NotificationCategory.meetingReminder.rawValue
        content.sound = .default
        content.userInfo = [
            NotificationUserInfoKey.selfUserID: accountID.uuidString,
            MeetingReminderUserInfoKey.conversationID: meeting.conversationID.id.uuidString,
            MeetingReminderUserInfoKey.conversationDomain: meeting.conversationID.domain
        ]
        return content
    }

}

public enum MeetingReminderUserInfoKey {

    public static let conversationID = "meetingReminderConversationID"
    public static let conversationDomain = "meetingReminderConversationDomain"

}
