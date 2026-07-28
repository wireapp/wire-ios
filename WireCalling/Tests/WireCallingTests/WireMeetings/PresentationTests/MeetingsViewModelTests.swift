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
import WireFoundationSupport

@testable import WireCallingDomain
@testable import WireCallingDomainSupport
@testable import WireCallingUI

@MainActor
@Suite("MeetingsViewModel Tests")
struct MeetingsViewModelTests {

    private let mockDateProvider: CurrentDateProvidingMock
    private let formatter: MeetingsFormatter
    private let upcomingMeetingsUseCase: FetchUpcomingMeetingsUseCaseProtocolMock
    private let observeMeetingChangesUseCase: ObserveMeetingChangesUseCaseProtocolMock
    private let deleteMeetingUseCase: DeleteMeetingUseCaseProtocolMock
    private let observeAttendedMeetingsUseCase: ObserveAttendedMeetingsUseCaseProtocolMock
    private let viewModel: MeetingsViewModel

    init() throws {
        self.mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-10-27T13:59:59Z")
        self.formatter = MeetingsFormatter()
        self.upcomingMeetingsUseCase = FetchUpcomingMeetingsUseCaseProtocolMock()
        self.observeMeetingChangesUseCase = ObserveMeetingChangesUseCaseProtocolMock()
        self.deleteMeetingUseCase = DeleteMeetingUseCaseProtocolMock()
        self.observeAttendedMeetingsUseCase = ObserveAttendedMeetingsUseCaseProtocolMock()
        self.viewModel = MeetingsViewModel(
            currentDateProvider: mockDateProvider,
            formatter: formatter,
            upcomingMeetingsUseCase: upcomingMeetingsUseCase,
            observeMeetingChangesUseCase: observeMeetingChangesUseCase,
            deleteMeetingUseCase: deleteMeetingUseCase,
            observeAttendedMeetingsUseCase: observeAttendedMeetingsUseCase
        )
    }

    // MARK: - Initial State

    @Test("initial state is empty")
    func initialState() {
        #expect(viewModel.loadedMeetings.isEmpty)
        #expect(viewModel.hasMore == false)
        #expect(viewModel.groupedUpcomingMeetings.isEmpty)
        #expect(viewModel.attendingConversationIDs.isEmpty)
    }

    // MARK: - loadInitialData

