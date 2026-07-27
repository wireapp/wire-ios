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

package struct UpdateMeetingUseCase: UpdateMeetingUseCaseProtocol {

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
        meeting: Meeting,
        title: String,
        startTime: Date,
        endTime: Date,
        recurrence: MeetingRecurrence?,
        participants: [MeetingMember]
    ) async throws -> Meeting {
        // The participant diff below needs the conversation's current members
        // as its baseline; without it, every existing participant would look
        // newly added. Fail before mutating anything.
        guard let conversation = meeting.conversation else {
            throw UpdateMeetingUseCaseError.conversationNotResolved
        }

        // Update the meeting itself first: it can fail with a permission
        // error (only the creator may edit), in which case the participants
        // should stay untouched.
        let updatedMeeting = try await meetingRepository.updateMeeting(
            id: meeting.id,
            title: title,
            startTime: startTime,
            endTime: endTime,
            recurrence: recurrence
        )

        // The creator is implicit in the form's participant selection, so it
        // is excluded from the baseline too — otherwise every update would
        // try to remove the creator from the conversation.
        let previousMembers = conversation.participants
            .filter { $0.qualifiedID != meeting.creatorID }
            .sorted { $0.name < $1.name }
        let previousIDs = Set(previousMembers.map(\.qualifiedID))
        let selectedIDs = Set(participants.map(\.qualifiedID))
        let membersToAdd = participants.filter { !previousIDs.contains($0.qualifiedID) }
        let membersToRemove = previousMembers.filter { !selectedIDs.contains($0.qualifiedID) }

        try await conversationRepository.addParticipants(membersToAdd, to: meeting.conversationID)
        try await conversationRepository.removeParticipants(membersToRemove, from: meeting.conversationID)

        return updatedMeeting
    }

}

package enum UpdateMeetingUseCaseError: Error {

    /// The meeting's conversation has not been resolved from the local store,
    /// so there is no baseline to diff the selected participants against.
    case conversationNotResolved

}
