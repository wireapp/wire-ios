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
    private let cancelReminders: @Sendable (UUID, QualifiedID) async -> Void
    private let selfUserID: UUID

    package init(
        meetingRepository: any MeetingRepositoryProtocol,
        conversationRepository: any MeetingConversationRepositoryProtocol,
        cancelReminders: @escaping @Sendable (UUID, QualifiedID) async -> Void,
        selfUserID: UUID
    ) {
        self.meetingRepository = meetingRepository
        self.conversationRepository = conversationRepository
        self.cancelReminders = cancelReminders
        self.selfUserID = selfUserID
    }

    package func invoke(meeting: Meeting) async throws {
        if meeting.creatorID.id == selfUserID {
            do {
                try await meetingRepository.deleteMeeting(id: meeting.id)
            } catch DeleteMeetingUseCaseError.cleanupFailed {
                // The server deletion succeeded, even though local cleanup failed.
                await cancelReminders(selfUserID, meeting.id)
                throw DeleteMeetingUseCaseError.cleanupFailed
            } catch {
                throw error
            }
            await cancelReminders(selfUserID, meeting.id)
            // The deleting client may not receive the conversation deletion event.
            do {
                try await conversationRepository.deleteConversation(id: meeting.conversationID)
            } catch {
                throw DeleteMeetingUseCaseError.cleanupFailed
            }
        } else {
            try await conversationRepository.leaveConversation(id: meeting.conversationID)
            await cancelReminders(selfUserID, meeting.id)
            try await meetingRepository.deleteLocalMeeting(id: meeting.id)
        }
    }

}

package enum DeleteMeetingUseCaseError: Error, Equatable {

    case notAllowed

    case cleanupFailed

}
