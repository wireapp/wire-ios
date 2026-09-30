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

import WireCallingDomain
import WireLogging
import WireNetwork

protocol MeetingEventNotificationBuilderProtocol {

    func buildContent(event: MeetingEvent) async -> UserNotification?

}

struct MeetingEventNotificationBuilder: MeetingEventNotificationBuilderProtocol {

    let meetingDeleteEventBuilder: any MeetingDeleteEventNotificationBuilderProtocol

    let meetingMemberAddEventBuilder: any MeetingMemberAddEventNotificationBuilderProtocol

    let meetingUpdateEventBuilder: any MeetingUpdateEventNotificationBuilderProtocol

    let reminderReconciler: MeetingEventReminderReconciler?

    init(
        meetingDeleteEventBuilder: any MeetingDeleteEventNotificationBuilderProtocol,
        meetingMemberAddEventBuilder: any MeetingMemberAddEventNotificationBuilderProtocol,
        meetingUpdateEventBuilder: any MeetingUpdateEventNotificationBuilderProtocol,
        reminderReconciler: MeetingEventReminderReconciler? = nil
    ) {
        self.meetingDeleteEventBuilder = meetingDeleteEventBuilder
        self.meetingMemberAddEventBuilder = meetingMemberAddEventBuilder
        self.meetingUpdateEventBuilder = meetingUpdateEventBuilder
        self.reminderReconciler = reminderReconciler
    }

    func buildContent(event: MeetingEvent) async -> UserNotification? {
        let meeting = await reminderReconciler?.reconcile(event: event)

        return switch event {
        case let .delete(event):
            await meetingDeleteEventBuilder.buildContent(event: event)
        case let .memberAdd(event):
            await meetingMemberAddEventBuilder.buildContent(event: event, meeting: meeting)
        case let .update(event):
            await meetingUpdateEventBuilder.buildContent(event: event, meeting: meeting)
        default:
            nil
        }
    }

}

struct MeetingEventReminderReconciler {

    let pullMeeting: (WireNetwork.QualifiedID) async throws -> Meeting?
    let reconcileMeeting: (Meeting) async throws -> Void
    let cancelMeeting: (WireNetwork.QualifiedID) async -> Void

    @discardableResult
    func reconcile(event: MeetingEvent) async -> Meeting? {
        let meetingID: WireNetwork.QualifiedID

        switch event {
        case let .delete(event):
            await cancelMeeting(event.meetingID)
            return nil
        case let .create(event):
            meetingID = event.meetingID
        case let .memberAdd(event):
            meetingID = event.meetingID
        case let .update(event):
            meetingID = event.meetingID
        }

        do {
            if let meeting = try await pullMeeting(meetingID) {
                do {
                    try await reconcileMeeting(meeting)
                } catch {
                    WireLogger.meetings.error("Failed to schedule NSE meeting reminder: \(error)")
                }
                return meeting
            } else {
                // The meeting API confirmed that this meeting no longer exists.
                await cancelMeeting(meetingID)
            }
        } catch {
            // Preserve pending requests if the current meeting could not be fetched.
            WireLogger.meetings.error("Failed to reconcile NSE meeting reminder: \(error)")
        }
        return nil
    }

}
