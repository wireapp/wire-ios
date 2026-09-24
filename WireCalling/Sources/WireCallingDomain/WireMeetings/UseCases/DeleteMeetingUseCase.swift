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

package struct DeleteMeetingUseCase: DeleteMeetingUseCaseProtocol {

    private let meetingRepository: any MeetingRepositoryProtocol
    private let conversationRepository: any MeetingConversationRepositoryProtocol
    private let selfUserID: UUID

    package init(
        meetingRepository: any MeetingRepositoryProtocol,
        conversationRepository: any MeetingConversationRepositoryProtocol,
        selfUserID: UUID
    ) {
        self.meetingRepository = meetingRepository
        self.conversationRepository = conversationRepository
        self.selfUserID = selfUserID
    }

    package func invoke(meeting: Meeting) async throws {
        if meeting.creatorID.id == selfUserID {
            try await meetingRepository.deleteMeeting(id: meeting.id)
        } else {
            try await conversationRepository.leaveConversation(id: meeting.conversationID)
            await meetingRepository.deleteLocalMeeting(id: meeting.id)
        }
    }

}
