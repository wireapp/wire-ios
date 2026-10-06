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

struct MeetingUpdateEventProcessor: MeetingUpdateEventProcessorProtocol {

    let repository: any MeetingRepositoryProtocol
    let conversationRepository: any ConversationRepositoryProtocol
    let reconcileReminder: @Sendable (Meeting) async throws -> Void
    let cancelReminder: @Sendable (WireNetwork.QualifiedID) async -> Void

    func processEvent(_ event: MeetingUpdateEvent) async throws {
        // A nil meeting no longer exists on the backend; its local copy
        // was already deleted, so there is nothing left to link.
        guard let meeting = try await repository.pullMeeting(id: event.meetingID) else {
            await cancelReminder(event.meetingID)
            return
        }

        // Reconcile before the conversation pull, whose failure can stop processing this event.
        do {
            try await reconcileReminder(meeting)
        } catch {
            WireLogger.eventProcessing.error("Failed to reconcile meeting reminder: \(error)")
        }

        let conversationID = meeting.conversationID
        try await conversationRepository.pullConversation(
            id: conversationID.id,
            domain: conversationID.domain
        )
        await repository.storeMeeting(meeting)
    }

}