    @Test("loadInitialData loads the first page using the initial page size and a zero offset")
    func loadInitialData_loadsFirstPage() async {
        // Given
        let meeting = Meeting.fixture(title: "Upcoming 1", start: mockDateProvider.now.addingTimeInterval(3600))
        upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsClosure = { _, _ in
            PaginatedMeetings(meetings: [meeting], hasMore: true, nextOffset: 10)
        }

        // When
        await viewModel.loadInitialData()

        // Then
        #expect(viewModel.loadedMeetings.count == 1)
        #expect(viewModel.loadedMeetings.first?.title == "Upcoming 1")
        #expect(viewModel.hasMore == true)
        #expect(upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsCallsCount == 1)
        #expect(upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsReceivedInvocations.first?
            .pageSize == 10)
        #expect(upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsReceivedInvocations.first?
            .offset == 0)
    }

    @Test("loadInitialData replaces previously loaded meetings and resets the offset")
    func loadInitialData_resetsState() async {
        // Given
        let first = Meeting.fixture(title: "First load", start: mockDateProvider.now.addingTimeInterval(3600))
        let second = Meeting.fixture(title: "Second load", start: mockDateProvider.now.addingTimeInterval(7200))
        upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsClosure = { _, _ in
            PaginatedMeetings(meetings: [first], hasMore: true, nextOffset: 10)
        }
        await viewModel.loadInitialData()

        // When — a second initial load returns a different page
        upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsClosure = { _, _ in
            PaginatedMeetings(meetings: [second], hasMore: false, nextOffset: 10)
        }
        await viewModel.loadInitialData()

        // Then — meetings are replaced (not appended) and the offset is back to 0
        #expect(viewModel.loadedMeetings.count == 1)
        #expect(viewModel.loadedMeetings.first?.title == "Second load")
        #expect(viewModel.hasMore == false)
        #expect(upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsReceivedInvocations.last?
            .offset == 0)
    }

    // MARK: - loadMoreIfNeeded

    @Test("loadMoreIfNeeded appends the next page using the page size and the returned offset")
    func loadMoreIfNeeded_appendsNextPage() async {
        // Given — page 1 at offset 0, page 2 at offset 10
        let page1 = Meeting.fixture(title: "Page 1", start: mockDateProvider.now.addingTimeInterval(3600))
        let page2 = Meeting.fixture(title: "Page 2", start: mockDateProvider.now.addingTimeInterval(2 * 86_400))
        upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsClosure = { _, offset in
            if offset == 0 {
                PaginatedMeetings(meetings: [page1], hasMore: true, nextOffset: 10)
            } else {
                PaginatedMeetings(meetings: [page2], hasMore: false, nextOffset: 15)
            }
        }

        // When
        await viewModel.loadInitialData()
        await viewModel.loadMoreIfNeeded()

        // Then
        #expect(viewModel.loadedMeetings.count == 2)
        #expect(viewModel.loadedMeetings.contains { $0.title == "Page 1" })
        #expect(viewModel.loadedMeetings.contains { $0.title == "Page 2" })
        #expect(viewModel.hasMore == false)
        #expect(upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsCallsCount == 2)
        #expect(upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsReceivedInvocations.last?
            .pageSize == 5)
        #expect(upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsReceivedInvocations.last?
            .offset == 10)
    }

    @Test("loadMoreIfNeeded does nothing when there are no more meetings")
    func loadMoreIfNeeded_doesNothingWhenNoMore() async {
        // Given
        upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsClosure = { _, _ in
            PaginatedMeetings(meetings: [], hasMore: false, nextOffset: 0)
        }
        await viewModel.loadInitialData()
        #expect(viewModel.hasMore == false)

        // When
        await viewModel.loadMoreIfNeeded()

        // Then — no extra fetch happened
        #expect(upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsCallsCount == 1)
    }

    // MARK: - observeMeetingChanges

    @Test("a meeting change event reloads the loaded meetings from offset zero")
    func meetingChangeEvent_reloadsLoadedMeetings() async {
        // Given — an initial load with one meeting
        let initial = Meeting.fixture(title: "Initial", start: mockDateProvider.now.addingTimeInterval(3600))
        let updated = Meeting.fixture(title: "Updated", start: mockDateProvider.now.addingTimeInterval(3600))
        upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsClosure = { _, _ in
            PaginatedMeetings(meetings: [initial], hasMore: false, nextOffset: 1)
        }
        await viewModel.loadInitialData()

        let (changes, changeContinuation) = AsyncStream<Void>.makeStream()
        observeMeetingChangesUseCase.invokeAsyncStreamVoidReturnValue = changes

        // When — a change event arrives while the next fetch returns different meetings
        upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsClosure = { _, _ in
            PaginatedMeetings(meetings: [updated], hasMore: false, nextOffset: 1)
        }
        changeContinuation.yield(())
        changeContinuation.finish()
        await viewModel.observeMeetingChanges()

        // Then — the loaded meetings were replaced by a fetch from offset 0
        #expect(viewModel.loadedMeetings.map(\.title) == ["Updated"])
        #expect(upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsReceivedInvocations.last?
            .offset == 0)
    }

    @Test("a meeting change event re-fetches the entire loaded range in one page")
    func meetingChangeEvent_refetchesLoadedRange() async {
        // Given — 12 loaded meetings (initial page of 10 plus a page of 2)
        let meetings = (0 ..< 12).map { index in
            Meeting.fixture(
                title: "Meeting \(index)",
                start: mockDateProvider.now.addingTimeInterval(Double(index + 1) * 3600)
            )
        }
        upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsClosure = { _, offset in
            if offset == 0 {
                PaginatedMeetings(meetings: Array(meetings.prefix(10)), hasMore: true, nextOffset: 10)
            } else {
                PaginatedMeetings(meetings: Array(meetings.suffix(2)), hasMore: false, nextOffset: 12)
            }
        }
        await viewModel.loadInitialData()
        await viewModel.loadMoreIfNeeded()
        #expect(viewModel.loadedMeetings.count == 12)

        let (changes, changeContinuation) = AsyncStream<Void>.makeStream()
        observeMeetingChangesUseCase.invokeAsyncStreamVoidReturnValue = changes

        // When
        upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsClosure = { _, _ in
            PaginatedMeetings(meetings: meetings, hasMore: false, nextOffset: 12)
        }
        changeContinuation.yield(())
        changeContinuation.finish()
        await viewModel.observeMeetingChanges()

        // Then — a single fetch covering all 12 loaded meetings
        let lastInvocation = upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsReceivedInvocations
            .last
        #expect(lastInvocation?.pageSize == 12)
        #expect(lastInvocation?.offset == 0)
        #expect(viewModel.loadedMeetings.count == 12)
    }

    // MARK: - observeAttendedMeetings

    @Test("the initially emitted set populates attendingConversationIDs and isAttending")
    func observeAttendedMeetings_appliesInitialValue() async {
        // Given
        let attended = Meeting.fixture(title: "Attended", start: mockDateProvider.now.addingTimeInterval(3600))
        let other = Meeting.fixture(title: "Other", start: mockDateProvider.now.addingTimeInterval(7200))

        let (stream, continuation) = AsyncStream<Set<QualifiedID>>.makeStream()
        observeAttendedMeetingsUseCase.invokeAsyncStreamSetWireFoundationQualifiedIDReturnValue = stream

        // When
        continuation.yield([attended.conversationID])
        continuation.finish()
        await viewModel.observeAttendedMeetings()

        // Then
        #expect(viewModel.attendingConversationIDs == [attended.conversationID])
        #expect(viewModel.isAttending(attended) == true)
        #expect(viewModel.isAttending(other) == false)
    }

    @Test("a subsequent emission replaces the attending set")
    func observeAttendedMeetings_appliesSubsequentUpdates() async {
        // Given
        let meeting = Meeting.fixture(title: "Meeting", start: mockDateProvider.now.addingTimeInterval(3600))

        let (stream, continuation) = AsyncStream<Set<QualifiedID>>.makeStream()
        observeAttendedMeetingsUseCase.invokeAsyncStreamSetWireFoundationQualifiedIDReturnValue = stream

        // When — the self user joins the call and later leaves it
        continuation.yield([meeting.conversationID])
        continuation.yield([])
        continuation.finish()
        await viewModel.observeAttendedMeetings()

        // Then — the latest emitted set wins
        #expect(viewModel.attendingConversationIDs.isEmpty)
        #expect(viewModel.isAttending(meeting) == false)
    }

    @Test("observeAttendedMeetings returns immediately when no use case is provided")
    func observeAttendedMeetings_withoutUseCase() async {
        // Given — a view model created without the optional use case
        let viewModel = MeetingsViewModel(
            currentDateProvider: mockDateProvider,
            formatter: formatter,
            upcomingMeetingsUseCase: upcomingMeetingsUseCase,
            observeMeetingChangesUseCase: observeMeetingChangesUseCase,
            deleteMeetingUseCase: deleteMeetingUseCase
        )

        // When
        await viewModel.observeAttendedMeetings()

        // Then
        #expect(viewModel.attendingConversationIDs.isEmpty)
        #expect(observeAttendedMeetingsUseCase.invokeAsyncStreamSetWireFoundationQualifiedIDCallsCount == 0)
    }

    // MARK: - Grouping

    @Test("groupedUpcomingMeetings groups by day ascending and sorts within a day by start then title")
    func groupedUpcomingMeetings_groupsAndSorts() async {
        // Given — same-day meetings (one tie on start time, broken by title) plus a later day,
        // delivered out of order to prove the grouper sorts both days and time slots.
        let earlyZebra = Meeting.fixture(title: "Zebra sync", start: mockDateProvider.now.addingTimeInterval(3600))
        let earlyApple = Meeting.fixture(title: "Apple sync", start: mockDateProvider.now.addingTimeInterval(3600))
        let later = Meeting.fixture(title: "Late", start: mockDateProvider.now.addingTimeInterval(7200))
        let otherDay = Meeting.fixture(title: "Next day", start: mockDateProvider.now.addingTimeInterval(2 * 86_400))

        upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsClosure = { _, _ in
            PaginatedMeetings(meetings: [later, otherDay, earlyZebra, earlyApple], hasMore: false, nextOffset: 10)
        }

        // When
        await viewModel.loadInitialData()

        // Then
        let groups = viewModel.groupedUpcomingMeetings
        #expect(groups.count == 2)

        // Days are sorted ascending
        #expect(groups[0].day < groups[1].day)

        // First day: sorted by start, ties broken by title
        #expect(groups[0].meetings.map(\.title) == ["Apple sync", "Zebra sync", "Late"])

        // Second day
        #expect(groups[1].meetings.map(\.title) == ["Next day"])
    }

    // MARK: - deleteMeeting

    @Test("deleteMeeting calls the use case with the correct ID and removes the meeting")
    func deleteMeeting_callsUseCaseAndRemovesMeeting() async throws {
        // Given
        let meeting = Meeting.fixture(title: "To delete", start: mockDateProvider.now.addingTimeInterval(3600))
        upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsClosure = { _, _ in
            PaginatedMeetings(meetings: [meeting], hasMore: false, nextOffset: 1)
        }
        await viewModel.loadInitialData()
        #expect(viewModel.loadedMeetings.count == 1)

        // When
        await viewModel.deleteMeeting(meeting)

        // Then
        #expect(deleteMeetingUseCase.invokeMeetingIDQualifiedIDVoidCallsCount == 1)
        #expect(deleteMeetingUseCase.invokeMeetingIDQualifiedIDVoidReceivedMeetingID == meeting.id)
        #expect(viewModel.loadedMeetings.isEmpty)
    }

    @Test("deleteMeeting flags an error and keeps the meeting when the use case fails")
    func deleteMeeting_flagsErrorOnFailure() async {
        // Given
        let meeting = Meeting.fixture(title: "To delete", start: mockDateProvider.now.addingTimeInterval(3600))
        upcomingMeetingsUseCase.invokePageSizeIntOffsetIntPaginatedMeetingsClosure = { _, _ in
            PaginatedMeetings(meetings: [meeting], hasMore: false, nextOffset: 1)
        }
        await viewModel.loadInitialData()

        struct DeleteError: Error {}
        deleteMeetingUseCase.invokeMeetingIDQualifiedIDVoidThrowableError = DeleteError()

        // When
        await viewModel.deleteMeeting(meeting)

        // Then — the error is surfaced and the meeting is not removed
        #expect(viewModel.hasDeleteError == true)
        #expect(viewModel.loadedMeetings.count == 1)
    }

    // MARK: - Delete Confirmation

    @Test("setting meetingToDelete presents the confirmation without deleting anything")
    func meetingToDelete_presentsConfirmation() {
        // Given
        let meeting = Meeting.fixture(title: "To delete", start: mockDateProvider.now.addingTimeInterval(3600))

        // When
        viewModel.meetingToDelete = meeting

        // Then
        #expect(viewModel.isDeleteConfirmationPresented == true)
        #expect(deleteMeetingUseCase.invokeMeetingIDQualifiedIDVoidCallsCount == 0)
    }

    @Test("confirmDelete deletes the pending meeting and dismisses the confirmation")
    func confirmDelete_deletesPendingMeeting() async {
        // Given
        let meeting = Meeting.fixture(title: "To delete", start: mockDateProvider.now.addingTimeInterval(3600))
        viewModel.meetingToDelete = meeting

        // When — confirmDelete deletes in a fire-and-forget task, so wait for the use case call
        await withCheckedContinuation { continuation in
            deleteMeetingUseCase.invokeMeetingIDQualifiedIDVoidClosure = { _ in continuation.resume() }
            viewModel.confirmDelete()
        }

        // Then
        #expect(deleteMeetingUseCase.invokeMeetingIDQualifiedIDVoidCallsCount == 1)
        #expect(deleteMeetingUseCase.invokeMeetingIDQualifiedIDVoidReceivedMeetingID == meeting.id)
        #expect(viewModel.meetingToDelete == nil)
        #expect(viewModel.isDeleteConfirmationPresented == false)
    }

    @Test("confirmDelete does nothing when no meeting is pending")
    func confirmDelete_withoutPendingMeeting() {
        // When
        viewModel.confirmDelete()

        // Then
        #expect(deleteMeetingUseCase.invokeMeetingIDQualifiedIDVoidCallsCount == 0)
    }

    @Test("dismissing the confirmation clears the pending meeting without deleting it")
    func dismissConfirmation_cancelsDelete() {
        // Given
        let meeting = Meeting.fixture(title: "To delete", start: mockDateProvider.now.addingTimeInterval(3600))
        viewModel.meetingToDelete = meeting

        // When — the cancel button dismisses the alert, which resets the binding
        viewModel.isDeleteConfirmationPresented = false

        // Then
        #expect(viewModel.meetingToDelete == nil)
        #expect(deleteMeetingUseCase.invokeMeetingIDQualifiedIDVoidCallsCount == 0)
    }

    // MARK: - Formatting

    @Test("formatTimeRange delegates to the formatter")
    func formatTimeRange() {
        let meeting = Meeting.fixture(title: "Meeting", start: mockDateProvider.now)
        #expect(viewModel.formatTimeRange(for: meeting) == formatter.timeRange(from: meeting.start, to: meeting.end))
    }

    @Test("formatDay delegates to the formatter")
    func formatDay() {
        let day = mockDateProvider.now
        #expect(viewModel.formatDay(day) == formatter.dayHeader(for: day, now: mockDateProvider.now))
    }

}

private extension Meeting {

    static func fixture(
        id: QualifiedID = QualifiedID(id: UUID(), domain: ""),
        title: String,
        start: Date,
        duration: TimeInterval = 3600
    ) -> Meeting {
        Meeting(
            id: id,
            title: title,
            start: start,
            end: start.addingTimeInterval(duration),
            recurrence: nil,
            conversationID: QualifiedID(id: UUID(), domain: ""),
            creatorID: QualifiedID(id: UUID(), domain: "")
        )
    }

}
