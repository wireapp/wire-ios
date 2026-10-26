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
import UIKit
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
        supportsMeetingLinks: Bool = false,
        onSuccess: @escaping (Meeting) -> Void = { _ in }
    ) -> MeetingFormViewModel {
        let searchMembersUseCase = SearchMembersUseCaseProtocolMock()
        searchMembersUseCase.invokeQueryStringMeetingMemberReturnValue = []
        return MeetingFormViewModel(
            mode: mode,
            searchMembersUseCase: searchMembersUseCase,
            createMeetingUseCase: createMeetingUseCaseMock,
            updateMeetingUseCase: updateMeetingUseCaseMock,
            currentDateProvider: dateProviderMock,
            supportsMeetingLinks: supportsMeetingLinks,
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

    @Test("scheduled startDateRange begins at the first future quarter-hour")
    func startDateRange_ScheduledModeStartsAtFirstFutureQuarterHour() throws {
        dateProviderMock.now = try makeDate(year: 2026, month: 7, day: 6, hour: 14, minute: 18)
        let viewModel = makeViewModel(mode: .scheduled)
        let nextQuarterHour = try makeDate(year: 2026, month: 7, day: 6, hour: 14, minute: 30)
        #expect(viewModel.startDateRange.lowerBound == nextQuarterHour)

        dateProviderMock.now = try makeDate(year: 2026, month: 7, day: 6, hour: 23, minute: 45)
        let startOfNextDay = try makeDate(year: 2026, month: 7, day: 7, hour: 0, minute: 0)
        #expect(viewModel.startDateRange.lowerBound == startOfNextDay)

        let exactBoundaryViewModel = makeViewModel(mode: .scheduled)
        #expect(exactBoundaryViewModel.startDate == startOfNextDay)
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

    @Test("a late scheduled default moves to tomorrow when no valid end remains", arguments: [30, 44, 45, 50])
    func scheduledMode_LateDefaultStartsTomorrow(minute: Int) throws {
        dateProviderMock.now = try makeDate(year: 2026, month: 7, day: 6, hour: 23, minute: minute)
        let viewModel = makeViewModel(mode: .scheduled)
        let expectedStart = try makeDate(year: 2026, month: 7, day: 7, hour: 0, minute: 0)
        let expectedEnd = try makeDate(year: 2026, month: 7, day: 7, hour: 1, minute: 0)

        #expect(viewModel.startDate == expectedStart)
        #expect(viewModel.startDateRange.lowerBound == expectedStart)
        #expect(viewModel.endDate == expectedEnd)
    }

    @Test("a scheduled default can use the last valid 15-minute range")
    func scheduledMode_LastValidDefaultStaysToday() throws {
        dateProviderMock.now = try makeDate(year: 2026, month: 7, day: 6, hour: 23, minute: 29)
        let viewModel = makeViewModel(mode: .scheduled)
        let expectedStart = try makeDate(year: 2026, month: 7, day: 6, hour: 23, minute: 30)
        let expectedEnd = try makeDate(year: 2026, month: 7, day: 6, hour: 23, minute: 45)

        #expect(viewModel.startDate == expectedStart)
        #expect(viewModel.endDate == expectedEnd)
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

    @Test("Meet Now starts at submission time and lasts one hour", arguments: [
        (12, 7, 23), (23, 20, 23), (23, 45, 0), (23, 59, 59)
    ])
    func submit_InstantMode_Success_TC_11981(hour: Int, minute: Int, second: Int) async throws {
        // Given
        var receivedMeeting: Meeting?
        let viewModel = makeViewModel(mode: .instant, supportsMeetingLinks: true) { receivedMeeting = $0 }
        // Advance the clock after opening the form to check the actual submission time.
        dateProviderMock.now = try makeDate(year: 2026, month: 7, day: 7, hour: hour, minute: minute)
            .addingTimeInterval(TimeInterval(second))
        viewModel.meetingTitle = "Team Standup"
        #expect(!viewModel.canSetPassword)
        viewModel.password = "ignored"
        viewModel.invitedEmails = ["ignored@example.com"]
        viewModel.selectedMembers = [member]
        createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringParticipantsMeetingMemberInvitedEmailsStringMeetingCreationResultReturnValue =
            MeetingCreationResult(meeting: meeting, link: URL(string: "https://wire.example/meeting-join/"))

        // When
        await viewModel.submit()

        // Then
        #expect(
            createMeetingUseCaseMock
                .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringParticipantsMeetingMemberInvitedEmailsStringMeetingCreationResultCallsCount ==
                1
        )
        let arguments = createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringParticipantsMeetingMemberInvitedEmailsStringMeetingCreationResultReceivedArguments
        #expect(arguments?.invitedEmails.isEmpty == true)
        #expect(!viewModel.makeMemberSelectionViewModel().allowsEmailInvitations)
        #expect(arguments?.type == .immediate)
        #expect(arguments?.password == nil)
        #expect(viewModel.password.isEmpty)
        #expect(arguments?.title == "Team Standup")
        #expect(arguments?.startTime == dateProviderMock.now)
        #expect(arguments?.endTime == dateProviderMock.now.addingTimeInterval(TimeInterval.oneHour))
        #expect(arguments?.recurrence == nil)
        #expect(arguments?.participants == [member])
        #expect(receivedMeeting == meeting)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.hasError == false)
    }

    @Test(
        "submit in scheduled mode creates a meeting with the form values",
        arguments: [
            (MeetingRepeatOption.weekly, MeetingRecurrence(frequency: .weekly, interval: 1)),
            (MeetingRepeatOption.everyFourWeeks, MeetingRecurrence(frequency: .weekly, interval: 4)),
            (MeetingRepeatOption.monthly, MeetingRecurrence(frequency: .monthly, interval: 1))
        ] as [(MeetingRepeatOption, MeetingRecurrence)]
    )
    func submit_ScheduledMode_Success(
        repeatOption: MeetingRepeatOption,
        expectedRecurrence: MeetingRecurrence
    ) async {
        // Given
        var receivedMeeting: Meeting?
        let viewModel = makeViewModel(mode: .scheduled, supportsMeetingLinks: true) { receivedMeeting = $0 }
        viewModel.meetingTitle = "Planning"
        viewModel.password = " exact Password1! "
        viewModel.confirmPassword = viewModel.password
        viewModel.invitedEmails = ["guest@example.com"]
        viewModel.repeatOption = repeatOption
        viewModel.selectedMembers = [member]
        createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringParticipantsMeetingMemberInvitedEmailsStringMeetingCreationResultReturnValue =
            MeetingCreationResult(
                meeting: meeting,
                link: URL(string: "https://wire.example/meeting-join/?key=server&code=link")
            )

        // When
        await viewModel.submit()

        // Then
        #expect(
            createMeetingUseCaseMock
                .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringParticipantsMeetingMemberInvitedEmailsStringMeetingCreationResultCallsCount ==
                1
        )
        let arguments = createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringParticipantsMeetingMemberInvitedEmailsStringMeetingCreationResultReceivedArguments
        #expect(arguments?.invitedEmails == ["guest@example.com"])
        #expect(arguments?.type == .scheduled)
        #expect(arguments?.password == " exact Password1! ")
        #expect(viewModel.password.isEmpty)
        #expect(viewModel.confirmPassword.isEmpty)
        #expect(arguments?.title == "Planning")
        #expect(arguments?.startTime == viewModel.startDate)
        #expect(arguments?.endTime == viewModel.endDate)
        #expect(arguments?.recurrence == expectedRecurrence)
        #expect(arguments?.participants == [member])
        #expect(receivedMeeting == meeting)
        #expect(viewModel.isLoading == false)
    }

    @Test("missing participants are acknowledged without creating another meeting", arguments: [
        MeetingFormViewModel.Mode.instant, .scheduled
    ])
    func submit_ParticipantsNotAdded_ContinuesWithCreatedMeeting(mode: MeetingFormViewModel.Mode) async {
        var completedMeetings: [Meeting] = []
        let viewModel = makeViewModel(mode: mode, supportsMeetingLinks: true) { completedMeetings.append($0) }
        viewModel.password = "Abcdef1!"
        viewModel.confirmPassword = viewModel.password
        createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringParticipantsMeetingMemberInvitedEmailsStringMeetingCreationResultThrowableError =
            CreateMeetingUseCaseError.participantsNotAdded(
                result: MeetingCreationResult(meeting: meeting, link: nil),
                participants: [member]
            )

        await viewModel.submit()

        #expect(viewModel.hasParticipantsNotAddedAlert)
        #expect(viewModel.participantsNotAdded == [member])
        #expect(viewModel.password.isEmpty)
        #expect(viewModel.confirmPassword.isEmpty)
        #expect(viewModel.participantsNotAddedMessage.contains(L10n.Localizable.Meetings.Error.missingLink))
        #expect(!viewModel.hasError)
        #expect(!viewModel.isLoading)
        #expect(completedMeetings.isEmpty)

        await viewModel.submit()
        viewModel.acknowledgeParticipantsNotAdded()
        await viewModel.submit()
        viewModel.acknowledgeParticipantsNotAdded()

        #expect(!viewModel.hasParticipantsNotAddedAlert)
        #expect(completedMeetings == [meeting])
        #expect(createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringParticipantsMeetingMemberInvitedEmailsStringMeetingCreationResultCallsCount ==
            1)
    }

    @Test("submit sets the error flag and does not call onSuccess when the use case fails")
    func submit_Failure_SetsError() async {
        // Given
        var onSuccessCalled = false
        let viewModel = makeViewModel(mode: .instant) { _ in onSuccessCalled = true }
        viewModel.meetingTitle = "Team Standup"
        createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringParticipantsMeetingMemberInvitedEmailsStringMeetingCreationResultThrowableError =
            URLError(.badServerResponse)

        // When
        await viewModel.submit()

        // Then
        #expect(viewModel.hasError == true)
        #expect(viewModel.isLoading == false)
        #expect(onSuccessCalled == false)
    }

    @Test("scheduled passwords require 8–1024 Unicode scalars and all four character classes")
    func passwordValidation() async {
        let viewModel = makeViewModel(mode: .scheduled, supportsMeetingLinks: true)
        viewModel.meetingTitle = "Meeting"
        for unavailableModel in [
            makeViewModel(mode: .instant, supportsMeetingLinks: true),
            makeViewModel(mode: .edit(makeEditableMeeting()), supportsMeetingLinks: true),
            makeViewModel(mode: .scheduled)
        ] {
            unavailableModel.password = "ignored"
            #expect(!unavailableModel.canSetPassword)
            #expect(unavailableModel.isPasswordValid)
            #expect(unavailableModel.passwordsMatch)
        }
        #expect(viewModel.canSetPassword)
        for (password, expected) in [
            ("", true), ("Abcde1!", false), ("Abcdef1!", true),
            ("ABCDEF1!", false), ("abcdef1!", false), ("Abcdefg!", false), ("Abcdef12", false),
            ("Abcdef١!", true), ("Äbcdef1!", true), ("äBCDEF1!", true), ("Abcdef1é", false),
            ("Abcdef1e\u{301}", false),
            ("Abcde1😀", false), ("Abcdef1\n", true), ("Abcd1!e\u{301}", true),
            ("Aa1!" + String(repeating: "e\u{301}", count: 510), true),
            ("Aa1!" + String(repeating: "e\u{301}", count: 510) + "a", false)
        ] {
            viewModel.password = password
            viewModel.confirmPassword = password
            #expect(viewModel.isNextButtonEnabled == expected)
            if !expected { await viewModel.submit() }
        }
        viewModel.password = "Abcdef1!"
        for confirmation in ["", "Abcdef2!"] {
            viewModel.confirmPassword = confirmation
            #expect(!viewModel.isNextButtonEnabled)
            await viewModel.submit()
        }
        viewModel.confirmPassword = viewModel.password
        #expect(viewModel.isNextButtonEnabled)
        viewModel.password = "Abcd1!e\u{301}"
        viewModel.confirmPassword = "Abcd1!é"
        #expect(!viewModel.passwordsMatch)
        #expect(!viewModel.isNextButtonEnabled)
        await viewModel.submit()
        #expect(createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringParticipantsMeetingMemberInvitedEmailsStringMeetingCreationResultCallsCount ==
            0)
    }

    @Test("generate produces valid eight-character passwords and copy uses the current value")
    func generateAndCopyPassword() {
        let viewModel = makeViewModel(mode: .scheduled, supportsMeetingLinks: true)
        let pasteboard = UIPasteboard.withUniqueName()
        defer { UIPasteboard.remove(withName: pasteboard.name) }
        for _ in 0 ..< 64 {
            viewModel.generatePassword()
            #expect(viewModel.password.count == 8)
            #expect(viewModel.isPasswordValid)
            #expect(viewModel.confirmPassword == viewModel.password)
        }
        viewModel.copyPassword(to: pasteboard)
        #expect(pasteboard.string == viewModel.password)
        viewModel.password = "Manual2!"
        #expect(!viewModel.passwordsMatch)
        viewModel.copyPassword(to: pasteboard)
        #expect(pasteboard.string == "Manual2!")
        viewModel.password = ""
        viewModel.copyPassword(to: pasteboard)
        #expect(pasteboard.string?.count == 8)
    }

    @Test("missing-link warnings complete the saved meeting once")
    func submit_MissingLink() async {
        var completedMeetings: [Meeting] = []
        let viewModel = makeViewModel(mode: .instant, supportsMeetingLinks: true) { completedMeetings.append($0) }
        viewModel.meetingTitle = "Meeting"
        viewModel.password = "password"
        createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringParticipantsMeetingMemberInvitedEmailsStringMeetingCreationResultReturnValue =
            MeetingCreationResult(meeting: meeting, link: nil)

        await viewModel.submit()
        #expect(completedMeetings.isEmpty)
        #expect(viewModel.password.isEmpty)
        #expect(createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringParticipantsMeetingMemberInvitedEmailsStringMeetingCreationResultReceivedArguments?
            .password == nil)
        #expect(viewModel.hasError)
        #expect(viewModel.errorMessage.contains(L10n.Localizable.Meetings.Error.missingLink))

        await viewModel.submit()
        var didDismiss = false
        for _ in 0 ..< 2 {
            viewModel.acknowledgeError { didDismiss = true }
            await viewModel.submit()
        }
        #expect(!didDismiss)
        #expect(!viewModel.hasError)
        #expect(completedMeetings == [meeting])
        #expect(createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringParticipantsMeetingMemberInvitedEmailsStringMeetingCreationResultCallsCount ==
            1)
    }

    enum SetupFailure: CaseIterable {
        case conversation
        case participants
        case unknownParticipants
    }

    @Test("post-create setup failures retain missing-link feedback", arguments: SetupFailure.allCases)
    func submit_SetupFailureWithMissingLink(failure: SetupFailure) async {
        let meetingRepository = MeetingRepositoryProtocolMock()
        meetingRepository
            .createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringInvitedEmailsStringMeetingCreationResultReturnValue =
            MeetingCreationResult(meeting: meeting, link: nil)
        let conversationRepository = MeetingConversationRepositoryProtocolMock()
        switch failure {
        case .conversation:
            conversationRepository.pullConversationIdUUIDDomainStringVoidThrowableError = URLError(.badServerResponse)
        case .participants:
            conversationRepository
                .addParticipantsParticipantsMeetingMemberToConversationIDQualifiedIDVoidThrowableError =
                MeetingParticipantsError.failedToSetUpParticipants([member], reasons: [:])
        case .unknownParticipants:
            conversationRepository
                .addParticipantsParticipantsMeetingMemberToConversationIDQualifiedIDVoidThrowableError =
                URLError(.badServerResponse)
        }
        var didComplete = false
        let viewModel = MeetingFormViewModel(
            mode: .instant,
            searchMembersUseCase: SearchMembersUseCaseProtocolMock(),
            createMeetingUseCase: CreateMeetingUseCase(
                meetingRepository: meetingRepository,
                conversationRepository: conversationRepository
            ),
            updateMeetingUseCase: updateMeetingUseCaseMock,
            currentDateProvider: dateProviderMock,
            supportsMeetingLinks: true,
            onSuccess: { _ in didComplete = true }
        )
        viewModel.meetingTitle = meeting.title
        viewModel.selectedMembers = [member]

        await viewModel.submit()
        #expect(viewModel.hasError)
        #expect(viewModel.errorMessage.contains(L10n.Localizable.Meetings.Error.missingLink))
        var didDismiss = false
        viewModel.acknowledgeError { didDismiss = true }
        await viewModel.submit()
        #expect(didDismiss)
        #expect(!didComplete)
        #expect(meetingRepository
            .createMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringInvitedEmailsStringMeetingCreationResultCallsCount ==
            1)
    }

    @Test("email invitations are hidden before API v19")
    func emailInvitationsRequireV19() async {
        for mode in [MeetingFormViewModel.Mode.scheduled, .edit(makeEditableMeeting())] {
            let form = makeViewModel(mode: mode)
            #expect(!form.allowsEmailInvitations)
            #expect(!form.makeMemberSelectionViewModel().allowsEmailInvitations)
            await form.loadInvitedEmails()
        }
        #expect(updateMeetingUseCaseMock.fetchInvitedEmailsForMeetingMeetingStringCallsCount == 0)
    }

    @Test("edit loads email invitees, preserves drafts, and saves only requested changes")
    func editEmailInvitations() async {
        let original = makeEditableMeeting()
        let form = makeViewModel(mode: .edit(original), supportsMeetingLinks: true)
        updateMeetingUseCaseMock
            .fetchInvitedEmailsForMeetingMeetingStringThrowableError = URLError(.notConnectedToInternet)
        await form.loadInvitedEmails()
        #expect(form.hasEmailLoadError)
        #expect(!form.isNextButtonEnabled)
        await form.submit()
        #expect(updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingCallsCount ==
            0)

        updateMeetingUseCaseMock.fetchInvitedEmailsForMeetingMeetingStringThrowableError = nil
        updateMeetingUseCaseMock.fetchInvitedEmailsForMeetingMeetingStringReturnValue = [
            "old@example.com",
            "keep@example.com"
        ]
        await form.loadInvitedEmails()
        #expect(!form.hasEmailLoadError)
        #expect(form.isNextButtonEnabled)
        let picker = form.makeMemberSelectionViewModel()
        #expect(picker.selectedEmails == ["old@example.com", "keep@example.com"])
        picker.removeEmail("old@example.com")
        picker.emailAddress = "new@example.com"
        picker.addEmail()
        #expect(form.invitedEmails == ["old@example.com", "keep@example.com"])
        picker.confirmSelection()
        await form.loadInvitedEmails()
        #expect(form.invitedEmails == ["keep@example.com", "new@example.com"])
        #expect(updateMeetingUseCaseMock.fetchInvitedEmailsForMeetingMeetingStringCallsCount == 2)
        form.selectedMembers = []
        #expect(form.selectedParticipantCount == 2)
        #expect(form.selectedMembersSummary == "keep@example.com, new@example.com")
        updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingReturnValue =
            original
        await form.submit()
        let arguments = updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingReceivedArguments
        #expect(arguments?.emailsToAdd == ["new@example.com"])
        #expect(arguments?.emailsToRemove == ["old@example.com"])
    }

    @Test("partial email save refreshes server state and prevents resubmission", arguments: [false, true])
    func partialEmailSave(refreshFails: Bool) async {
        var completed = false
        let form = makeViewModel(mode: .edit(makeEditableMeeting()), supportsMeetingLinks: true) { _ in
            completed = true
        }
        updateMeetingUseCaseMock.fetchInvitedEmailsForMeetingMeetingStringReturnValue = ["old@example.com"]
        await form.loadInvitedEmails()
        form.invitedEmails = ["new@example.com"]
        updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingThrowableError =
            UpdateMeetingUseCaseError.emailInvitationsFailed(updatedMeeting: meeting)
        updateMeetingUseCaseMock.fetchInvitedEmailsForMeetingMeetingStringReturnValue = [
            "old@example.com",
            "new@example.com"
        ]
        if refreshFails {
            updateMeetingUseCaseMock
                .fetchInvitedEmailsForMeetingMeetingStringThrowableError = URLError(.networkConnectionLost)
            updateMeetingUseCaseMock
                .updateConversationNameForMeetingMeetingVoidThrowableError = URLError(.networkConnectionLost)
        }
        await form.submit()
        if refreshFails {
            #expect(form.hasConversationNameUpdateError)
            #expect(!completed)
            #expect(form.conversationNameErrorMessage.contains(L10n.Localizable.WireMeetings.Schedule.Email.saveFailed))
            updateMeetingUseCaseMock.updateConversationNameForMeetingMeetingVoidThrowableError = nil
            await form.retryConversationNameUpdate()
        }
        #expect(form.hasError && form.dismissAfterError)
        #expect(!completed)
        #expect(form.hasEmailLoadError == refreshFails)
        if !refreshFails { #expect(form.invitedEmails == ["old@example.com", "new@example.com"]) }
        var dismissed = false
        form.acknowledgeError { dismissed = true }
        await form.submit()
        #expect(dismissed)
        #expect(updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingCallsCount ==
            1)
    }

    // MARK: - Edit Mode Tests

    @Test(
        "availableRepeatOptions hides monthly and yearly unless selected",
        arguments: [
            (
                MeetingRepeatOption.never,
                [.never, .daily, .weekly, .everyTwoWeeks, .everyFourWeeks]
            ),
            (
                MeetingRepeatOption.monthly,
                [.never, .daily, .weekly, .everyTwoWeeks, .everyFourWeeks, .monthly]
            ),
            (
                MeetingRepeatOption.yearly,
                [.never, .daily, .weekly, .everyTwoWeeks, .everyFourWeeks, .yearly]
            )
        ] as [(MeetingRepeatOption, [MeetingRepeatOption])]
    )
    func availableRepeatOptions_HidesLegacyOptionsUnlessSelected(
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
        #expect(viewModel.repeatOption == .everyTwoWeeks)
        #expect(viewModel.selectedMembers == [member])
    }

    @Test(
        "edit mode maps the meeting's recurrence to the matching repeat option",
        arguments: [
            (nil, MeetingRepeatOption.never),
            (MeetingRecurrence(frequency: .daily, interval: 1), .daily),
            (MeetingRecurrence(frequency: .weekly, interval: 1), .weekly),
            (MeetingRecurrence(frequency: .weekly, interval: 2), .everyTwoWeeks),
            (MeetingRecurrence(frequency: .weekly, interval: 4), .everyFourWeeks),
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

    @Test("startDateRange starts exactly 24 hours ago when editing", arguments: [false, true])
    func startDateRange_EditModePastMeeting(isRecurring: Bool) {
        // Given
        let meeting = makeEditableMeeting(
            start: dateProviderMock.now.addingTimeInterval(-3 * 86_400),
            recurrence: isRecurring ? MeetingRecurrence(frequency: .daily, interval: 1) : nil
        )

        // When
        let viewModel = makeViewModel(mode: .edit(meeting))

        // Then
        #expect(viewModel.startDateRange.lowerBound == dateProviderMock.now.addingTimeInterval(-86_400))
    }

    @Test("editing an expired non-recurring meeting preserves its dates but prevents submission")
    func editMode_ExpiredNonRecurringMeeting() async {
        let original = makeEditableMeeting(
            start: dateProviderMock.now.addingTimeInterval(-3 * 86_400),
            recurrence: nil
        )
        let viewModel = makeViewModel(mode: .edit(original))

        #expect(viewModel.startDate == original.start)
        #expect(viewModel.startDateRange.contains(viewModel.startDatePickerSelection))
        #expect(viewModel.startDate == original.start)

        await viewModel.submit()

        #expect(viewModel.hasExpiredStartDateError)
        #expect(!viewModel.isLoading)
        let rejectedArguments = updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingReceivedArguments
        #expect(rejectedArguments == nil)
    }

    @Test("the start picker preserves expired dates for display and only accepts allowed dates")
    func startDatePickerSelection_ExpiredMeeting() {
        let original = makeEditableMeeting(
            start: dateProviderMock.now.addingTimeInterval(-3 * 86_400),
            recurrence: nil
        )
        let viewModel = makeViewModel(mode: .edit(original))
        let cutoff = dateProviderMock.now.addingTimeInterval(-86_400)

        #expect(viewModel.startDateRange.lowerBound == cutoff)
        #expect(viewModel.startDatePickerSelection == cutoff)
        #expect(viewModel.startDate == original.start)
        #expect(viewModel.endDate == original.end)

        viewModel.startDatePickerSelection = cutoff.addingTimeInterval(-1)
        #expect(viewModel.startDate == original.start)
        #expect(viewModel.endDate == original.end)

        viewModel.startDatePickerSelection = cutoff
        #expect(viewModel.startDate == cutoff)
        #expect(viewModel.endDate == cutoff.addingTimeInterval(TimeInterval.oneHour))
    }

    @Test("the start picker retains valid selections and rejects values that expire before selection")
    func startDatePickerSelection_RechecksWindow() {
        let original = makeEditableMeeting(start: dateProviderMock.now.addingTimeInterval(-3600))
        let viewModel = makeViewModel(mode: .edit(original))
        #expect(viewModel.startDatePickerSelection == original.start)

        let oldCutoff = viewModel.startDateRange.lowerBound
        dateProviderMock.now = dateProviderMock.now.addingTimeInterval(1)
        viewModel.startDatePickerSelection = oldCutoff
        #expect(viewModel.startDate == original.start)

        viewModel.startDatePickerSelection = dateProviderMock.now
        #expect(viewModel.startDate == dateProviderMock.now)
    }

    @Test("expired submission clears previous save errors", arguments: [false, true])
    func submit_ExpiredStartClearsPreviousError(conversationNameFailed: Bool) async {
        let original = makeEditableMeeting(start: dateProviderMock.now.addingTimeInterval(-86_400))
        let viewModel = makeViewModel(mode: .edit(original))
        let error: any Error = if conversationNameFailed {
            UpdateMeetingUseCaseError.conversationNameUpdateFailed(updatedMeeting: original)
        } else {
            URLError(.badServerResponse)
        }
        updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingThrowableError =
            error

        await viewModel.submit()
        #expect(viewModel.hasError == !conversationNameFailed)
        #expect(viewModel.hasConversationNameUpdateError == conversationNameFailed)

        dateProviderMock.now = dateProviderMock.now.addingTimeInterval(1)
        await viewModel.submit()

        #expect(viewModel.hasExpiredStartDateError)
        #expect(!viewModel.hasError)
        #expect(!viewModel.hasConversationNameUpdateError)
        #expect(!viewModel.isLoading)
        let callsCount = updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingCallsCount
        #expect(callsCount == 1)
    }

    @Test("saving rechecks the current window and allows retry after correcting the start time")
    func submit_EditModeStartDateExpiresWhileEditing() async {
        let original = makeEditableMeeting(start: dateProviderMock.now.addingTimeInterval(-86_400))
        let viewModel = makeViewModel(mode: .edit(original))
        dateProviderMock.now = dateProviderMock.now.addingTimeInterval(1)

        #expect(viewModel.startDateRange.contains(viewModel.startDatePickerSelection))
        #expect(viewModel.startDate == original.start)
        await viewModel.submit()

        #expect(viewModel.hasExpiredStartDateError)
        let rejectedArguments = updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingReceivedArguments
        #expect(rejectedArguments == nil)

        viewModel.startDate = dateProviderMock.now
        updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingReturnValue =
            meeting
        await viewModel.submit()

        #expect(!viewModel.hasExpiredStartDateError)
        let savedArguments = updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingReceivedArguments
        #expect(savedArguments?.startTime == dateProviderMock.now)
    }

    @Test("editing preserves and submits recurring start times within 24 hours", arguments: [0.0, 3600.0, 86_400.0])
    func editMode_RecentRecurringMeetingPreservesDates(secondsAgo: TimeInterval) async throws {
        let original = makeEditableMeeting(start: dateProviderMock.now.addingTimeInterval(-secondsAgo))
        let viewModel = makeViewModel(mode: .edit(original))
        updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingReturnValue =
            meeting

        #expect(viewModel.startDate == original.start)
        #expect(viewModel.endDate == original.end)

        await viewModel.submit()

        let arguments = updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingReceivedArguments
        #expect(arguments?.startTime == original.start)
        #expect(arguments?.endTime == original.end)
    }

    @Test("recurring meetings just outside the 24-hour window advance to an allowed occurrence")
    func editMode_RecurringMeetingOutsideWindow() {
        let original = makeEditableMeeting(
            start: dateProviderMock.now.addingTimeInterval(-86_401),
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1)
        )
        let viewModel = makeViewModel(mode: .edit(original))

        #expect(viewModel.startDate == original.start.addingTimeInterval(86_400))
        #expect(viewModel.endDate == original.end.addingTimeInterval(86_400))
    }

    @Test("edit mode pre-fills recurring meetings that started in the past with the next occurrence")
    func editMode_PastRecurringMeetingUsesNextOccurrence() throws {
        // Given
        let originalStart = try makeDate(year: 2026, month: 7, day: 5, hour: 9, minute: 0)
        let meeting = makeEditableMeeting(
            start: originalStart,
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1)
        )
        let expectedStart = try makeDate(year: 2026, month: 7, day: 6, hour: 9, minute: 0)
        let expectedEnd = try makeDate(year: 2026, month: 7, day: 6, hour: 10, minute: 0)

        // When
        let viewModel = makeViewModel(mode: .edit(meeting))

        // Then
        #expect(viewModel.startDate == expectedStart)
        #expect(viewModel.endDate == expectedEnd)
        #expect(viewModel.startDateRange.lowerBound == dateProviderMock.now.addingTimeInterval(-86_400))
    }

    @Test("editing either occurrence keeps today's ongoing occurrence as the series start", arguments: [0, 1])
    func submit_EditModePastRecurringMeeting_UsesCurrentOccurrenceTime_TC_11999(occurrenceOffset: Int) async throws {
        // Create an old daily series with an ongoing occurrence today and a future occurrence tomorrow.
        dateProviderMock.now = try makeDate(year: 2026, month: 7, day: 6, hour: 9, minute: 30)
        let originalStart = try makeDate(year: 2026, month: 7, day: 1, hour: 9, minute: 0)
        let original = makeEditableMeeting(
            start: originalStart,
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1)
        )
        let expectedStart = try makeDate(year: 2026, month: 7, day: 6, hour: 9, minute: 0)
        let expectedEnd = expectedStart.addingTimeInterval(TimeInterval.oneHour)
        let occurrences = MeetingOccurrencePaginator().occurrences(
            for: [original],
            startingAt: expectedStart,
            offset: 0,
            limit: 2
        )
        #expect(occurrences.count == 2)
        let selectedOccurrence = try #require(occurrences.dropFirst(occurrenceOffset).first)
        #expect(selectedOccurrence.start == expectedStart.addingTimeInterval(Double(occurrenceOffset) * 86_400))

        // Open the form from either occurrence, which has the same underlying meeting.
        let viewModel = makeViewModel(mode: .edit(selectedOccurrence.meeting))
        #expect(viewModel.startDate == expectedStart)
        #expect(viewModel.endDate == expectedEnd)
        #expect(viewModel.repeatOption == .daily)
        updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingReturnValue =
            original

        // Save the series with today's dates, not tomorrow's dates or the original generator date.
        await viewModel.submit()

        let arguments = updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingReceivedArguments
        #expect(arguments?.meeting == original)
        #expect(arguments?.startTime == expectedStart)
        #expect(arguments?.endTime == expectedEnd)
        #expect(arguments?.recurrence == original.recurrence)
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
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingReturnValue =
            meeting

        // When
        await viewModel.submit()

        // Then
        let arguments = updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingReceivedArguments
        #expect(arguments?.meeting == original)
        #expect(arguments?.title == "Updated Title")
        #expect(arguments?.startTime == viewModel.startDate)
        #expect(arguments?.endTime == viewModel.endDate)
        #expect(arguments?.recurrence == MeetingRecurrence(frequency: .daily, interval: 1))
        #expect(arguments?.participants.isEmpty == true)
        #expect(
            createMeetingUseCaseMock
                .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringParticipantsMeetingMemberInvitedEmailsStringMeetingCreationResultCallsCount ==
                0
        )
        #expect(receivedMeeting == meeting)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.hasError == false)
    }

    @Test("a failed edit keeps all draft values and can retry the same meeting once")
    func submit_EditMode_FailureRetainsDraftAndRetries_TC_12003() async throws {
        // Change all editable values, including member and email invitations.
        let original = makeEditableMeeting()
        var savedMeetings: [Meeting] = []
        let viewModel = makeViewModel(mode: .edit(original), supportsMeetingLinks: true) { savedMeetings.append($0) }
        updateMeetingUseCaseMock.fetchInvitedEmailsForMeetingMeetingStringReturnValue = ["old@example.com"]
        await viewModel.loadInvitedEmails()
        let draftStart = try makeDate(year: 2026, month: 7, day: 7, hour: 10, minute: 0)
        let draftEnd = draftStart.addingTimeInterval(90 * TimeInterval.oneMinute)
        viewModel.meetingTitle = "Updated Title"
        viewModel.startDate = draftStart
        viewModel.endDate = draftEnd
        viewModel.repeatOption = .daily
        viewModel.selectedMembers = []
        viewModel.invitedEmails = ["new@example.com"]
        updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingThrowableError =
            URLError(.notConnectedToInternet)

        // Fail the first save and keep the form open with all draft values.
        await viewModel.submit()

        #expect(viewModel.hasError == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.dismissAfterError == false)
        #expect(savedMeetings.isEmpty)
        #expect(viewModel.meetingTitle == "Updated Title")
        #expect(viewModel.startDate == draftStart)
        #expect(viewModel.endDate == draftEnd)
        #expect(viewModel.repeatOption == .daily)
        #expect(viewModel.selectedMembers.isEmpty)
        #expect(viewModel.invitedEmails == ["new@example.com"])
        let failedArguments = updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingReceivedArguments
        #expect(failedArguments?.meeting.id == original.id)

        // Restore the connection and retry the same draft without creating another meeting.
        updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingThrowableError =
            nil
        updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingReturnValue =
            original
        await viewModel.submit()

        let savedArguments = updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingReceivedArguments
        #expect(savedArguments?.meeting.id == original.id)
        #expect(savedArguments?.title == "Updated Title")
        #expect(savedArguments?.startTime == draftStart)
        #expect(savedArguments?.endTime == draftEnd)
        #expect(savedArguments?.recurrence == MeetingRecurrence(frequency: .daily, interval: 1))
        #expect(savedArguments?.participants.isEmpty == true)
        #expect(savedArguments?.emailsToAdd == ["new@example.com"])
        #expect(savedArguments?.emailsToRemove == ["old@example.com"])
        #expect(updateMeetingUseCaseMock
            .invokeMeetingMeetingTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceParticipantsMeetingMemberEmailsToAddStringEmailsToRemoveStringMeetingCallsCount ==
            2)
        #expect(createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringParticipantsMeetingMemberInvitedEmailsStringMeetingCreationResultCallsCount ==
            0)
        #expect(savedMeetings == [original])
        #expect(viewModel.hasError == false)
        #expect(viewModel.isLoading == false)
    }

    @Test("submit while a submission is in flight is ignored")
    func submit_WhileLoading_IsIgnored_TC_11983() async {
        // Given
        var successCount = 0
        let viewModel = makeViewModel(mode: .instant) { _ in successCount += 1 }
        viewModel.meetingTitle = "Team Standup"
        let meeting = meeting
        createMeetingUseCaseMock
            .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringParticipantsMeetingMemberInvitedEmailsStringMeetingCreationResultClosure =
            { _, _, _, _, _, _, _, _ in
                // Suspend so the second submission starts while the first is in flight.
                try await Task.sleep(for: .milliseconds(10))
                return MeetingCreationResult(meeting: meeting, link: nil)
            }

        // When
        let firstSubmission = Task { await viewModel.submit() }
        let secondSubmission = Task { await viewModel.submit() }
        await firstSubmission.value
        await secondSubmission.value

        // Then
        #expect(
            createMeetingUseCaseMock
                .invokeTitleStringStartTimeDateEndTimeDateRecurrenceMeetingRecurrenceTypeMeetingTypePasswordStringParticipantsMeetingMemberInvitedEmailsStringMeetingCreationResultCallsCount ==
                1
        )
        #expect(viewModel.isLoading == false)
        #expect(successCount == 1)
    }

}
