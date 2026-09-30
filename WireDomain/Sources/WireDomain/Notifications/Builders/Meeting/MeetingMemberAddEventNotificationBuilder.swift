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
import WireCallingData
import WireCallingDomain
import WireNetwork

protocol MeetingMemberAddEventNotificationBuilderProtocol {

    func buildContent(event: MeetingMemberAddEvent) async -> UserNotification?

}

struct MeetingMemberAddEventNotificationBuilder: MeetingMemberAddEventNotificationBuilderProtocol {

    let meetingsAPI: any MeetingsAPI
    let usersAPI: any UsersAPI
    let featureConfigLocalStore: any FeatureConfigLocalStoreProtocol
    let meetingLocalStore: (any MeetingLocalStoreProtocol)?
    let accountID: UUID
    var locale: Locale = .autoupdatingCurrent
    var timeZone: TimeZone = .autoupdatingCurrent

    init(
        meetingsAPI: any MeetingsAPI,
        usersAPI: any UsersAPI,
        featureConfigLocalStore: any FeatureConfigLocalStoreProtocol,
        meetingLocalStore: (any MeetingLocalStoreProtocol)? = nil,
        accountID: UUID,
        locale: Locale = .autoupdatingCurrent,
        timeZone: TimeZone = .autoupdatingCurrent
    ) {
        self.meetingsAPI = meetingsAPI
        self.usersAPI = usersAPI
        self.featureConfigLocalStore = featureConfigLocalStore
        self.meetingLocalStore = meetingLocalStore
        self.accountID = accountID
        self.locale = locale
        self.timeZone = timeZone
    }

    func buildContent(event: MeetingMemberAddEvent) async -> UserNotification? {
        guard let feature = try? await featureConfigLocalStore.fetchFeature(name: .meetings) else { return nil }
        guard await featureConfigLocalStore.isFeatureEnabled(feature: feature) else { return nil }
        guard event.senderID.id != accountID else { return nil }

        // The NSE stores events without running the application's meeting refresh,
        // so an invitation's meeting and inviter may not exist in the local store yet.
        guard let meeting = try? await meetingsAPI.getMeeting(id: event.meetingID) else { return nil }
        await meetingLocalStore?.storeMeeting(meeting.toDomainMeeting())
        guard let inviter = try? await usersAPI.getUser(for: event.senderID), !inviter.name.isEmpty else { return nil }

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
        content.title = meeting.title
        content.body = String.formated(
            key: "push.notification.body.senderInvitedToMeeting",
            bundle: .module,
            inviter.name,
            dateFormatter.string(from: meeting.startTime),
            timeFormatter.string(from: meeting.startTime),
            timeFormatter.string(from: meeting.endTime)
        )
        content.categoryIdentifier = NotificationCategory.meetingInvitation.rawValue
        content.sound = .default
        content.userInfo = [NotificationUserInfoKey.selfUserID: accountID.uuidString]
        return .text(content)
    }

}

private extension MeetingResponse {

    func toDomainMeeting() -> Meeting {
        Meeting(
            id: id,
            title: title,
            start: startTime,
            end: endTime,
            recurrence: recurrence?.toDomainRecurrence(),
            timeZoneIdentifier: timeZoneIdentifier,
            conversationID: conversationID,
            creatorID: creatorID
        )
    }

}

private extension WireNetwork.MeetingRecurrence {

    func toDomainRecurrence() -> WireCallingDomain.MeetingRecurrence {
        WireCallingDomain.MeetingRecurrence(
            frequency: frequency.toDomainFrequency(),
            interval: interval ?? 1,
            until: until
        )
    }

}

private extension MeetingFrequency {

    func toDomainFrequency() -> WireCallingDomain.MeetingRecurrence.Frequency {
        switch self {
        case .daily: .daily
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
    }

}
