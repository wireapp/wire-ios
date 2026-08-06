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
struct MeetingFormViewModelTests {

    private let createMeetingUseCaseMock = CreateMeetingUseCaseProtocolMock()
    private let updateMeetingUseCaseMock = UpdateMeetingUseCaseProtocolMock()
    private let dateProviderMock = CurrentDateProvidingMock()
    private let viewModel: MeetingFormViewModel

    private let member = MeetingMember(
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
        dateProviderMock.now = try! Date.ISO8601FormatStyle().parse("2026-07-06T14:18:00+02:00")
        self.viewModel = MeetingFormViewModel(
            mode: .instant,
            searchMembersUseCase: SearchMembersUseCaseProtocolMock(),
            createMeetingUseCase: createMeetingUseCaseMock,
            updateMeetingUseCase: updateMeetingUseCaseMock,
            currentDateProvider: dateProviderMock
        )
    }

    private func makeViewModel(
        mode: MeetingFormViewModel.Mode,
        onSuccess: @escaping (Meeting) -> Void = { _ in }
    ) -> MeetingFormViewModel {
        MeetingFormViewModel(
            mode: mode,
            searchMembersUseCase: SearchMembersUseCaseProtocolMock(),
            createMeetingUseCase: createMeetingUseCaseMock,
            updateMeetingUseCase: updateMeetingUseCaseMock,
            currentDateProvider: dateProviderMock,
            onSuccess: onSuccess
        )
    }

