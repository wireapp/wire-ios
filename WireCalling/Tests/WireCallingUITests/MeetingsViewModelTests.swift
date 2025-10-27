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

// import Foundation
// import Testing
// import WireCallingDomain
// import WireCallingUI
// import WireFoundation
//
// @Suite("MeetingsViewModel Tests")
// struct MeetingsViewModelTests {
//
//    // MARK: - Mocks
//
//    final class MockMeetingsRepository: MeetingsRepositoryProtocol {
//        var ongoingMeetings: [Meeting] = []
//        var pastMeetings: [Meeting] = []
//        var upcomingMeetings: [Meeting] = []
//        var hasMoreUpcoming: Bool = false
//
//        func fetchOngoingMeetings(at date: Date) -> [Meeting] {
//            ongoingMeetings
//        }
//
//        func fetchPastMeetings(until date: Date) -> [Meeting] {
//            pastMeetings
//        }
//
//        func fetchUpcomingMeetings(after date: Date, limit: Int, offset: Int) -> [Meeting] {
//            upcomingMeetings
//        }
//
//        func hasUpcomingMeetings(after date: Date) -> Bool {
//            hasMoreUpcoming
//        }
//    }
//
//    final class MockDateProvider: CurrentDateProviding {
//        var now: Date
//
//        init(now: Date = Date()) {
//            self.now = now
//        }
//    }
//
//    final class MockFetchOngoingMeetingsUseCase: FetchOngoingMeetingsUseCaseProtocol {
//        var meetingsToReturn: [Meeting] = []
//        var invokeCallCount = 0
//
//        func invoke() -> [Meeting] {
//            invokeCallCount += 1
//            return meetingsToReturn
//        }
//    }
//
//    final class MockFetchPastMeetingsUseCase: FetchPastMeetingsUseCaseProtocol {
//        var groupsToReturn: GroupedMeetings = []
//        var invokeCallCount = 0
//
//        func invoke() -> GroupedMeetings {
//            invokeCallCount += 1
//            return groupsToReturn
//        }
//    }
//
//    final class MockFetchUpcomingMeetingsUseCase: FetchUpcomingMeetingsUseCaseProtocol {
//        var resultsToReturn: [PaginatedGroupedMeetings] = []
//        var invokeCallCount = 0
//        var capturedLimitToTwoDays: [Bool] = []
//        var capturedPageSize: [Int] = []
//        var capturedOffset: [Int] = []
//
//        func invoke(limitToTwoDays: Bool, pageSize: Int, offset: Int) -> PaginatedGroupedMeetings {
//            capturedLimitToTwoDays.append(limitToTwoDays)
//            capturedPageSize.append(pageSize)
//            capturedOffset.append(offset)
//
//            let result = resultsToReturn.isEmpty
//                ? PaginatedGroupedMeetings(groups: [], hasMore: false, nextOffset: 0)
//                : resultsToReturn[min(invokeCallCount, resultsToReturn.count - 1)]
//
//            invokeCallCount += 1
//            return result
//        }
//    }
//
//    final class MockMeetingsFormatter: MeetingsFormatter {
//        var dayHeaderToReturn: String = "Mocked Day"
//        var timeHeaderToReturn: String = "Mocked Time"
//
//        override func dayHeader(for date: Date, now: Date) -> String {
//            dayHeaderToReturn
//        }
//
//        override func timeHeader(for date: Date) -> String {
//            timeHeaderToReturn
//        }
//    }
//
//    // MARK: - Helpers
//
//    func createMeeting(
//        id: UUID = UUID(),
//        title: String,
//        start: Date,
//        duration: TimeInterval = 3600
//    ) -> Meeting {
//        Meeting(
//            id: id,
//            title: title,
//            start: start,
//            end: start.addingTimeInterval(duration)
//        )
//    }
//
//    func createViewModel(
//        repository: MockMeetingsRepository = MockMeetingsRepository(),
//        dateProvider: MockDateProvider = MockDateProvider(),
//        formatter: MeetingsFormatter = MeetingsFormatter(),
//        pastUseCase: MockFetchPastMeetingsUseCase = MockFetchPastMeetingsUseCase(),
//        ongoingUseCase: MockFetchOngoingMeetingsUseCase = MockFetchOngoingMeetingsUseCase(),
//        upcomingUseCase: MockFetchUpcomingMeetingsUseCase = MockFetchUpcomingMeetingsUseCase()
//    ) -> (
//        viewModel: MeetingsViewModel,
//        repository: MockMeetingsRepository,
//        dateProvider: MockDateProvider,
//        formatter: MeetingsFormatter,
//        pastUseCase: MockFetchPastMeetingsUseCase,
//        ongoingUseCase: MockFetchOngoingMeetingsUseCase,
//        upcomingUseCase: MockFetchUpcomingMeetingsUseCase
//    ) {
//        let viewModel = MeetingsViewModel(
//            repository: repository,
//            currentDateProvider: dateProvider,
//            formatter: formatter,
//            pastMeetingsUseCase: pastUseCase,
//            ongoingMeetingsUseCase: ongoingUseCase,
//            upcomingMeetingsUseCase: upcomingUseCase
//        )
//        return (viewModel, repository, dateProvider, formatter, pastUseCase, ongoingUseCase, upcomingUseCase)
//    }
//
//    // MARK: - Initial State Tests
//
//    @Test("initial state has correct defaults")
//    func testInitialState() {
//        let (viewModel, _, _, _, _, _, _) = createViewModel()
//
//        #expect(viewModel.selectedTab == .next)
//        #expect(viewModel.showAll == false)
//        #expect(viewModel.showMoreButton == false)
//        #expect(viewModel.ongoingMeetings.isEmpty)
//        #expect(viewModel.groupedPastMeetings.isEmpty)
//        #expect(viewModel.groupedNext.isEmpty)
//    }
//
//    // MARK: - Load Initial Data Tests
//
//    @Test("loadInitialData calls all use cases")
//    func testLoadInitialData() {
//        let (viewModel, _, _, _, pastUseCase, ongoingUseCase, upcomingUseCase) = createViewModel()
//
//        viewModel.loadInitialData()
//
//        #expect(ongoingUseCase.invokeCallCount == 1)
//        #expect(pastUseCase.invokeCallCount == 1)
//        #expect(upcomingUseCase.invokeCallCount == 1)
//    }
//
//    @Test("loadInitialData with limited view passes correct parameters")
//    func testLoadInitialDataLimitedView() {
//        let (viewModel, _, _, _, _, _, upcomingUseCase) = createViewModel()
//
//        viewModel.loadInitialData()
//
//        #expect(upcomingUseCase.capturedLimitToTwoDays.first == true)
//        #expect(upcomingUseCase.capturedPageSize.first == 50)
//        #expect(upcomingUseCase.capturedOffset.first == 0)
//    }
//
//    // MARK: - Refresh Ongoing Meetings Tests
//
//    @Test("refreshOngoingMeetings fetches and updates ongoing meetings")
//    func testRefreshOngoingMeetings() {
//        let (viewModel, _, _, _, _, ongoingUseCase, _) = createViewModel()
//
//        let meeting1 = createMeeting(title: "Ongoing 1", start: Date())
//        let meeting2 = createMeeting(title: "Ongoing 2", start: Date())
//        ongoingUseCase.meetingsToReturn = [meeting1, meeting2]
//
//        viewModel.refreshOngoingMeetings()
//
//        #expect(viewModel.ongoingMeetings.count == 2)
//        #expect(viewModel.ongoingMeetings.contains { $0.title == "Ongoing 1" })
//        #expect(viewModel.ongoingMeetings.contains { $0.title == "Ongoing 2" })
//    }
//
//    @Test("refreshOngoingMeetings with empty result")
//    func testRefreshOngoingMeetingsEmpty() {
//        let (viewModel, _, _, _, _, ongoingUseCase, _) = createViewModel()
//        ongoingUseCase.meetingsToReturn = []
//
//        viewModel.refreshOngoingMeetings()
//
//        #expect(viewModel.ongoingMeetings.isEmpty)
//    }
//
//    @Test("refreshOngoingMeetings updates existing meetings")
//    func testRefreshOngoingMeetingsUpdate() {
//        let (viewModel, _, _, _, _, ongoingUseCase, _) = createViewModel()
//
//        let meeting1 = createMeeting(title: "Meeting 1", start: Date())
//        ongoingUseCase.meetingsToReturn = [meeting1]
//        viewModel.refreshOngoingMeetings()
//
//        #expect(viewModel.ongoingMeetings.count == 1)
//
//        let meeting2 = createMeeting(title: "Meeting 2", start: Date())
//        ongoingUseCase.meetingsToReturn = [meeting1, meeting2]
//        viewModel.refreshOngoingMeetings()
//
//        #expect(viewModel.ongoingMeetings.count == 2)
//    }
//
//    // MARK: - Refresh Past Meetings Tests
//
//    @Test("refreshPastMeetings fetches and updates past meetings")
//    func testRefreshPastMeetings() {
//        let (viewModel, _, _, _, pastUseCase, _, _) = createViewModel()
//
//        let date1 = Date()
//        let date2 = Date().addingTimeInterval(3600)
//        let meeting1 = createMeeting(title: "Past 1", start: date1)
//
//        let groupedMeetings: GroupedMeetings = [
//            (day: date1, timeSlots: [(time: date1, meetings: [meeting1])])
//        ]
//        pastUseCase.groupsToReturn = groupedMeetings
//
//        viewModel.refreshPastMeetings()
//
//        #expect(viewModel.groupedPastMeetings.count == 1)
//        #expect(viewModel.groupedPastMeetings[0].timeSlots.count == 1)
//        #expect(viewModel.groupedPastMeetings[0].timeSlots[0].meetings[0].title == "Past 1")
//    }
//
//    @Test("refreshPastMeetings with empty result")
//    func testRefreshPastMeetingsEmpty() {
//        let (viewModel, _, _, _, pastUseCase, _, _) = createViewModel()
//        pastUseCase.groupsToReturn = []
//
//        viewModel.refreshPastMeetings()
//
//        #expect(viewModel.groupedPastMeetings.isEmpty)
//    }
//
//    // MARK: - Load Upcoming Meetings Tests
//
//    @Test("loadUpcomingMeetings loads first page")
//    func testLoadUpcomingMeetingsFirstPage() {
//        let (viewModel, _, _, _, _, _, upcomingUseCase) = createViewModel()
//
//        let date = Date()
//        let meeting = createMeeting(title: "Upcoming 1", start: date)
//        let groups: GroupedMeetings = [
//            (day: date, timeSlots: [(time: date, meetings: [meeting])])
//        ]
//
//        upcomingUseCase.resultsToReturn = [
//            PaginatedGroupedMeetings(groups: groups, hasMore: true, nextOffset: 50)
//        ]
//
//        viewModel.loadInitialData()
//
//        #expect(viewModel.groupedNext.count == 1)
//        #expect(upcomingUseCase.capturedOffset[0] == 0)
//    }
//
//    @Test("loadMoreUpcomingMeetings loads next page")
//    func testLoadMoreUpcomingMeetings() {
//        let (viewModel, _, _, _, _, _, upcomingUseCase) = createViewModel()
//
//        let date1 = Date()
//        let meeting1 = createMeeting(title: "Meeting 1", start: date1)
//        let groups1: GroupedMeetings = [
//            (day: date1, timeSlots: [(time: date1, meetings: [meeting1])])
//        ]
//
//        let date2 = Date().addingTimeInterval(7200)
//        let meeting2 = createMeeting(title: "Meeting 2", start: date2)
//        let groups2: GroupedMeetings = [
//            (day: date2, timeSlots: [(time: date2, meetings: [meeting2])])
//        ]
//
//        upcomingUseCase.resultsToReturn = [
//            PaginatedGroupedMeetings(groups: groups1, hasMore: true, nextOffset: 50),
//            PaginatedGroupedMeetings(groups: groups2, hasMore: false, nextOffset: 100)
//        ]
//
//        viewModel.loadInitialData()
//        #expect(viewModel.groupedNext.count == 1)
//
//        viewModel.loadMoreUpcomingMeetings()
//        #expect(viewModel.groupedNext.count == 2)
//        #expect(upcomingUseCase.capturedOffset[1] == 50)
//    }
//
//    @Test("showAll toggle resets pagination")
//    func testShowAllToggleResetsPagination() {
//        let (viewModel, _, _, _, _, _, upcomingUseCase) = createViewModel()
//
//        let date = Date()
//        let meeting = createMeeting(title: "Meeting", start: date)
//        let groups: GroupedMeetings = [
//            (day: date, timeSlots: [(time: date, meetings: [meeting])])
//        ]
//
//        upcomingUseCase.resultsToReturn = [
//            PaginatedGroupedMeetings(groups: groups, hasMore: true, nextOffset: 50),
//            PaginatedGroupedMeetings(groups: groups, hasMore: false, nextOffset: 0)
//        ]
//
//        viewModel.loadInitialData()
//        #expect(upcomingUseCase.invokeCallCount == 1)
//
//        viewModel.showAll = true
//        #expect(upcomingUseCase.invokeCallCount == 2)
//        #expect(upcomingUseCase.capturedOffset[1] == 0)
//        #expect(upcomingUseCase.capturedLimitToTwoDays[1] == false)
//    }
//
//    @Test("showAll toggle from true to false resets pagination")
//    func testShowAllToggleBackResetsPagination() {
//        let (viewModel, _, _, _, _, _, upcomingUseCase) = createViewModel()
//
//        let date = Date()
//        let meeting = createMeeting(title: "Meeting", start: date)
//        let groups: GroupedMeetings = [
//            (day: date, timeSlots: [(time: date, meetings: [meeting])])
//        ]
//
//        upcomingUseCase.resultsToReturn = [
//            PaginatedGroupedMeetings(groups: groups, hasMore: false, nextOffset: 0)
//        ]
//
//        viewModel.showAll = true
//        let firstCallCount = upcomingUseCase.invokeCallCount
//
//        viewModel.showAll = false
//        #expect(upcomingUseCase.invokeCallCount == firstCallCount + 1)
//        #expect(upcomingUseCase.capturedLimitToTwoDays.last == true)
//    }
//
//    @Test("showAll set to same value does not trigger reload")
//    func testShowAllSameValueDoesNotReload() {
//        let (viewModel, _, _, _, _, _, upcomingUseCase) = createViewModel()
//
//        viewModel.showAll = false
//        let callCount = upcomingUseCase.invokeCallCount
//
//        viewModel.showAll = false
//        #expect(upcomingUseCase.invokeCallCount == callCount)
//    }
//
//    // MARK: - Show More Button Tests
//
//    @Test("showMoreButton is false when no more meetings in limited view")
//    func testShowMoreButtonFalseWhenNoMore() {
//        let (viewModel, repository, _, _, _, _, upcomingUseCase) = createViewModel()
//
//        repository.hasMoreUpcoming = false
//        upcomingUseCase.resultsToReturn = [
//            PaginatedGroupedMeetings(groups: [], hasMore: false, nextOffset: 0)
//        ]
//
//        viewModel.loadInitialData()
//
//        #expect(viewModel.showMoreButton == false)
//    }
//
//    @Test("showMoreButton is true when more meetings exist beyond tomorrow in limited view")
//    func testShowMoreButtonTrueWhenMoreExist() {
//        let (viewModel, repository, _, _, _, _, upcomingUseCase) = createViewModel()
//
//        repository.hasMoreUpcoming = true
//        upcomingUseCase.resultsToReturn = [
//            PaginatedGroupedMeetings(groups: [], hasMore: false, nextOffset: 0)
//        ]
//
//        viewModel.loadInitialData()
//
//        #expect(viewModel.showMoreButton == true)
//    }
//
//    @Test("showMoreButton reflects hasMore in unlimited view")
//    func testShowMoreButtonUnlimitedView() {
//        let (viewModel, _, _, _, _, _, upcomingUseCase) = createViewModel()
//
//        upcomingUseCase.resultsToReturn = [
//            PaginatedGroupedMeetings(groups: [], hasMore: false, nextOffset: 0),
//            PaginatedGroupedMeetings(groups: [], hasMore: true, nextOffset: 50)
//        ]
//
//        viewModel.showAll = true
//        #expect(viewModel.showMoreButton == true)
//    }
//
//    // MARK: - Formatting Tests
//
//    @Test("formatDay delegates to formatter")
//    func testFormatDay() {
//        let formatter = MockMeetingsFormatter()
//        formatter.dayHeaderToReturn = "Custom Day"
//        let (viewModel, _, _, _, _, _, _) = createViewModel(formatter: formatter)
//
//        let date = Date()
//        let result = viewModel.formatDay(date)
//
//        #expect(result == "Custom Day")
//    }
//
//    @Test("formatTime delegates to formatter")
//    func testFormatTime() {
//        let formatter = MockMeetingsFormatter()
//        formatter.timeHeaderToReturn = "Custom Time"
//        let (viewModel, _, _, _, _, _, _) = createViewModel(formatter: formatter)
//
//        let date = Date()
//        let result = viewModel.formatTime(date)
//
//        #expect(result == "Custom Time")
//    }
//
//    // MARK: - Merge Groups Tests
//
//    @Test("merging groups combines meetings from different days")
//    func testMergeGroupsDifferentDays() {
//        let (viewModel, _, _, _, _, _, upcomingUseCase) = createViewModel()
//
//        let date1 = Date()
//        let date2 = date1.addingTimeInterval(86400)
//        let meeting1 = createMeeting(title: "Meeting 1", start: date1)
//        let meeting2 = createMeeting(title: "Meeting 2", start: date2)
//
//        let groups1: GroupedMeetings = [
//            (day: date1, timeSlots: [(time: date1, meetings: [meeting1])])
//        ]
//        let groups2: GroupedMeetings = [
//            (day: date2, timeSlots: [(time: date2, meetings: [meeting2])])
//        ]
//
//        upcomingUseCase.resultsToReturn = [
//            PaginatedGroupedMeetings(groups: groups1, hasMore: true, nextOffset: 50),
//            PaginatedGroupedMeetings(groups: groups2, hasMore: false, nextOffset: 100)
//        ]
//
//        viewModel.loadInitialData()
//        viewModel.loadMoreUpcomingMeetings()
//
//        #expect(viewModel.groupedNext.count == 2)
//        #expect(viewModel.groupedNext[0].day == date1)
//        #expect(viewModel.groupedNext[1].day == date2)
//    }
//
//    @Test("merging groups combines meetings from same day different times")
//    func testMergeGroupsSameDayDifferentTimes() {
//        let (viewModel, _, _, _, _, _, upcomingUseCase) = createViewModel()
//
//        let date = Date()
//        let time1 = date
//        let time2 = date.addingTimeInterval(3600)
//        let meeting1 = createMeeting(title: "Meeting 1", start: time1)
//        let meeting2 = createMeeting(title: "Meeting 2", start: time2)
//
//        let groups1: GroupedMeetings = [
//            (day: date, timeSlots: [(time: time1, meetings: [meeting1])])
//        ]
//        let groups2: GroupedMeetings = [
//            (day: date, timeSlots: [(time: time2, meetings: [meeting2])])
//        ]
//
//        upcomingUseCase.resultsToReturn = [
//            PaginatedGroupedMeetings(groups: groups1, hasMore: true, nextOffset: 50),
//            PaginatedGroupedMeetings(groups: groups2, hasMore: false, nextOffset: 100)
//        ]
//
//        viewModel.loadInitialData()
//        viewModel.loadMoreUpcomingMeetings()
//
//        #expect(viewModel.groupedNext.count == 1)
//        #expect(viewModel.groupedNext[0].timeSlots.count == 2)
//    }
//
//    @Test("merging groups combines meetings at same time")
//    func testMergeGroupsSameTime() {
//        let (viewModel, _, _, _, _, _, upcomingUseCase) = createViewModel()
//
//        let date = Date()
//        let meeting1 = createMeeting(title: "Meeting 1", start: date)
//        let meeting2 = createMeeting(title: "Meeting 2", start: date)
//
//        let groups1: GroupedMeetings = [
//            (day: date, timeSlots: [(time: date, meetings: [meeting1])])
//        ]
//        let groups2: GroupedMeetings = [
//            (day: date, timeSlots: [(time: date, meetings: [meeting2])])
//        ]
//
//        upcomingUseCase.resultsToReturn = [
//            PaginatedGroupedMeetings(groups: groups1, hasMore: true, nextOffset: 50),
//            PaginatedGroupedMeetings(groups: groups2, hasMore: false, nextOffset: 100)
//        ]
//
//        viewModel.loadInitialData()
//        viewModel.loadMoreUpcomingMeetings()
//
//        #expect(viewModel.groupedNext.count == 1)
//        #expect(viewModel.groupedNext[0].timeSlots.count == 1)
//        #expect(viewModel.groupedNext[0].timeSlots[0].meetings.count == 2)
//    }
//
//    @Test("merging maintains chronological order")
//    func testMergeGroupsMaintainsOrder() {
//        let (viewModel, _, _, _, _, _, upcomingUseCase) = createViewModel()
//
//        let date1 = Date()
//        let date2 = date1.addingTimeInterval(86400)
//        let date3 = date1.addingTimeInterval(172800)
//
//        let meeting1 = createMeeting(title: "Meeting 1", start: date1)
//        let meeting2 = createMeeting(title: "Meeting 2", start: date2)
//        let meeting3 = createMeeting(title: "Meeting 3", start: date3)
//
//        // Load in non-chronological order
//        let groups1: GroupedMeetings = [
//            (day: date2, timeSlots: [(time: date2, meetings: [meeting2])])
//        ]
//        let groups2: GroupedMeetings = [
//            (day: date1, timeSlots: [(time: date1, meetings: [meeting1])]),
//            (day: date3, timeSlots: [(time: date3, meetings: [meeting3])])
//        ]
//
//        upcomingUseCase.resultsToReturn = [
//            PaginatedGroupedMeetings(groups: groups1, hasMore: true, nextOffset: 50),
//            PaginatedGroupedMeetings(groups: groups2, hasMore: false, nextOffset: 100)
//        ]
//
//        viewModel.loadInitialData()
//        viewModel.loadMoreUpcomingMeetings()
//
//        #expect(viewModel.groupedNext.count == 3)
//        #expect(viewModel.groupedNext[0].day < viewModel.groupedNext[1].day)
//        #expect(viewModel.groupedNext[1].day < viewModel.groupedNext[2].day)
//    }
//
//    // MARK: - Tab Tests
//
//    @Test("Tab enum has correct cases")
//    func testTabCases() {
//        let tabs = MeetingsViewModel.Tab.allCases
//        #expect(tabs.count == 2)
//        #expect(tabs.contains(.next))
//        #expect(tabs.contains(.past))
//    }
//
//    @Test("Tab enum raw values are correct")
//    func testTabRawValues() {
//        #expect(MeetingsViewModel.Tab.next.rawValue == 0)
//        #expect(MeetingsViewModel.Tab.past.rawValue == 1)
//    }
//
//    @Test("selectedTab can be changed")
//    func testSelectedTabChange() {
//        let (viewModel, _, _, _, _, _, _) = createViewModel()
//
//        #expect(viewModel.selectedTab == .next)
//
//        viewModel.selectedTab = .past
//        #expect(viewModel.selectedTab == .past)
//    }
//
//    // MARK: - Edge Cases
//
//    @Test("multiple refreshes work correctly")
//    func testMultipleRefreshes() {
//        let (viewModel, _, _, _, pastUseCase, ongoingUseCase, upcomingUseCase) = createViewModel()
//
//        viewModel.loadInitialData()
//        viewModel.loadInitialData()
//        viewModel.loadInitialData()
//
//        #expect(ongoingUseCase.invokeCallCount == 3)
//        #expect(pastUseCase.invokeCallCount == 3)
//        #expect(upcomingUseCase.invokeCallCount == 3)
//    }
//
//    @Test("empty state remains consistent")
//    func testEmptyStateConsistency() {
//        let (viewModel, _, _, _, pastUseCase, ongoingUseCase, upcomingUseCase) = createViewModel()
//
//        ongoingUseCase.meetingsToReturn = []
//        pastUseCase.groupsToReturn = []
//        upcomingUseCase.resultsToReturn = [
//            PaginatedGroupedMeetings(groups: [], hasMore: false, nextOffset: 0)
//        ]
//
//        viewModel.loadInitialData()
//
//        #expect(viewModel.ongoingMeetings.isEmpty)
//        #expect(viewModel.groupedPastMeetings.isEmpty)
//        #expect(viewModel.groupedNext.isEmpty)
//        #expect(viewModel.showMoreButton == false)
//    }
//
//    @Test("pagination offset increases correctly")
//    func testPaginationOffsetIncreases() {
//        let (viewModel, _, _, _, _, _, upcomingUseCase) = createViewModel()
//
//        upcomingUseCase.resultsToReturn = [
//            PaginatedGroupedMeetings(groups: [], hasMore: true, nextOffset: 50),
//            PaginatedGroupedMeetings(groups: [], hasMore: true, nextOffset: 100),
//            PaginatedGroupedMeetings(groups: [], hasMore: false, nextOffset: 150)
//        ]
//
//        viewModel.loadInitialData()
//        #expect(upcomingUseCase.capturedOffset[0] == 0)
//
//        viewModel.loadMoreUpcomingMeetings()
//        #expect(upcomingUseCase.capturedOffset[1] == 50)
//
//        viewModel.loadMoreUpcomingMeetings()
//        #expect(upcomingUseCase.capturedOffset[2] == 100)
//    }
// }
