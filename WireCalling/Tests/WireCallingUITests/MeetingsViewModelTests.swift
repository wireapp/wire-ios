//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

@Suite("MeetingsViewModel Tests")
struct MeetingsViewModelTests {

    private let mockRepository: MockMeetingsRepositoryProtocol
    private let mockDateProvider: CurrentDateProvidingMock
    private let formatter: MeetingsFormatter
    private let pastMeetingsUseCase: MockFetchPastMeetingsUseCaseProtocol
    private let ongoingMeetingsUseCase: MockFetchOngoingMeetingsUseCaseProtocol
    private let upcomingMeetingsUseCase: MockFetchUpcomingMeetingsUseCaseProtocol
    private let viewModel: MeetingsViewModel

    init() throws {
        self.mockRepository = MockMeetingsRepositoryProtocol()
        self.mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-10-27T13:59:59Z")
        self.formatter = MeetingsFormatter()
        self.pastMeetingsUseCase = MockFetchPastMeetingsUseCaseProtocol()
        self.ongoingMeetingsUseCase = MockFetchOngoingMeetingsUseCaseProtocol()
        self.upcomingMeetingsUseCase = MockFetchUpcomingMeetingsUseCaseProtocol()
        self.viewModel = MeetingsViewModel(
            repository: mockRepository,
            currentDateProvider: mockDateProvider,
            formatter: formatter,
            pastMeetingsUseCase: pastMeetingsUseCase,
            ongoingMeetingsUseCase: ongoingMeetingsUseCase,
            upcomingMeetingsUseCase: upcomingMeetingsUseCase
        )
    }

    @Test("initial state has correct defaults")
    func initialState() {
        #expect(viewModel.selectedTab == .next)
        #expect(viewModel.showAll == false)
        #expect(viewModel.showMoreButton == false)
        #expect(viewModel.ongoingMeetings.isEmpty)
        #expect(viewModel.groupedPastMeetings.isEmpty)
        #expect(viewModel.groupedNext.isEmpty)
    }

    @Test("loadInitialData calls all use cases")
    func loadInitialData() {
        // Given
        ongoingMeetingsUseCase.invoke_MockMethod = {
            []
        }
        pastMeetingsUseCase.invoke_MockMethod = {
            []
        }
        mockRepository.hasUpcomingMeetingsAfter_MockMethod = { _ in false }

        let date1 = Date()
        let meeting1 = createMeeting(title: "Past 1", start: date1)
        let groupedMeetings: GroupedMeetings = [
            (day: date1, timeSlots: [(time: date1, meetings: [meeting1])])
        ]
        upcomingMeetingsUseCase.invokeLimitToTwoDaysPageSizeOffset_MockMethod = { _, _, _ in
            PaginatedGroupedMeetings(groups: groupedMeetings, hasMore: false, nextOffset: 0)
        }

        // When
        viewModel.loadInitialData()

        // Then
        #expect(ongoingMeetingsUseCase.invoke_Invocations.count == 1)
        #expect(pastMeetingsUseCase.invoke_Invocations.count == 1)
        #expect(upcomingMeetingsUseCase.invokeLimitToTwoDaysPageSizeOffset_Invocations.count == 1)
    }

    @Test("refreshOngoingMeetings fetches and updates ongoing meetings")
    func refreshOngoingMeetings() {
        // Given
        let meeting1 = createMeeting(title: "Ongoing 1", start: Date())
        let meeting2 = createMeeting(title: "Ongoing 2", start: Date())
        ongoingMeetingsUseCase.invoke_MockValue = [meeting1, meeting2]

        // When
        viewModel.refreshOngoingMeetings()

        // Then
        #expect(viewModel.ongoingMeetings.count == 2)
        #expect(viewModel.ongoingMeetings.contains { $0.title == "Ongoing 1" })
        #expect(viewModel.ongoingMeetings.contains { $0.title == "Ongoing 2" })
    }

    @Test("refreshOngoingMeetings with empty result")
    func refreshOngoingMeetings_EmptyResult() {
        // Given
        ongoingMeetingsUseCase.invoke_MockValue = []

        // When
        viewModel.refreshOngoingMeetings()

        // Then
        #expect(viewModel.ongoingMeetings.isEmpty)
    }

