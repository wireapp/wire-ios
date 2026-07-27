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

@Suite("UpdateMeetingUseCase Tests")
struct UpdateMeetingUseCaseTests {

    private let meetingRepository = MeetingRepositoryProtocolMock()
    private let conversationRepository = MeetingConversationRepositoryProtocolMock()
    private let useCase: UpdateMeetingUseCase

    private static let keptMember = MeetingMember(
        qualifiedID: QualifiedID(id: UUID(), domain: "example.com"),
        name: "Katie Armstrong",
        handle: "katie"
    )

    private static let removedMember = MeetingMember(
        qualifiedID: QualifiedID(id: UUID(), domain: "example.com"),
        name: "Marco Weissnat",
        handle: "marco"
    )

    private static let addedMember = MeetingMember(
        qualifiedID: QualifiedID(id: UUID(), domain: "example.com"),
        name: "Olga Heaney",
        handle: "olga"
    )

    private let meeting = Meeting(
        id: QualifiedID(id: UUID(), domain: "example.com"),
        title: "Team Standup",
        start: .distantPast,
        end: .distantFuture,
        recurrence: nil,
        conversation: MeetingConversation(
            qualifiedID: QualifiedID(id: UUID(), domain: "example.com"),
            participants: [Self.keptMember, Self.removedMember]
        ),
        creatorID: QualifiedID(id: UUID(), domain: "example.com")
    )

    init() {
        self.useCase = UpdateMeetingUseCase(
            meetingRepository: meetingRepository,
            conversationRepository: conversationRepository
        )
    }

    @Test("invoke updates the meeting via the repository and returns it")
    func invokeUpdatesMeeting() async throws {
        // Given
        meetingRepository
            .updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReturnValue =
            meeting
        let recurrence = MeetingRecurrence(frequency: .weekly, interval: 1)

        // When
        let result = try await useCase.invoke(
            meeting: meeting,
            title: "Renamed Standup",
            startTime: meeting.start,
            endTime: meeting.end,
            recurrence: recurrence,
            participants: [Self.keptMember, Self.removedMember]
        )

        // Then
        let arguments = meetingRepository
            .updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReceivedArguments
        #expect(arguments?.id == meeting.id)
        #expect(arguments?.title == "Renamed Standup")
        #expect(arguments?.startTime == meeting.start)
        #expect(arguments?.endTime == meeting.end)
        #expect(arguments?.recurrence == recurrence)
        #expect(result == meeting)
    }

    @Test("invoke adds newly selected members and removes deselected ones")
    func invokeAddsAndRemovesParticipants() async throws {
        // Given
        meetingRepository
            .updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReturnValue =
            meeting

        // When
        _ = try await useCase.invoke(
            meeting: meeting,
            title: meeting.title,
            startTime: meeting.start,
            endTime: meeting.end,
            recurrence: nil,
            participants: [Self.keptMember, Self.addedMember]
        )

        // Then
        let addArguments = conversationRepository
            .addParticipantsParticipantsMeetingMemberToConversationIDQualifiedIDVoidReceivedArguments
        #expect(addArguments?.participants == [Self.addedMember])
        #expect(addArguments?.conversationID == meeting.conversation.qualifiedID)
        let removeArguments = conversationRepository
            .removeParticipantsParticipantsMeetingMemberFromConversationIDQualifiedIDVoidReceivedArguments
        #expect(removeArguments?.participants == [Self.removedMember])
        #expect(removeArguments?.conversationID == meeting.conversation.qualifiedID)
    }

    @Test("invoke leaves the participants unchanged when the selection matches the members")
    func invokeWithUnchangedParticipants() async throws {
        // Given
        meetingRepository
            .updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReturnValue =
            meeting

        // When
        _ = try await useCase.invoke(
            meeting: meeting,
            title: meeting.title,
            startTime: meeting.start,
            endTime: meeting.end,
            recurrence: nil,
            participants: [Self.keptMember, Self.removedMember]
        )

        // Then
        let addArguments = conversationRepository
            .addParticipantsParticipantsMeetingMemberToConversationIDQualifiedIDVoidReceivedArguments
        #expect(addArguments?.participants.isEmpty == true)
        let removeArguments = conversationRepository
            .removeParticipantsParticipantsMeetingMemberFromConversationIDQualifiedIDVoidReceivedArguments
        #expect(removeArguments?.participants.isEmpty == true)
    }

    @Test("invoke does not touch the participants when updating the meeting fails")
    func invokeFailsWhenUpdatingMeetingFails() async {
        // Given
        meetingRepository
            .updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingThrowableError =
            URLError(.badServerResponse)

        // When / Then
        await #expect(throws: URLError.self) {
            _ = try await useCase.invoke(
                meeting: meeting,
                title: meeting.title,
                startTime: meeting.start,
                endTime: meeting.end,
                recurrence: nil,
                participants: [Self.addedMember]
            )
        }
        #expect(conversationRepository
            .addParticipantsParticipantsMeetingMemberToConversationIDQualifiedIDVoidCallsCount == 0)
        #expect(conversationRepository
            .removeParticipantsParticipantsMeetingMemberFromConversationIDQualifiedIDVoidCallsCount == 0)
    }

    @Test("invoke keeps the implicit creator out of the participant diff")
    func invokeExcludesCreatorFromDiff() async throws {
        // Given
        let creatorMember = MeetingMember(
            qualifiedID: QualifiedID(id: UUID(), domain: "example.com"),
            name: "Erika Muster",
            handle: "erika"
        )
        let meeting = Meeting(
            id: QualifiedID(id: UUID(), domain: "example.com"),
            title: "Team Standup",
            start: .distantPast,
            end: .distantFuture,
            recurrence: nil,
            conversation: MeetingConversation(
                qualifiedID: QualifiedID(id: UUID(), domain: "example.com"),
                participants: [creatorMember, Self.keptMember]
            ),
            creatorID: creatorMember.qualifiedID
        )
        meetingRepository
            .updateMeetingIdQualifiedIDTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReturnValue =
            meeting

        // When — the form's selection never contains the creator
        _ = try await useCase.invoke(
            meeting: meeting,
            title: meeting.title,
            startTime: meeting.start,
            endTime: meeting.end,
            recurrence: nil,
            participants: [Self.keptMember]
        )

        // Then — the creator must neither be removed nor re-added
        let addArguments = conversationRepository
            .addParticipantsParticipantsMeetingMemberToConversationIDQualifiedIDVoidReceivedArguments
        #expect(addArguments?.participants.isEmpty == true)
        let removeArguments = conversationRepository
            .removeParticipantsParticipantsMeetingMemberFromConversationIDQualifiedIDVoidReceivedArguments
        #expect(removeArguments?.participants.isEmpty == true)
    }

}
