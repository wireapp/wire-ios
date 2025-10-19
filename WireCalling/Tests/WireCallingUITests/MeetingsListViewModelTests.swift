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
import WireCallingDomain
import WireCallingUI

// @Suite("MeetingsListViewModel Tests")
// struct MeetingsListViewModelTests {
//    let calendar = Calendar.current
//    let dateFormatter: DateFormatter
//    var viewModel: MeetingsViewModel!
//    let currentDate = Date()
//
//    init() {
//        self.dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
//        dateFormatter.timeZone = TimeZone(abbreviation: "CEST")!
//
//        let meetings: [Meeting] = [
//            Meeting(
//                id: UUID(),
//                title: "Ongoing Meeting",
//                start: calendar.date(byAdding: .minute, value: -5, to: currentDate)!,
//                end: calendar.date(byAdding: .minute, value: 60, to: currentDate)!
//            ),
//            Meeting(
//                id: UUID(),
//                title: "Today Meeting 1",
//                start: calendar.date(byAdding: .hour, value: 1, to: currentDate)!,
//                end: calendar.date(byAdding: .minute, value: 75, to: currentDate)!
//            ),
//            Meeting(
//                id: UUID(),
//                title: "Today Meeting 2",
//                start: calendar.date(byAdding: .hour, value: 2, to: currentDate)!,
//                end: calendar.date(byAdding: .minute, value: 135, to: currentDate)!
//            ),
//            Meeting(
//                id: UUID(),
//                title: "Tomorrow Meeting",
//                start: calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: currentDate))!,
//                end: calendar.date(byAdding: .minute, value: 1445, to: currentDate)!
//            ),
//            Meeting(
//                id: UUID(),
//                title: "Past Today Meeting",
//                start: calendar.date(byAdding: .hour, value: -1, to: currentDate)!,
//                end: calendar.date(byAdding: .minute, value: -30, to: currentDate)!
//            ),
//            Meeting(
//                id: UUID(),
//                title: "Yesterday Meeting",
//                start: calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: currentDate))!,
//                end: calendar.date(byAdding: .hour, value: -6, to: currentDate)!
//            )
//        ]
//
//        self.viewModel = MeetingsViewModel(meetings: meetings, currentDate: currentDate)
//    }
//
//    @Test("Verify ongoing meetings are correctly filtered")
//    func testOngoingMeetings() {
//        let ongoing = viewModel.ongoingMeetings
//        #expect(ongoing.count == 1)
//        #expect(ongoing[0].title == "Ongoing Meeting")
//    }
//
//    @Test("Verify displayed next meetings include today and tomorrow")
//    func testDisplayedNextMeetings() {
//        let next = viewModel.displayedNextMeetings
//        #expect(next.count == 3)
//        let titles = next.map(\.title)
//        #expect(titles.contains("Today Meeting 1"))
//        #expect(titles.contains("Today Meeting 2"))
//        #expect(titles.contains("Tomorrow Meeting"))
//    }
//
//    @Test("Verify hasMoreNext when no meetings exist beyond tomorrow")
//    func testHasMoreNext() {
//        #expect(viewModel.hasMoreNext == false)
//        viewModel.showAllNext = true
//        #expect(viewModel.hasMoreNext == false)
//    }
//
//    @Test("Verify displayed past meetings include today and yesterday")
//    func testDisplayedPastMeetings() {
//        let past = viewModel.displayedPastMeetings
//        #expect(past.count == 2)
//        let titles = past.map(\.title)
//        #expect(titles.contains("Past Today Meeting"))
//        #expect(titles.contains("Yesterday Meeting"))
//    }
//
//    @Test("Verify grouped ongoing meetings have no time grouping")
//    func testGroupedOngoing() {
//        let grouped = viewModel.groupedOngoing
//        #expect(grouped.count == 1)
//        #expect(grouped[0].timeSlots.count == 1)
//        let meetings = grouped[0].timeSlots[0].meetings
//        #expect(meetings.count == 1)
//        #expect(meetings[0].title == "Ongoing Meeting")
//    }
//
//    @Test("Verify grouped next meetings are in ascending order (today, then tomorrow)")
//    func testGroupedNext() {
//        let grouped = viewModel.groupedNext
//        #expect(grouped.count == 2)
//        let dayTitles = grouped.map { viewModel.formatDay($0.day) }
//        #expect(dayTitles == ["Today (Tuesday, October 14)", "Tomorrow (Wednesday, October 15)"])
//
//        let todayGroup = grouped.first { viewModel.calendar.isDate($0.day, inSameDayAs: viewModel.currentDate) }!
//        #expect(!todayGroup.timeSlots.isEmpty)
//        let todayTitles = todayGroup.timeSlots.flatMap(\.meetings).map(\.title)
//        #expect(todayTitles.contains("Today Meeting 1"))
//        #expect(todayTitles.contains("Today Meeting 2"))
//    }
//
//    @Test("Verify grouped past meetings are in descending order (today, then yesterday)")
//    func testGroupedPast() {
//        let grouped = viewModel.groupedPast
//        #expect(grouped.count == 2)
//        let dayTitles = grouped.map { viewModel.formatDay($0.day) }
//        #expect(dayTitles == ["Today (Tuesday, October 14)", "Yesterday (Monday, October 13)"])
//
//        let todayGroup = grouped.first { viewModel.calendar.isDate($0.day, inSameDayAs: viewModel.currentDate) }!
//        #expect(todayGroup.timeSlots.count == 1)
//        let todayTitles = todayGroup.timeSlots.flatMap(\.meetings).map(\.title)
//        #expect(todayTitles.contains("Past Today Meeting"))
//    }
// }
