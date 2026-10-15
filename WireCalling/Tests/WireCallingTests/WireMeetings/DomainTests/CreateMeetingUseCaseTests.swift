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

@Suite("CreateMeetingUseCase Tests")
struct CreateMeetingUseCaseTests {

    private let meetingRepository = MeetingRepositoryProtocolMock()
    private let conversationRepository = MeetingConversationRepositoryProtocolMock()
    private let useCase: CreateMeetingUseCase

    private let participant = MeetingMember(
        qualifiedID: QualifiedID(id: UUID(), domain: "example.com"),
        name: "Katie Armstrong",
        handle: "katie",
        isSelfUser: false,
        initials: "",
        accentColor: .default,
        avatarImageData: nil
    )

    private let meeting = Meeting(
        id: QualifiedID(id: UUID(), domain: "example.com"),
        title: "Team Standup",
        start: .distantPast,
        end: .distantFuture,
        recurrence: nil,
        conversationID: QualifiedID(id: UUID(), domain: "example.com"),
        creatorID: QualifiedID(id: UUID(), domain: "example.com")
    )

    init() {
        self.useCase = CreateMeetingUseCase(
            meetingRepository: meetingRepository,
            conversationRepository: conversationRepository
        )
        meetingRepository
            .createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringMeetingCreationResultReturnValue =
            MeetingCreationResult(meeting: meeting, link: nil)
    }

    @Test("invoke creates the meeting via the repository and returns it")
    func invokeCreatesMeeting() async throws {
        // Given
        meetingRepository
            .createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringMeetingCreationResultReturnValue =
            MeetingCreationResult(
                meeting: meeting,
                link: URL(string: "https://wire.example/meeting-join/?key=server&code=link")
            )
        let recurrence = MeetingRecurrence(frequency: .weekly, interval: 1)

        // When
        let result = try await useCase.invoke(
            title: "Team Standup",
            startTime: meeting.start,
            endTime: meeting.end,
            recurrence: recurrence,
            type: .scheduled,
            password: " exact password ",
            participants: [participant]
        )

        // Then
        let arguments = meetingRepository
            .createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringMeetingCreationResultReceivedArguments
        #expect(arguments?.title == "Team Standup")
        #expect(arguments?.startTime == meeting.start)
        #expect(arguments?.endTime == meeting.end)
        #expect(arguments?.recurrence == recurrence)
        #expect(arguments?.type == .scheduled)
        #expect(arguments?.password == " exact password ")
        #expect(result.meeting == meeting)
        #expect(result.link?.absoluteString == "https://wire.example/meeting-join/?key=server&code=link")
    }

    @Test("invoke pulls the meeting's conversation and adds the participants to it")
    func invokePullsConversationAndAddsParticipants() async throws {
        // When
        _ = try await useCase.invoke(
            title: "Team Standup",
            startTime: meeting.start,
            endTime: meeting.end,
            recurrence: nil,
            type: .scheduled,
            password: nil,
            participants: [participant]
        )

        // Then
        let pullArguments = conversationRepository.pullConversationIdUUIDDomainStringVoidReceivedArguments
        #expect(pullArguments?.id == meeting.conversationID.id)
        #expect(pullArguments?.domain == meeting.conversationID.domain)
        let addArguments = conversationRepository
            .addParticipantsParticipantsMeetingMemberToConversationIDQualifiedIDVoidReceivedArguments
        #expect(addArguments?.participants == [participant])
        #expect(addArguments?.conversationID == meeting.conversationID)
    }

    @Test("invoke names the meeting's conversation after the meeting title")
    func invokeSetsConversationName() async throws {
        // When
        _ = try await useCase.invoke(
            title: "Team Standup",
            startTime: meeting.start,
            endTime: meeting.end,
            recurrence: nil,
            type: .scheduled,
            password: nil,
            participants: [participant]
        )

        // Then
        let nameArguments = conversationRepository
            .setConversationNameNameStringForConversationIDQualifiedIDVoidReceivedArguments
        #expect(nameArguments?.name == "Team Standup")
        #expect(nameArguments?.conversationID == meeting.conversationID)
    }

    @Test("invoke stores the meeting again after its conversation was pulled")
    func invokeStoresMeetingAfterPullingConversation() async throws {
        // When
        _ = try await useCase.invoke(
            title: "Team Standup",
            startTime: meeting.start,
            endTime: meeting.end,
            recurrence: nil,
            type: .scheduled,
            password: nil,
            participants: []
        )

        // Then
        #expect(meetingRepository.storeMeetingMeetingMeetingVoidReceivedInvocations == [meeting])
        #expect(conversationRepository.pullConversationIdUUIDDomainStringVoidCallsCount == 1)
    }

    @Test("invoke stores the created meeting before reporting participants who could not be added")
    func invokeStoresMeetingWhenParticipantsCouldNotBeAdded() async {
        conversationRepository
            .addParticipantsParticipantsMeetingMemberToConversationIDQualifiedIDVoidThrowableError =
            MeetingParticipantsError.failedToAddParticipants([participant])

        await #expect(throws: CreateMeetingUseCaseError.participantsNotAdded(
            result: MeetingCreationResult(meeting: meeting, link: nil),
            participants: [participant]
        )) {
            _ = try await useCase.invoke(
                title: meeting.title,
                startTime: meeting.start,
                endTime: meeting.end,
                recurrence: nil,
                type: .scheduled,
                password: nil,
                participants: [participant]
            )
        }

        #expect(meetingRepository.storeMeetingMeetingMeetingVoidReceivedInvocations == [meeting])
    }

    @Test("invoke does not touch the conversation when creating the meeting fails")
    func invokeFailsWhenCreatingMeetingFails() async {
        // Given
        meetingRepository
            .createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringMeetingCreationResultThrowableError =
            URLError(.badServerResponse)

        // When / Then
        await #expect(throws: URLError.self) {
            _ = try await useCase.invoke(
                title: "Team Standup",
                startTime: meeting.start,
                endTime: meeting.end,
                recurrence: nil,
                type: .scheduled,
                password: nil,
                participants: [participant]
            )
        }
        #expect(conversationRepository.pullConversationIdUUIDDomainStringVoidCallsCount == 0)
        #expect(conversationRepository
            .setConversationNameNameStringForConversationIDQualifiedIDVoidCallsCount == 0)
        #expect(conversationRepository
            .addParticipantsParticipantsMeetingMemberToConversationIDQualifiedIDVoidCallsCount == 0)
        #expect(meetingRepository.storeMeetingMeetingMeetingVoidReceivedInvocations.isEmpty)
    }

}