    /// A meeting fixture for edit mode, starting tomorrow relative to the
    /// mocked current date unless a start date is given.
    private func makeEditableMeeting(
        start: Date? = nil,
        recurrence: MeetingRecurrence? = MeetingRecurrence(frequency: .weekly, interval: 2)
    ) -> Meeting {
        let start = start ?? dateProviderMock.now.addingTimeInterval(86_400)
        return Meeting(
            id: QualifiedID(id: UUID(), domain: "example.com"),
            title: "Design Review",
            start: start,
            end: start.addingTimeInterval(TimeInterval.oneHour),
            recurrence: recurrence,
            conversation: MeetingConversation(participants: [member]),
            conversationID: QualifiedID(id: UUID(), domain: "example.com"),
            creatorID: QualifiedID(id: UUID(), domain: "example.com")
        )
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) throws -> Date {
        var components = DateComponents()
        components.calendar = .current
        components.timeZone = Calendar.current.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.nanosecond = 0

        return try #require(components.date)
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

    // MARK: - Date Validation Tests

    @Test("startDateRange starts at the beginning of the current day")
    func startDateRange_StartsAtBeginningOfCurrentDay() {
        #expect(viewModel.startDateRange.lowerBound == Calendar.current.startOfDay(for: dateProviderMock.now))
    }

    @Test("scheduled mode starts at the next quarter-hour boundary")
    func scheduledMode_StartsAtNextQuarterHourBoundary() throws {
        // Given
        dateProviderMock.now = try makeDate(year: 2026, month: 7, day: 6, hour: 14, minute: 2)

        // When
        let viewModel = makeViewModel(mode: .scheduled)

        // Then
        let expectedStartDate = try makeDate(year: 2026, month: 7, day: 6, hour: 14, minute: 15)
        #expect(viewModel.startDate == expectedStartDate)
    }

    @Test("endDateRange starts after the start date")
    func endDateRange_StartsAfterStartDate() {
        #expect(viewModel.endDateRange.lowerBound > viewModel.startDate)
    }

    @Test("endDateRange ends at 23:45 on the start date")
    func endDateRange_EndsAtLatestAvailableEndTime() throws {
        // Given
        viewModel.startDate = try makeDate(year: 2026, month: 7, day: 6, hour: 10, minute: 0)

        // Then
        let expectedEndDate = try makeDate(year: 2026, month: 7, day: 6, hour: 23, minute: 45)
        #expect(viewModel.endDateRange.upperBound == expectedEndDate)
    }

    @Test("setting an end date before the start date is corrected to be after the start date")
    func endDateBeforeStartDate_IsCorrected() {
        // When
        viewModel.endDate = viewModel.startDate.addingTimeInterval(-3600)

        // Then
        #expect(viewModel.endDate > viewModel.startDate)
    }

    @Test("setting an end date past midnight is capped to 23:45 on the start date")
    func endDatePastMidnight_IsCappedToLatestAvailableEndTime() throws {
        // Given
        viewModel.startDate = try makeDate(year: 2026, month: 7, day: 6, hour: 22, minute: 30)

        // When
        viewModel.endDate = try makeDate(year: 2026, month: 7, day: 7, hour: 0, minute: 30)

        // Then
        let expectedEndDate = try makeDate(year: 2026, month: 7, day: 6, hour: 23, minute: 45)
        #expect(viewModel.endDate == expectedEndDate)
    }

    @Test("changing the start date keeps the end date after the start date")
    func changingStartDate_KeepsEndDateAfterStartDate() {
        // When
        viewModel.startDate = viewModel.startDate.addingTimeInterval(86_400)

        // Then
        #expect(viewModel.endDate > viewModel.startDate)
    }

    @Test("changing the start date moves the end date to the same day")
    func changingStartDate_MovesEndDateToSameDay() throws {
        // Given
        viewModel.startDate = try makeDate(year: 2026, month: 7, day: 6, hour: 14, minute: 30)
        viewModel.endDate = try makeDate(year: 2026, month: 7, day: 6, hour: 15, minute: 30)

        // When
        viewModel.startDate = try makeDate(year: 2026, month: 7, day: 7, hour: 14, minute: 30)

        // Then
        let expectedEndDate = try makeDate(year: 2026, month: 7, day: 7, hour: 15, minute: 30)
        #expect(viewModel.endDate == expectedEndDate)
    }

    @Test("changing the start time to 23:30 caps the end time at 23:45")
    func changingStartTimeTo2330_CapsEndTimeAt2345() throws {
        // Given
        viewModel.startDate = try makeDate(year: 2026, month: 7, day: 6, hour: 14, minute: 30)
        viewModel.endDate = try makeDate(year: 2026, month: 7, day: 6, hour: 15, minute: 30)

        // When
        viewModel.startDate = try makeDate(year: 2026, month: 7, day: 6, hour: 23, minute: 30)

        // Then
        let expectedEndDate = try makeDate(year: 2026, month: 7, day: 6, hour: 23, minute: 45)
        #expect(viewModel.endDate == expectedEndDate)
    }

    @Test("changing the start time to 23:45 makes the end time match")
    func changingStartTimeTo2345_MakesEndTimeMatch() throws {
        // Given
        viewModel.startDate = try makeDate(year: 2026, month: 7, day: 6, hour: 14, minute: 30)
        viewModel.endDate = try makeDate(year: 2026, month: 7, day: 6, hour: 15, minute: 30)

        // When
        viewModel.startDate = try makeDate(year: 2026, month: 7, day: 6, hour: 23, minute: 45)

        // Then
        #expect(viewModel.endDate == viewModel.startDate)
    }

    // MARK: - submit Tests

    @Test("submit in instant mode creates a meeting starting now and calls onSuccess")
    func submit_InstantMode_Success() async {
        // Given
        var receivedMeeting: Meeting?
        let viewModel = makeViewModel(mode: .instant) { receivedMeeting = $0 }
        viewModel.meetingTitle = "Team Standup"
        viewModel.selectedMembers = [member]
        createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberMeetingReturnValue =
            meeting

        // When
        await viewModel.submit()

        // Then
        #expect(
            createMeetingUseCaseMock
                .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberMeetingCallsCount ==
                1
        )
        let arguments = createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberMeetingReceivedArguments
        #expect(arguments?.title == "Team Standup")
        #expect(arguments?.startTime == dateProviderMock.now)
        #expect(arguments?.endTime == dateProviderMock.now.addingTimeInterval(TimeInterval.oneHour))
        #expect(arguments?.recurrence == nil)
        #expect(arguments?.participants == [member])
        #expect(receivedMeeting == meeting)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.hasError == false)
    }