    @Test("refreshPastMeetings fetches and updates past meetings")
    func refreshPastMeetings() {
        // Given
        let date1 = Date()
        let meeting1 = createMeeting(title: "Past 1", start: date1)
        let groupedMeetings: GroupedMeetings = [
            (day: date1, timeSlots: [(time: date1, meetings: [meeting1])])
        ]
        pastMeetingsUseCase.invoke_MockValue = groupedMeetings

        // When
        viewModel.refreshPastMeetings()

        // Then
        #expect(viewModel.groupedPastMeetings.count == 1)
        #expect(viewModel.groupedPastMeetings[0].timeSlots.count == 1)
        #expect(viewModel.groupedPastMeetings[0].timeSlots[0].meetings[0].title == "Past 1")
    }

    @Test("refreshPastMeetings with empty result")
    func refreshPastMeetings_EmptyResult() {
        // Given
        pastMeetingsUseCase.invoke_MockValue = []

        // When
        viewModel.refreshPastMeetings()

        // Then
        #expect(viewModel.groupedPastMeetings.isEmpty)
    }

    @Test("loadUpcomingMeetings loads first page")
    func loadUpcomingMeetingsFirstPage() {
        // Given
        ongoingMeetingsUseCase.invoke_MockMethod = {
            []
        }
        pastMeetingsUseCase.invoke_MockMethod = {
            []
        }
        mockRepository.hasUpcomingMeetingsAfter_MockMethod = { _ in false }
        let date = Date()
        let meeting = createMeeting(title: "Upcoming 1", start: date)
        let groups: GroupedMeetings = [
            (day: date, timeSlots: [(time: date, meetings: [meeting])])
        ]

        upcomingMeetingsUseCase.invokeLimitToTwoDaysPageSizeOffset_MockMethod = { _, _, _ in
            PaginatedGroupedMeetings(groups: groups, hasMore: true, nextOffset: 50)
        }

        // When
        viewModel.loadInitialData()

        // Then
        #expect(viewModel.groupedNext.count == 1)
    }

    // MARK: - Show More Button Tests

    @Test("showMoreButton is false when no more meetings in limited view")
    func showMoreButton_False_WhenNoMore() {
        // Given
        ongoingMeetingsUseCase.invoke_MockMethod = {
            []
        }
        pastMeetingsUseCase.invoke_MockMethod = {
            []
        }
        mockRepository.hasUpcomingMeetingsAfter_MockMethod = { _ in false }
        upcomingMeetingsUseCase.invokeLimitToTwoDaysPageSizeOffset_MockMethod = { _, _, _ in
            PaginatedGroupedMeetings(groups: [], hasMore: false, nextOffset: 0)
        }

        // When
        viewModel.loadInitialData()

        // Then
        #expect(viewModel.showMoreButton == false)
    }

    @Test("showMoreButton is true when more meetings exist beyond tomorrow in limited view")
    func showMoreButton_True_WhenMoreExist() {
        // Given
        ongoingMeetingsUseCase.invoke_MockMethod = {
            []
        }
        pastMeetingsUseCase.invoke_MockMethod = {
            []
        }
        mockRepository.hasUpcomingMeetingsAfter_MockMethod = { _ in true }
        upcomingMeetingsUseCase.invokeLimitToTwoDaysPageSizeOffset_MockMethod = { _, _, _ in
            PaginatedGroupedMeetings(groups: [], hasMore: false, nextOffset: 0)
        }

        // When
        viewModel.loadInitialData()

        // Then
        #expect(viewModel.showMoreButton == true)
    }

    // MARK: - Merge Groups Tests

