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

import UserNotifications
import WireCallingData
import WireDataModel
import WireNetwork

protocol MeetingDeleteEventNotificationBuilderProtocol {

    func buildContent(event: MeetingDeleteEvent) async -> UserNotification?

}

struct MeetingDeleteEventNotificationBuilder: MeetingDeleteEventNotificationBuilderProtocol {

    let meetingLocalStore: any MeetingLocalStoreProtocol
    let userLocalStore: any UserLocalStoreProtocol
    let featureConfigLocalStore: any FeatureConfigLocalStoreProtocol
    let accountID: UUID

    func buildContent(event: MeetingDeleteEvent) async -> UserNotification? {
        guard let feature = try? await featureConfigLocalStore.fetchFeature(name: .meetings) else { return nil }
        guard await featureConfigLocalStore.isFeatureEnabled(feature: feature) else { return nil }
        guard let meeting = await meetingLocalStore.storedMeeting(id: event.meetingID) else { return nil }
        guard meeting.creatorID.id != accountID else { return nil }
        guard let host = try? await userLocalStore.fetchUser(
            id: meeting.creatorID.id,
            domain: meeting.creatorID.domain
        ) else { return nil }
        guard let hostName = await userLocalStore.name(for: host), !hostName.isEmpty else { return nil }

        let content = UNMutableNotificationContent()
        content.title = meeting.title
        content.body = String.formated(key: "push.notification.body.senderCanceledMeeting", bundle: .module, hostName)
        content.categoryIdentifier = NotificationCategory.meetingCancellation.rawValue
        content.sound = .default
        content.userInfo = [
            NotificationUserInfoKey.selfUserID: accountID.uuidString
        ]

        return .text(content)
    }

}
