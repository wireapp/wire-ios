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
import WireNetwork

struct MeetingUpdateEventProcessor: MeetingUpdateEventProcessorProtocol {

    let repository: any MeetingRepositoryProtocol
    let conversationRepository: any ConversationRepositoryProtocol

    func processEvent(_ event: MeetingUpdateEvent) async throws {
        // A nil meeting no longer exists on the backend; its local copy
        // was already deleted, so there is nothing left to link.
        guard let meeting = try await repository.pullMeeting(id: event.meetingID) else { return }

        // The meeting's conversation arrives via its own conversation.create-meeting
        // event, but that event isn't guaranteed to have been processed before this
        // one. If the conversation isn't stored locally yet, pull it and store the
        // meeting again so the two are linked; meetings without a locally stored
        // conversation are not listed.
        let conversationID = meeting.conversationID
        guard await conversationRepository.fetchConversation(
            id: conversationID.id,
            domain: conversationID.domain
        ) == nil else { return }

        try await conversationRepository.pullConversation(
            id: conversationID.id,
            domain: conversationID.domain
        )
        await repository.storeMeeting(meeting)
    }

}