    @Test("submit in scheduled mode creates a meeting with the form values")
    func submit_ScheduledMode_Success() async {
        // Given
        var receivedMeeting: Meeting?
        let viewModel = makeViewModel(mode: .scheduled) { receivedMeeting = $0 }
        viewModel.meetingTitle = "Planning"
        viewModel.repeatOption = .weekly
        viewModel.selectedMembers = [member]
        createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberMeetingReturnValue =
            meeting

        // When
        await viewModel.submit()

        // Then
        #expect(
            createMeetingUseCaseMock
                .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberMeetingCallsCount ==
                1
        )
        let arguments = createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberMeetingReceivedArguments
        #expect(arguments?.title == "Planning")
        #expect(arguments?.startTime == viewModel.startDate)
        #expect(arguments?.endTime == viewModel.endDate)
        #expect(arguments?.recurrence == MeetingRecurrence(frequency: .weekly, interval: 1))
        #expect(arguments?.participants == [member])
        #expect(receivedMeeting == meeting)
        #expect(viewModel.isLoading == false)
    }

    @Test("submit sets the error flag and does not call onSuccess when the use case fails")
    func submit_Failure_SetsError() async {
        // Given
        var onSuccessCalled = false
        let viewModel = makeViewModel(mode: .instant) { _ in onSuccessCalled = true }
        viewModel.meetingTitle = "Team Standup"
        createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberMeetingThrowableError =
            URLError(.badServerResponse)

        // When
        await viewModel.submit()

        // Then
        #expect(viewModel.hasError == true)
        #expect(viewModel.isLoading == false)
        #expect(onSuccessCalled == false)
    }

    // MARK: - Edit Mode Tests

    @Test(
        "availableRepeatOptions hides yearly unless yearly is selected",
        arguments: [
            (
                MeetingRepeatOption.never,
                [.never, .daily, .weekly, .every2Weeks, .monthly]
            ),
            (
                MeetingRepeatOption.yearly,
                [.never, .daily, .weekly, .every2Weeks, .monthly, .yearly]
            )
        ] as [(MeetingRepeatOption, [MeetingRepeatOption])]
    )
    func availableRepeatOptions_HidesYearlyUnlessSelected(
        repeatOption: MeetingRepeatOption,
        expectedOptions: [MeetingRepeatOption]
    ) {
        // Given
        let viewModel = makeViewModel(mode: .scheduled)
        viewModel.repeatOption = repeatOption

        // Then
        #expect(viewModel.availableRepeatOptions == expectedOptions)
    }

    @Test("edit mode pre-fills the form with the meeting's values")
    func editMode_PrefillsForm() {
        // Given
        let meeting = makeEditableMeeting()

        // When
        let viewModel = makeViewModel(mode: .edit(meeting))

        // Then
        #expect(viewModel.meetingTitle == meeting.title)
        #expect(viewModel.startDate == meeting.start)
        #expect(viewModel.endDate == meeting.end)
        #expect(viewModel.repeatOption == .every2Weeks)
        #expect(viewModel.selectedMembers == [member])
    }

    @Test(
        "edit mode maps the meeting's recurrence to the matching repeat option",
        arguments: [
            (nil, MeetingRepeatOption.never),
            (MeetingRecurrence(frequency: .daily, interval: 1), .daily),
            (MeetingRecurrence(frequency: .weekly, interval: 1), .weekly),
            (MeetingRecurrence(frequency: .weekly, interval: 2), .every2Weeks),
            (MeetingRecurrence(frequency: .monthly, interval: 1), .monthly),
            (MeetingRecurrence(frequency: .yearly, interval: 1), .yearly)
        ] as [(MeetingRecurrence?, MeetingRepeatOption)]
    )
    func editMode_MapsRecurrence(recurrence: MeetingRecurrence?, expected: MeetingRepeatOption) {
        // When
        let viewModel = makeViewModel(mode: .edit(makeEditableMeeting(recurrence: recurrence)))

        // Then
        #expect(viewModel.repeatOption == expected)
    }

    @Test("startDateRange allows the original start day when editing a meeting that started in the past")
    func startDateRange_EditModePastMeeting() {
        // Given
        let meeting = makeEditableMeeting(
            start: dateProviderMock.now.addingTimeInterval(-3 * 86_400),
            recurrence: nil
        )

        // When
        let viewModel = makeViewModel(mode: .edit(meeting))

        // Then
        #expect(viewModel.startDateRange.lowerBound == Calendar.current.startOfDay(for: meeting.start))
    }

    @Test("edit mode pre-fills recurring meetings that started in the past with the next occurrence")
    func editMode_PastRecurringMeetingUsesNextOccurrence() throws {
        // Given
        let originalStart = try makeDate(year: 2026, month: 7, day: 5, hour: 9, minute: 0)
        let meeting = makeEditableMeeting(
            start: originalStart,
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1)
        )
        let expectedStart = try makeDate(year: 2026, month: 7, day: 7, hour: 9, minute: 0)
        let expectedEnd = try makeDate(year: 2026, month: 7, day: 7, hour: 10, minute: 0)

        // When
        let viewModel = makeViewModel(mode: .edit(meeting))

        // Then
        #expect(viewModel.startDate == expectedStart)
        #expect(viewModel.endDate == expectedEnd)
        #expect(viewModel.startDateRange.lowerBound == Calendar.current.startOfDay(for: dateProviderMock.now))
    }

    @Test("submit in edit mode sends the next occurrence time for a recurring meeting that started in the past")
    func submit_EditModePastRecurringMeeting_UsesNextOccurrenceTime() async throws {
        // Given
        let originalStart = try makeDate(year: 2026, month: 7, day: 5, hour: 9, minute: 0)
        let original = makeEditableMeeting(
            start: originalStart,
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1)
        )
        let viewModel = makeViewModel(mode: .edit(original))
        updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberMeetingReturnValue =
            meeting
        let expectedStart = try makeDate(year: 2026, month: 7, day: 7, hour: 9, minute: 0)
        let expectedEnd = try makeDate(year: 2026, month: 7, day: 7, hour: 10, minute: 0)

        // When
        await viewModel.submit()

        // Then
        let arguments = updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberMeetingReceivedArguments
        #expect(arguments?.meeting == original)
        #expect(arguments?.startTime == expectedStart)
        #expect(arguments?.endTime == expectedEnd)
    }

    @Test("submit in edit mode updates the meeting with the form values and calls onSuccess")
    func submit_EditMode_Success() async {
        // Given
        var receivedMeeting: Meeting?
        let original = makeEditableMeeting()
        let viewModel = makeViewModel(mode: .edit(original)) { receivedMeeting = $0 }
        viewModel.meetingTitle = "Updated Title"
        viewModel.repeatOption = .daily
        viewModel.selectedMembers = []
        updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberMeetingReturnValue =
            meeting

        // When
        await viewModel.submit()

        // Then
        let arguments = updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberMeetingReceivedArguments
        #expect(arguments?.meeting == original)
        #expect(arguments?.title == "Updated Title")
        #expect(arguments?.startTime == viewModel.startDate)
        #expect(arguments?.endTime == viewModel.endDate)
        #expect(arguments?.recurrence == MeetingRecurrence(frequency: .daily, interval: 1))
        #expect(arguments?.participants.isEmpty == true)
        #expect(
            createMeetingUseCaseMock
                .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberMeetingCallsCount ==
                0
        )
        #expect(receivedMeeting == meeting)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.hasError == false)
    }

    @Test("submit in edit mode sets the error flag when the use case fails")
    func submit_EditMode_Failure_SetsError() async {
        // Given
        var onSuccessCalled = false
        let viewModel = makeViewModel(mode: .edit(makeEditableMeeting())) { _ in onSuccessCalled = true }
        updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberMeetingThrowableError =
            URLError(.badServerResponse)

        // When
        await viewModel.submit()

        // Then
        #expect(viewModel.hasError == true)
        #expect(viewModel.isLoading == false)
        #expect(onSuccessCalled == false)
    }

    @Test("submit while a submission is in flight is ignored")
    func submit_WhileLoading_IsIgnored() async {
        // Given
        let viewModel = makeViewModel(mode: .instant)
        viewModel.meetingTitle = "Team Standup"
        let meeting = meeting
        createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberMeetingClosure =
            { _, _, _, _, _ in
                // Suspend so the second submission starts while the first is in flight.
                try await Task.sleep(for: .milliseconds(10))
                return meeting
            }

        // When
        let firstSubmission = Task { await viewModel.submit() }
        let secondSubmission = Task { await viewModel.submit() }
        await firstSubmission.value
        await secondSubmission.value

        // Then
        #expect(
            createMeetingUseCaseMock
                .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberMeetingCallsCount ==
                1
        )
        #expect(viewModel.isLoading == false)
    }

}
