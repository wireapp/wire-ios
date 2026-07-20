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
        guard let meeting = try await repository.pullMeeting(id: event.meetingID) else { return }

        // The backend doesn't send a conversation.create event for the meeting's
        // conversation (see `CreateMeetingUseCase`), so a meeting created on
        // another client references a conversation this client doesn't know yet.
        // Pull it and store the meeting again so the two are linked; meetings
        // without a locally stored conversation are not listed.
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
