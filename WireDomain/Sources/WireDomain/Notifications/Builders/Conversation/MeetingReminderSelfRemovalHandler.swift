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
import WireNetwork

/// Handles self-removal in the notification extension, including meetings absent from its local store.
struct MeetingReminderSelfRemovalHandler {

    let accountID: UUID
    let storedMeetings: () async -> [Meeting]
    let cancelMeeting: (WireNetwork.QualifiedID) async -> Void
    let deleteMeeting: (WireNetwork.QualifiedID) async -> Void
    let cancelPendingRequests: (WireNetwork.QualifiedID) async -> Void

    func handle(event: ConversationMemberLeaveEvent) async {
        guard event.removedUserIDs.contains(where: { $0.id == accountID }) else { return }

        let meetings = await storedMeetings()
        for meeting in meetings where meeting.conversationID == event.conversationID {
            await cancelMeeting(meeting.id)
            await deleteMeeting(meeting.id)
        }

        // Pending requests also carry the conversation ID, so cancellation works
        // when the NSE has no local meeting-to-conversation mapping.
        await cancelPendingRequests(event.conversationID)
    }

}

/// Finds an account's reminders by conversation metadata when the meeting ID is unavailable locally.
struct MeetingReminderPendingRequestCanceller {

    let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    func cancel(accountID: UUID, conversationID: WireNetwork.QualifiedID) async {
        let identifiers: [String] = await withCheckedContinuation { continuation in
            notificationCenter.getPendingNotificationRequests { requests in
                let matching = Self.matchingIdentifiers(
                    in: requests,
                    accountID: accountID,
                    conversationID: conversationID
                )
                continuation.resume(returning: matching)
            }
        }

        if !identifiers.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    static func matchingIdentifiers(
        in requests: [UNNotificationRequest],
        accountID: UUID,
        conversationID: WireNetwork.QualifiedID
    ) -> [String] {
        let accountPrefix = MeetingReminder.accountIdentifierPrefix(accountID: accountID)
        return requests.filter { request in
            request.identifier.hasPrefix(accountPrefix)
                && request.content.userInfo[MeetingReminderUserInfoKey.conversationID] as? String
                == conversationID.id.uuidString
                && request.content.userInfo[MeetingReminderUserInfoKey.conversationDomain] as? String
                == conversationID.domain
        }.map(\.identifier)
    }

}
