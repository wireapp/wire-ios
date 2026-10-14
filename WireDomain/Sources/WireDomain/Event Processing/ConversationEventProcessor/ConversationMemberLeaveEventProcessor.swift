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
import WireCallingData
import WireDataModel
import WireLogging
import WireNetwork

struct ConversationMemberLeaveEventProcessor: ConversationMemberLeaveEventProcessorProtocol {

    enum Error: Swift.Error {
        case failedToRemoveMembers(userIDs: Set<UserID>)
    }

    let repository: any ConversationRepositoryProtocol
    let meetingLocalStore: any MeetingLocalStoreProtocol
    let reminderCanceller: any MeetingReminderCancelling
    let accountID: UUID

    func processEvent(_ event: ConversationMemberLeaveEvent) async throws {
        // Cancel before the conversation update, which may fail or remove the meeting mapping.
        if event.removedUserIDs.contains(where: { $0.id == accountID }) {
            let meetings = await meetingLocalStore.storedMeetings()
            for meeting in meetings where meeting.conversationID.id == event.conversationID.id
                && meeting.conversationID.domain == event.conversationID.domain {
                await reminderCanceller.cancelAll(accountID: accountID, meetingID: meeting.id)
                do {
                    try await meetingLocalStore.deleteMeeting(id: meeting.id)
                } catch {
                    WireLogger.meetings.error("Failed to remove meeting after self-removal: \(error)")
                }
            }
        }

        do {
            try await repository.removeMembers(
                event.removedUserIDs,
                from: event.conversationID,
                initiatedBy: event.senderID,
                at: event.timestamp,
                reason: event.reason
            )
        } catch {
            throw Error.failedToRemoveMembers(userIDs: event.removedUserIDs)
        }
    }

}
