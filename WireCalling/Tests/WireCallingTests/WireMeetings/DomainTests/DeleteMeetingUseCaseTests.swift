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
import Testing
import WireFoundation

@testable import WireCallingDomain
@testable import WireCallingDomainSupport

@Suite("DeleteMeetingUseCase Tests")
struct DeleteMeetingUseCaseTests {

    private let meetingRepository = MeetingRepositoryProtocolMock()
    private let conversationRepository = MeetingConversationRepositoryProtocolMock()
    private let reminderCanceller = ReminderCancellerSpy()
    private let meeting = Meeting(
        id: QualifiedID(id: UUID(), domain: "example.com"),
        title: "Team meeting",
        start: .distantPast,
        end: .distantFuture,
        recurrence: nil,
        conversationID: QualifiedID(id: UUID(), domain: "example.com"),
        creatorID: QualifiedID(id: UUID(), domain: "example.com")
    )

    @Test("Host deletion cleans up the conversation without a server event")
    func hostDeletionCleansUpConversation() async throws {
        conversationRepository.deleteConversationIdConversationIDQualifiedIDVoidClosure = { _ in
            #expect(meetingRepository.deleteMeetingIdQualifiedIDVoidCallsCount == 1)
        }

        try await makeUseCase(selfUserID: meeting.creatorID.id).invoke(meeting: meeting)

        #expect(meetingRepository.deleteMeetingIdQualifiedIDVoidReceivedId == meeting.id)
        #expect(conversationRepository.deleteConversationIdConversationIDQualifiedIDVoidReceivedConversationID
            == meeting.conversationID)
        #expect(conversationRepository.leaveConversationIdConversationIDQualifiedIDVoidCallsCount == 0)
        let cancellations = await reminderCanceller.cancellations
        #expect(cancellations.count == 1)
        #expect(cancellations[0].accountID == meeting.creatorID.id)
        #expect(cancellations[0].meetingID == meeting.id)
    }

    @Test("Failed host deletion keeps the local conversation")
    func failedHostDeletionKeepsConversation() async {
        meetingRepository.deleteMeetingIdQualifiedIDVoidThrowableError = URLError(.notConnectedToInternet)

        await #expect(throws: URLError.self) {
            try await makeUseCase(selfUserID: meeting.creatorID.id).invoke(meeting: meeting)
        }

        #expect(conversationRepository.deleteConversationIdConversationIDQualifiedIDVoidCallsCount == 0)
        let cancellations = await reminderCanceller.cancellations
        #expect(cancellations.isEmpty)
    }

    @Test("Participant deletion leaves the conversation without deleting it for everyone")
    func participantDeletionLeavesConversation() async throws {
        let participantID = UUID()
        try await makeUseCase(selfUserID: participantID).invoke(meeting: meeting)

        #expect(conversationRepository.leaveConversationIdConversationIDQualifiedIDVoidReceivedConversationID
            == meeting.conversationID)
        #expect(meetingRepository.deleteLocalMeetingIdQualifiedIDVoidReceivedId == meeting.id)
        #expect(meetingRepository.deleteMeetingIdQualifiedIDVoidCallsCount == 0)
        #expect(conversationRepository.deleteConversationIdConversationIDQualifiedIDVoidCallsCount == 0)
        let cancellations = await reminderCanceller.cancellations
        #expect(cancellations.count == 1)
        #expect(cancellations[0].accountID == participantID)
        #expect(cancellations[0].meetingID == meeting.id)
    }

    private func makeUseCase(selfUserID: UUID) -> DeleteMeetingUseCase {
        let reminderCanceller = reminderCanceller
        return DeleteMeetingUseCase(
            meetingRepository: meetingRepository,
            conversationRepository: conversationRepository,
            cancelReminders: { accountID, meetingID in
                await reminderCanceller.cancelAll(accountID: accountID, meetingID: meetingID)
            },
            selfUserID: selfUserID
        )
    }

}

private actor ReminderCancellerSpy {
    private(set) var cancellations: [(accountID: UUID, meetingID: QualifiedID)] = []

    func cancelAll(accountID: UUID, meetingID: QualifiedID) async {
        cancellations.append((accountID, meetingID))
    }
}
