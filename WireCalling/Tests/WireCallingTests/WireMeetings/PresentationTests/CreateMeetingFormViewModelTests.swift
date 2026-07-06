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

import SwiftUI
import Testing
import WireCallingDomain
import WireCallingDomainSupport
import WireFoundation
import WireFoundationSupport

@testable import WireCallingUI

@MainActor
struct CreateMeetingFormViewModelTests {

    private let instantUseCaseMock = CreateInstantMeetingUseCaseProtocolMock()
    private let scheduledUseCaseMock = CreateScheduledMeetingUseCaseProtocolMock()
    private let dateProviderMock = CurrentDateProvidingMock()
    private let viewModel: CreateMeetingFormViewModel

    private let member = Member(
        qualifiedID: QualifiedID(id: UUID(), domain: "example.com"),
        name: "Katie Armstrong",
        handle: "katie"
    )

    private let meeting = Meeting(
        id: QualifiedID(id: UUID(), domain: "example.com"),
        title: "Team Standup",
        start: .distantPast,
        end: .distantFuture,
        recurrence: nil,
        members: [],
        conversationID: QualifiedID(id: UUID(), domain: "example.com")
    )

    init() {
        dateProviderMock.now = try! Date.ISO8601FormatStyle().parse("2026-07-06T14:18:00+02:00")
        self.viewModel = CreateMeetingFormViewModel(
            mode: .instant,
            memberRepository: MemberRepositoryProtocolMock(),
            createInstantMeetingUseCase: instantUseCaseMock,
            createScheduledMeetingUseCase: scheduledUseCaseMock,
            currentDateProvider: dateProviderMock
        )
    }

    private func makeViewModel(
        mode: CreateMeetingFormViewModel.Mode,
        onSuccess: @escaping (Meeting) -> Void = { _ in }
    ) -> CreateMeetingFormViewModel {
        CreateMeetingFormViewModel(
            mode: mode,
            memberRepository: MemberRepositoryProtocolMock(),
            createInstantMeetingUseCase: instantUseCaseMock,
            createScheduledMeetingUseCase: scheduledUseCaseMock,
            currentDateProvider: dateProviderMock,
            onSuccess: onSuccess
        )
    }

    // MARK: - isNextButtonEnabled Tests

    @Test("isNextButtonEnabled is false with empty title")
    func isNextButtonEnabled_EmptyTitle() {
        // Given
        viewModel.meetingTitle = ""

        // Then
        #expect(viewModel.isNextButtonEnabled == false)
    }

    @Test("isNextButtonEnabled is false with whitespace-only title")
    func isNextButtonEnabled_WhitespaceTitle() {
        // Given
        viewModel.meetingTitle = "   "

        // Then
        #expect(viewModel.isNextButtonEnabled == false)
    }

    @Test("isNextButtonEnabled is true with valid title")
    func isNextButtonEnabled_EmptyPasswords() {
        // Given
        viewModel.meetingTitle = "Team Standup"

        // Then
        #expect(viewModel.isNextButtonEnabled == true)
    }

    @Test("changing meetingTitle updates isNextButtonEnabled")
    func changingMeetingTitle_UpdatesButton() {
        // Given
        viewModel.meetingTitle = ""
        #expect(viewModel.isNextButtonEnabled == false)

        // When
        viewModel.meetingTitle = "New Meeting"

        // Then
        #expect(viewModel.isNextButtonEnabled == true)
    }

    @Test("trimming whitespace from title is handled correctly")
    func trimmingWhitespace() {
        // Given
        viewModel.meetingTitle = "  Meeting Title  "

        // Then
        #expect(viewModel.isNextButtonEnabled == true)
    }

    // MARK: - submit Tests

    @Test("submit in instant mode invokes the instant use case and calls onSuccess")
    func submit_InstantMode_Success() async {
        // Given
        var receivedMeeting: Meeting?
        let viewModel = makeViewModel(mode: .instant) { receivedMeeting = $0 }
        viewModel.meetingTitle = "Team Standup"
        viewModel.selectedMembers = [member]
        instantUseCaseMock.invokeTitleStringParticipantsMemberMeetingReturnValue = meeting

        // When
        viewModel.submit()
        #expect(viewModel.isLoading == true)
        await viewModel.submitTask?.value

        // Then
        #expect(instantUseCaseMock.invokeTitleStringParticipantsMemberMeetingCallsCount == 1)
        let arguments = instantUseCaseMock.invokeTitleStringParticipantsMemberMeetingReceivedArguments
        #expect(arguments?.title == "Team Standup")
        #expect(arguments?.participants == [member])
        #expect(receivedMeeting == meeting)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }

    @Test("submit in scheduled mode invokes the scheduled use case with the form values")
    func submit_ScheduledMode_Success() async {
        // Given
        var receivedMeeting: Meeting?
        let viewModel = makeViewModel(mode: .scheduled) { receivedMeeting = $0 }
        viewModel.meetingTitle = "Planning"
        viewModel.repeatOption = .weekly
        scheduledUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReturnValue = meeting

        // When
        viewModel.submit()
        await viewModel.submitTask?.value

        // Then
        #expect(
            scheduledUseCaseMock
                .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingCallsCount == 1
        )
        let arguments = scheduledUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceMeetingReceivedArguments
        #expect(arguments?.title == "Planning")
        #expect(arguments?.startTime == viewModel.startDate)
        #expect(arguments?.endTime == viewModel.endDate)
        #expect(arguments?.recurrence == MeetingRecurrence(frequency: .weekly, interval: 1))
        #expect(receivedMeeting == meeting)
        #expect(viewModel.isLoading == false)
    }

    @Test("submit exposes the error and does not call onSuccess when the use case fails")
    func submit_Failure_SetsError() async {
        // Given
        var onSuccessCalled = false
        let viewModel = makeViewModel(mode: .instant) { _ in onSuccessCalled = true }
        viewModel.meetingTitle = "Team Standup"
        instantUseCaseMock.invokeTitleStringParticipantsMemberMeetingThrowableError = URLError(.badServerResponse)

        // When
        viewModel.submit()
        await viewModel.submitTask?.value

        // Then
        #expect(viewModel.error != nil)
        #expect(viewModel.isLoading == false)
        #expect(onSuccessCalled == false)
    }

    @Test("submit while a submission is in flight is ignored")
    func submit_WhileLoading_IsIgnored() async {
        // Given
        let viewModel = makeViewModel(mode: .instant)
        viewModel.meetingTitle = "Team Standup"
        instantUseCaseMock.invokeTitleStringParticipantsMemberMeetingReturnValue = meeting

        // When
        viewModel.submit()
        viewModel.submit()
        await viewModel.submitTask?.value

        // Then
        #expect(instantUseCaseMock.invokeTitleStringParticipantsMemberMeetingCallsCount == 1)
    }

}
