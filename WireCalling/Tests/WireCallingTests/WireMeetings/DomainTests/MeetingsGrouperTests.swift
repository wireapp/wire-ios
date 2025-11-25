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

    // MARK: - Grouping by Day Tests

    @Test("group meetings by day without hour grouping")
    func testGroupByDayOnly() {
        let today = makeDate(day: 15, hour: 10, minute: 0, issueMessage: "Failed to create today date")

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
            Issue.record("Failed to create tomorrow date")
            return
        }

        let meetings = [
            createMeeting(title: "Meeting 1", start: today),
            createMeeting(title: "Meeting 2", start: today.addingTimeInterval(3600)),
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
        let date1 = makeDate(day: 15, hour: 10, minute: 0, issueMessage: "Failed to create first date")
        let date2 = makeDate(day: 15, hour: 10, minute: 30, issueMessage: "Failed to create second date")
        let date3 = makeDate(day: 15, hour: 14, minute: 0, issueMessage: "Failed to create third date")
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
        let today = makeDate(day: 15, hour: 10, minute: 0, issueMessage: "Failed to create today date")
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)
        else {
            Issue.record("Failed to create test dates")
            return
        }

        let meetings = [
            createMeeting(title: "Tomorrow", start: tomorrow),
            createMeeting(title: "Yesterday", start: yesterday),
            createMeeting(title: "Today", start: today)
        ]

        let result = grouper.group(meetings, byHours: false, sort: .ascending)

        #expect(result.count == 3)
        #expect(result[0].day < result[1].day)
        #expect(result[1].day < result[2].day)
    }

    @Test("group meetings in descending order")
    func testDescendingSort() {
        let today = makeDate(day: 15, hour: 10, minute: 0, issueMessage: "Failed to create today date")
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)
        else {
            Issue.record("Failed to create test dates")
            return
        }

        let meetings = [
            createMeeting(title: "Yesterday", start: yesterday),
            createMeeting(title: "Today", start: today),
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
        let date1 = makeDate(day: 15, hour: 14, minute: 0, issueMessage: "Failed to create first date")
        let date2 = makeDate(day: 15, hour: 10, minute: 0, issueMessage: "Failed to create second date")
        let date3 = makeDate(day: 15, hour: 12, minute: 0, issueMessage: "Failed to create third date")

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
        let sameTime = makeDate(day: 15, hour: 10, minute: 0, issueMessage: "Failed to create date")

        let meetings = [
            createMeeting(title: "Zebra Meeting", start: sameTime),
            createMeeting(title: "Alpha Meeting", start: sameTime),
            createMeeting(title: "Beta Meeting", start: sameTime)
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
        let date = makeDate(day: 15, hour: 10, minute: 0, issueMessage: "Failed to create date")

        let meetings = [
            createMeeting(title: "Single Meeting", start: date)
        ]

        let result = grouper.group(meetings, byHours: false, sort: .ascending)

        #expect(result.count == 1)
        #expect(result[0].timeSlots.count == 1)
        #expect(result[0].timeSlots[0].meetings.count == 1)
        #expect(result[0].timeSlots[0].meetings[0].title == "Single Meeting")
    }

    @Test("group meetings across multiple days with hours")
    func testGroupMultipleDaysWithHours() {
        let day1Time1 = makeDate(day: 15, hour: 10, minute: 0)
        let day1Time2 = makeDate(day: 15, hour: 14, minute: 0)
        let day2Time1 = makeDate(day: 16, hour: 10, minute: 0)
        let day2Time2 = makeDate(day: 16, hour: 14, minute: 0)

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
        let time1 = makeDate(day: 15, hour: 10, minute: 15)
        let time2 = makeDate(day: 15, hour: 10, minute: 45)

        let meetings = [
            createMeeting(title: "Meeting 1", start: time1),
            createMeeting(title: "Meeting 2", start: time2)
        ]

        let result = grouper.group(meetings, byHours: true, sort: .ascending)

        #expect(result.count == 1)
        #expect(result[0].timeSlots.count == 1)
        #expect(result[0].timeSlots[0].meetings.count == 2)
    }

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

    func makeDate(
        year: Int = 2025,
        month: Int = 1,
        day: Int = 15,
        hour: Int,
        minute: Int = 0,
        issueMessage: String = "Failed to create date"
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute

        guard let date = calendar.date(from: components) else {
            Issue.record(issueMessage)
            fatalError(issueMessage)
        }

        return date
    }

}
