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

package import Foundation

import WireFoundation

package struct CreateMeetingUseCase: CreateMeetingUseCaseProtocol {

    private let meetingRepository: any MeetingRepositoryProtocol
    private let conversationRepository: any MeetingConversationRepositoryProtocol

    package init(
        meetingRepository: any MeetingRepositoryProtocol,
        conversationRepository: any MeetingConversationRepositoryProtocol
    ) {
        self.meetingRepository = meetingRepository
        self.conversationRepository = conversationRepository
    }

    package func invoke(
        title: String,
        startTime: Date,
        endTime: Date,
        recurrence: MeetingRecurrence?,
        participants: [MeetingMember]
    ) async throws -> Meeting {
        let meeting = try await meetingRepository.createMeeting(
            title: title,
            startTime: startTime,
            endTime: endTime,
            recurrence: recurrence
        )
        // The backend creates a conversation for the meeting but doesn't
        // notify this client about it, so pull it explicitly.
        try await conversationRepository.pullConversation(
            id: meeting.conversationID.id,
            domain: meeting.conversationID.domain
        )
        // The backend doesn't name the conversation it creates for the
        // meeting, so mirror the meeting title onto it.
        try await conversationRepository.setConversationName(title, for: meeting.conversationID)
        try await conversationRepository.addParticipants(participants, to: meeting.conversationID)
        // Store the meeting again now that its conversation exists locally,
        // so the two are linked; meetings without a local conversation are
        // not listed.
        await meetingRepository.storeMeeting(meeting)
        return meeting
    }

}