    @Test("merging groups combines meetings from different days")
    func mergeGroups_DifferentDays() {
        // Given
        ongoingMeetingsUseCase.invoke_MockMethod = {
            []
        }
        pastMeetingsUseCase.invoke_MockMethod = {
            []
        }
        mockRepository.hasUpcomingMeetingsAfter_MockMethod = { _ in false }
        let date1 = Date()
        let date2 = date1.addingTimeInterval(86_400)
        let meeting1 = createMeeting(title: "Meeting 1", start: date1)
        let meeting2 = createMeeting(title: "Meeting 2", start: date2)

        let groups: GroupedMeetings = [
            (day: date1, timeSlots: [(time: date1, meetings: [meeting1])]),
            (day: date2, timeSlots: [(time: date2, meetings: [meeting2])])
        ]
        upcomingMeetingsUseCase.invokeLimitToTwoDaysPageSizeOffset_MockMethod = { _, _, _ in
            PaginatedGroupedMeetings(groups: groups, hasMore: true, nextOffset: 50)
        }

        // When
        viewModel.loadInitialData()
        viewModel.loadMoreUpcomingMeetings()

        // Then
        #expect(viewModel.groupedNext[0].day == date1)
        #expect(viewModel.groupedNext[1].day == date2)
    }

    @Test("merging groups combines meetings from same day different times")
    func mergeGroups_SameDay_DifferentTimes() {
        // Given
        ongoingMeetingsUseCase.invoke_MockMethod = {
            []
        }
        pastMeetingsUseCase.invoke_MockMethod = {
            []
        }
        mockRepository.hasUpcomingMeetingsAfter_MockMethod = { _ in false }
        let date = Date()
        let time1 = date
        let time2 = date.addingTimeInterval(3600)
        let meeting1 = createMeeting(title: "Meeting 1", start: time1)
        let meeting2 = createMeeting(title: "Meeting 2", start: time2)

        let groups: GroupedMeetings = [
            (day: date, timeSlots: [(time: time1, meetings: [meeting1])]),
            (day: date, timeSlots: [(time: time2, meetings: [meeting2])])
        ]
        upcomingMeetingsUseCase.invokeLimitToTwoDaysPageSizeOffset_MockMethod = { _, _, _ in
            PaginatedGroupedMeetings(groups: groups, hasMore: true, nextOffset: 50)
        }

        // When
        viewModel.loadInitialData()
        viewModel.loadMoreUpcomingMeetings()

        // Then
        #expect(viewModel.groupedNext.count == 1)
        #expect(viewModel.groupedNext[0].timeSlots.count == 2)
    }

    @Test("merging groups combines meetings at same time")
    func mergeGroups_SameTime() {
        // Given
        ongoingMeetingsUseCase.invoke_MockMethod = {
            []
        }
        pastMeetingsUseCase.invoke_MockMethod = {
            []
        }
        mockRepository.hasUpcomingMeetingsAfter_MockMethod = { _ in false }
        let date = Date()
        let meeting1 = createMeeting(title: "Meeting 1", start: date)
        let meeting2 = createMeeting(title: "Meeting 2", start: date)

        let firstPageGroups: GroupedMeetings = [
            (day: date, timeSlots: [(time: date, meetings: [meeting1])])
        ]

        let secondPageGroups: GroupedMeetings = [
            (day: date, timeSlots: [(time: date, meetings: [meeting2])])
        ]

        upcomingMeetingsUseCase.invokeLimitToTwoDaysPageSizeOffset_MockMethod = { _, _, offset in
            if offset == 0 {
                PaginatedGroupedMeetings(groups: firstPageGroups, hasMore: true, nextOffset: 50)
            } else {
                PaginatedGroupedMeetings(groups: secondPageGroups, hasMore: false, nextOffset: 100)
            }
        }

        // When
        viewModel.loadInitialData()
        viewModel.loadMoreUpcomingMeetings()

        // Then
        #expect(viewModel.groupedNext.count == 1)
        #expect(viewModel.groupedNext[0].timeSlots.count == 1)
        #expect(viewModel.groupedNext[0].timeSlots[0].meetings.count == 2)
    }

    // MARK: - Helpers

    private func createMeeting(
        id: UUID = UUID(),
        title: String,
        start: Date,
        duration: TimeInterval = 3600
    ) -> Meeting {
        Meeting(
            id: id,
            title: title,
            start: start,
            end: start.addingTimeInterval(duration)
        )
    }

}
