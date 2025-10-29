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

@Suite("MeetingsGrouper Tests")
struct MeetingsGrouperTests {

    let grouper = MeetingsGrouper()
    let calendar = Calendar.current

    // MARK: - Helpers

    func createMeeting(
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

    // MARK: - Grouping by Day Tests

    @Test("group meetings by day without hour grouping")
    func testGroupByDayOnly() {
        let now = Date()
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else {
            Issue.record("Failed to create tomorrow date")
            return
        }

        let meetings = [
            createMeeting(title: "Meeting 1", start: now),
            createMeeting(title: "Meeting 2", start: now.addingTimeInterval(3600)),
            createMeeting(title: "Meeting 3", start: tomorrow)
        ]

        let result = grouper.group(meetings, byHours: false, sort: .ascending)

        #expect(result.count == 2)
        #expect(result[0].timeSlots.count == 1)
        #expect(result[0].timeSlots[0].meetings.count == 2)
        #expect(result[1].timeSlots.count == 1)
        #expect(result[1].timeSlots[0].meetings.count == 1)
    }

    @Test("group meetings by day and hour")
    func testGroupByDayAndHour() {
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        components.hour = 10
        components.minute = 0

        guard let date1 = calendar.date(from: components) else {
            Issue.record("Failed to create first date")
            return
        }

        components.hour = 10
        components.minute = 30
        guard let date2 = calendar.date(from: components) else {
            Issue.record("Failed to create second date")
            return
        }

        components.hour = 14
        components.minute = 0
        guard let date3 = calendar.date(from: components) else {
            Issue.record("Failed to create third date")
            return
        }

        let meetings = [
            createMeeting(title: "Morning Meeting 1", start: date1),
            createMeeting(title: "Morning Meeting 2", start: date2),
            createMeeting(title: "Afternoon Meeting", start: date3)
        ]

        let result = grouper.group(meetings, byHours: true, sort: .ascending)

        #expect(result.count == 1)
        #expect(result[0].timeSlots.count == 2)
        #expect(result[0].timeSlots[0].meetings.count == 2)
        #expect(result[0].timeSlots[1].meetings.count == 1)
    }

    // MARK: - Sorting Tests

    @Test("group meetings in ascending order")
    func testAscendingSort() {
        let now = Date()
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else {
            Issue.record("Failed to create test dates")
            return
        }

        let meetings = [
            createMeeting(title: "Tomorrow", start: tomorrow),
            createMeeting(title: "Yesterday", start: yesterday),
            createMeeting(title: "Today", start: now)
        ]

        let result = grouper.group(meetings, byHours: false, sort: .ascending)

        #expect(result.count == 3)
        #expect(result[0].day < result[1].day)
        #expect(result[1].day < result[2].day)
    }

    @Test("group meetings in descending order")
    func testDescendingSort() {
        let now = Date()
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else {
            Issue.record("Failed to create test dates")
            return
        }

        let meetings = [
            createMeeting(title: "Yesterday", start: yesterday),
            createMeeting(title: "Today", start: now),
            createMeeting(title: "Tomorrow", start: tomorrow)
        ]

        let result = grouper.group(meetings, byHours: false, sort: .descending)

        #expect(result.count == 3)
        #expect(result[0].day > result[1].day)
        #expect(result[1].day > result[2].day)
    }

    // MARK: - Meeting Sorting Within Groups

    @Test("meetings are sorted by start time within groups")
    func testMeetingsSortedWithinGroups() {
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        components.hour = 14
        components.minute = 0

        guard let date1 = calendar.date(from: components) else {
            Issue.record("Failed to create first date")
            return
        }

        components.hour = 10
        guard let date2 = calendar.date(from: components) else {
            Issue.record("Failed to create second date")
            return
        }

        components.hour = 12
        guard let date3 = calendar.date(from: components) else {
            Issue.record("Failed to create third date")
            return
        }

        let meetings = [
            createMeeting(title: "Afternoon", start: date1),
            createMeeting(title: "Morning", start: date2),
            createMeeting(title: "Noon", start: date3)
        ]

        let result = grouper.group(meetings, byHours: false, sort: .ascending)

        #expect(result.count == 1)
        let sortedMeetings = result[0].timeSlots[0].meetings
        #expect(sortedMeetings.count == 3)
        #expect(sortedMeetings[0].title == "Morning")
        #expect(sortedMeetings[1].title == "Noon")
        #expect(sortedMeetings[2].title == "Afternoon")
    }

    @Test("meetings with same start time are sorted by title")
    func testMeetingsSortedByTitleWhenSameStartTime() {
        let now = Date()

        let meetings = [
            createMeeting(title: "Zebra Meeting", start: now),
            createMeeting(title: "Alpha Meeting", start: now),
            createMeeting(title: "Beta Meeting", start: now)
        ]

        let result = grouper.group(meetings, byHours: false, sort: .ascending)

        #expect(result.count == 1)
        let sortedMeetings = result[0].timeSlots[0].meetings
        #expect(sortedMeetings.count == 3)
        #expect(sortedMeetings[0].title == "Alpha Meeting")
        #expect(sortedMeetings[1].title == "Beta Meeting")
        #expect(sortedMeetings[2].title == "Zebra Meeting")
    }

    // MARK: - Edge Cases

    @Test("group empty meetings array")
    func testGroupEmptyMeetings() {
        let meetings: [Meeting] = []

        let result = grouper.group(meetings, byHours: false, sort: .ascending)

        #expect(result.isEmpty)
    }

    @Test("group single meeting")
    func testGroupSingleMeeting() {
        let now = Date()
        let meetings = [
            createMeeting(title: "Single Meeting", start: now)
        ]

        let result = grouper.group(meetings, byHours: false, sort: .ascending)

        #expect(result.count == 1)
        #expect(result[0].timeSlots.count == 1)
        #expect(result[0].timeSlots[0].meetings.count == 1)
        #expect(result[0].timeSlots[0].meetings[0].title == "Single Meeting")
    }

    @Test("group meetings across multiple days with hours")
    func testGroupMultipleDaysWithHours() {
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15

        components.hour = 10
        guard let day1Time1 = calendar.date(from: components) else {
            Issue.record("Failed to create date")
            return
        }

        components.hour = 14
        guard let day1Time2 = calendar.date(from: components) else {
            Issue.record("Failed to create date")
            return
        }

        components.day = 16
        components.hour = 10
        guard let day2Time1 = calendar.date(from: components) else {
            Issue.record("Failed to create date")
            return
        }

        components.hour = 14
        guard let day2Time2 = calendar.date(from: components) else {
            Issue.record("Failed to create date")
            return
        }

        let meetings = [
            createMeeting(title: "Day 1 Morning", start: day1Time1),
            createMeeting(title: "Day 1 Afternoon", start: day1Time2),
            createMeeting(title: "Day 2 Morning", start: day2Time1),
            createMeeting(title: "Day 2 Afternoon", start: day2Time2)
        ]

        let result = grouper.group(meetings, byHours: true, sort: .ascending)

        #expect(result.count == 2)
        #expect(result[0].timeSlots.count == 2)
        #expect(result[1].timeSlots.count == 2)
    }

    @Test("hour grouping rounds down to hour boundary")
    func testHourGroupingRoundsToHourBoundary() {
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        components.hour = 10

        components.minute = 15
        guard let time1 = calendar.date(from: components) else {
            Issue.record("Failed to create date")
            return
        }

        components.minute = 45
        guard let time2 = calendar.date(from: components) else {
            Issue.record("Failed to create date")
            return
        }

        let meetings = [
            createMeeting(title: "Meeting 1", start: time1),
            createMeeting(title: "Meeting 2", start: time2)
        ]

        let result = grouper.group(meetings, byHours: true, sort: .ascending)

        #expect(result.count == 1)
        #expect(result[0].timeSlots.count == 1)
        #expect(result[0].timeSlots[0].meetings.count == 2)
    }
}
