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
import WireNetwork

protocol MeetingUpdateEventNotificationBuilderProtocol {

    func buildContent(event: MeetingUpdateEvent) async -> UserNotification?

}

struct MeetingUpdateEventNotificationBuilder: MeetingUpdateEventNotificationBuilderProtocol {

    let meetingsAPI: any MeetingsAPI
    let usersAPI: any UsersAPI
    let featureConfigLocalStore: any FeatureConfigLocalStoreProtocol
    let accountID: UUID
    var locale: Locale = .autoupdatingCurrent
    var timeZone: TimeZone = .autoupdatingCurrent

    func buildContent(event: MeetingUpdateEvent) async -> UserNotification? {
        guard let feature = try? await featureConfigLocalStore.fetchFeature(name: .meetings) else { return nil }
        guard await featureConfigLocalStore.isFeatureEnabled(feature: feature) else { return nil }

        guard let meeting = try? await meetingsAPI.getMeeting(id: event.meetingID) else { return nil }
        // Only the meeting's owner can edit it, so treat a self-owned meeting as
        // a change made on another device and skip the notification.
        guard meeting.creatorID.id != accountID else { return nil }
        guard let host = try? await usersAPI.getUser(for: meeting.creatorID), !host.name.isEmpty else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.timeZone = timeZone
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        let timeFormatter = DateFormatter()
        timeFormatter.locale = locale
        timeFormatter.timeZone = timeZone
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        let content = UNMutableNotificationContent()
        content.title = String.formated(
            key: "push.notification.title.updatedMeeting",
            bundle: .module,
            meeting.title
        )
        content.body = String.formated(
            key: "push.notification.body.senderUpdatedMeeting",
            bundle: .module,
            host.name,
            dateFormatter.string(from: meeting.startTime),
            timeFormatter.string(from: meeting.startTime),
            timeFormatter.string(from: meeting.endTime)
        )
        content.categoryIdentifier = NotificationCategory.meetingUpdate.rawValue
        content.sound = .default
        content.userInfo = [NotificationUserInfoKey.selfUserID: accountID.uuidString]
        return .text(content)
    }

}
