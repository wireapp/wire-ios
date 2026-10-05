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
import WireNetwork
import XCTest

class MeetingsPage: PageModel {
    override var pageMainElement: XCUIElement {
        createMeetingButton
    }

    var noUpcomingMeetingsText: XCUIElement {
        app.staticTexts["No upcoming meetings yet"]
    }

    var meetingRows: XCUIElementQuery {
        app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH %@", "meetingRow."))
    }

    var dayHeaders: XCUIElementQuery {
        app.staticTexts.matching(identifier: "meetingsDayHeader")
    }

    var meetingsList: XCUIElement {
        app.descendants(matching: .any)["meetingsList"].firstMatch
    }

    var createMeetingButton: XCUIElement {
        app.buttons["scheduleMeetingBarButton"]
    }

    var meetNowOption: XCUIElement {
        app.buttons["Meet Now"]
    }

    var scheduleMeetingOption: XCUIElement {
        app.buttons["Schedule a Meeting"]
    }

    func row(_ meeting: WireNetwork.MeetingResponse, start: Date? = nil) -> XCUIElement {
        app.otherElements[rowIdentifier(meeting, start: start ?? meeting.startTime)]
    }

    private func rowIdentifier(_ meeting: WireNetwork.MeetingResponse, start: Date) -> String {
        "meetingRow.\(meeting.id.domain).\(meeting.id.id.uuidString).\(Int(start.timeIntervalSince1970))"
    }

    func scrollToTop(first meeting: WireNetwork.MeetingResponse, start: Date? = nil) throws {
        let target = row(meeting, start: start)
        guard meetingsList.waitForExistence(timeout: 10) else {
            throw failure("Meetings list did not appear")
        }

        for _ in 0 ..< 60 {
            if target.exists, target.isHittable,
               visibleDayHeaders().contains(where: { $0.frame.minY < target.frame.minY }) {
                return
            }
            meetingsList.swipeDown()
        }

        throw failure("The first meeting row and its day header did not appear after 60 scroll attempts")
    }

    @discardableResult
    func showRow(_ meeting: WireNetwork.MeetingResponse, start: Date? = nil) throws -> XCUIElement {
        guard meetingsList.waitForExistence(timeout: 10) else {
            throw failure("Meetings list did not appear")
        }

        let target = row(meeting, start: start)
        if target.waitForExistence(timeout: 10), target.isHittable {
            return target
        }

        for _ in 0 ..< 60 {
            if target.exists, target.isHittable {
                return target
            }
            meetingsList.swipeUp()
        }

        throw failure(
            "Meeting '\(meeting.title)' at \(start ?? meeting.startTime) did not appear after 60 scroll attempts"
        )
    }

    private func scrollToTop(until target: XCUIElement) throws {
        guard meetingsList.waitForExistence(timeout: 10) else {
            throw failure("Meetings list did not appear")
        }

        for _ in 0 ..< 60 {
            if target.exists, target.isHittable {
                return
            }
            meetingsList.swipeDown()
        }

        throw failure("The first list item did not appear after 60 scroll attempts")
    }

    func openMenu(for meeting: WireNetwork.MeetingResponse, start: Date? = nil) throws {
        let meetingRow = try showRow(meeting, start: start)
        let menuButton = meetingRow.descendants(matching: .any)["meetingMenu"].firstMatch
        XCTAssertTrue(menuButton.waitAndTap(), "Meeting menu did not appear for '\(meeting.title)'")
    }

    func edit(_ meeting: WireNetwork.MeetingResponse, start: Date? = nil) throws -> MeetingFormPage {
        try openMenu(for: meeting, start: start)
        let editButton = app.buttons["Edit meeting"]
        XCTAssertTrue(editButton.waitAndTap(), "Edit meeting option did not appear")
        return try MeetingFormPage()
    }

    func assertRows(_ meetings: [WireNetwork.MeetingResponse]) throws {
        try assertOccurrences(meetings.map { ($0, $0.startTime) })
    }

    func assertOccurrences(_ occurrences: [(WireNetwork.MeetingResponse, Date)]) throws {
        let ordered = occurrences.sorted { $0.1 < $1.1 }
        guard let first = ordered.first else {
            XCTAssertEqual(meetingRows.count, 0, "The empty meetings list contained rows")
            return
        }

        let expected = ordered.map { rowIdentifier($0.0, start: $0.1) }
        let actual = try scan(
            expected: expected,
            firstElement: row(first.0, start: first.1),
            visibleIdentifiers: { visibleRows().map(\.identifier) },
            itemName: "Meeting rows"
        )
        XCTAssertEqual(actual, expected, "Meeting rows did not match the expected order or count")
    }

    func assertRows(_ meetings: [WireNetwork.MeetingResponse], now: Date, locale: String) throws {
        try assertOccurrences(meetings.map { ($0, $0.startTime) }, now: now, locale: locale)
    }

    func assertOccurrences(
        _ occurrences: [(WireNetwork.MeetingResponse, Date)],
        now: Date,
        locale: String
    ) throws {
        let ordered = occurrences.sorted { $0.1 < $1.1 }
        guard !ordered.isEmpty else {
            XCTAssertEqual(meetingRows.count, 0, "The empty meetings list contained rows")
            XCTAssertEqual(dayHeaders.count, 0, "The empty meetings list contained day headers")
            return
        }

        let calendar = Calendar.current
        let days = ordered.reduce(into: [Date]()) { groupedDays, occurrence in
            let day = calendar.startOfDay(for: occurrence.1)
            if !groupedDays.contains(where: { calendar.isDate($0, inSameDayAs: day) }) {
                groupedDays.append(day)
            }
        }
        let labels = dayHeaderLabels(for: days, now: now, locale: locale)
        var expected: [String] = []
        for (day, label) in zip(days, labels) {
            expected.append("header:\(label)")
            expected += ordered.filter { calendar.isDate($0.1, inSameDayAs: day) }
                .map { "row:\(rowIdentifier($0.0, start: $0.1))" }
        }

        let firstHeader = dayHeaders.matching(NSPredicate(format: "label == %@", labels[0])).firstMatch
        let actual = try scan(
            expected: expected,
            firstElement: firstHeader,
            visibleIdentifiers: { visibleViewport().map(\.0) },
            itemName: "Meeting rows and day headers"
        )
        XCTAssertEqual(actual, expected, "Meeting rows did not appear under their expected day headers")
    }

    func assertDayHeaders(_ days: [Date], now: Date, locale: String) throws {
        guard !days.isEmpty else {
            XCTAssertEqual(dayHeaders.count, 0, "The empty meetings list contained day headers")
            return
        }

        let expected = dayHeaderLabels(for: days, now: now, locale: locale)
        let firstHeader = dayHeaders.matching(NSPredicate(format: "label == %@", expected[0])).firstMatch
        let actual = try scan(
            expected: expected,
            firstElement: firstHeader,
            visibleIdentifiers: { visibleDayHeaders().map(\.label) },
            itemName: "Meeting day headers"
        )
        XCTAssertEqual(actual, expected, "Meeting day headers did not match the expected order or count")
    }

    private func dayHeaderLabels(for days: [Date], now: Date, locale: String) -> [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: locale)
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEEE MMMM d")

        return days.map { day in
            let date = formatter.string(from: day)
            if calendar.isDate(day, inSameDayAs: now) { return "Today (\(date))" }
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
               calendar.isDate(day, inSameDayAs: tomorrow) {
                return "Tomorrow (\(date))"
            }
            return date
        }
    }

    private func scan(
        expected: [String],
        firstElement: XCUIElement,
        visibleIdentifiers: () -> [String],
        itemName: String
    ) throws -> [String] {
        guard expected.count == Set(expected).count else {
            throw failure("Expected \(itemName.lowercased()) contain duplicate identifiers")
        }
        try scrollToTop(until: firstElement)

        var actualIndices: [Int] = []
        var previousIndices: [Int] = []
        for _ in 0 ..< 60 {
            let identifiers = try waitForVisibleIdentifiers(visibleIdentifiers, itemName: itemName)
            guard identifiers.count == Set(identifiers).count else {
                throw failure("\(itemName) repeated in one visible list snapshot")
            }
            let indices = try identifiers.map { identifier -> Int in
                guard let index = expected.firstIndex(of: identifier) else {
                    throw failure("Unexpected \(itemName.lowercased()) item appeared: \(identifier)")
                }
                return index
            }
            guard indices == Array((indices.first ?? 0) ..< (indices.first ?? 0) + indices.count) else {
                throw failure("\(itemName) were out of order or not contiguous in one visible list snapshot")
            }
            if let previousFirst = previousIndices.first,
               let previousLast = previousIndices.last,
               let currentFirst = indices.first,
               let currentLast = indices.last,
               currentFirst < previousFirst || currentFirst > previousLast + 1 || currentLast < previousLast {
                throw failure("\(itemName) repeated or skipped between visible list snapshots")
            }
            for index in indices {
                guard index <= actualIndices.count else {
                    throw failure("\(itemName) skipped between visible list snapshots")
                }
                if index == actualIndices.count {
                    actualIndices.append(index)
                } else if !previousIndices.contains(index) {
                    throw failure("\(itemName) repeated outside the overlapping list snapshots")
                }
            }
            previousIndices = indices

            let viewport = visibleViewport()
            meetingsList.swipeUp()
            try waitForPaginationToFinish()
            if sameViewport(viewport, visibleViewport()) {
                guard actualIndices.count < expected.count else {
                    return actualIndices.map { expected[$0] }
                }
                guard waitForViewportChange(from: viewport) else {
                    throw failure(
                        "Meetings viewport did not change while only \(actualIndices.count) " +
                            "of \(expected.count) expected \(itemName.lowercased()) items were visible"
                    )
                }
            }
        }

        throw failure("\(itemName) did not finish scanning within 60 scroll attempts")
    }

    private func waitForVisibleIdentifiers(
        _ visibleIdentifiers: () -> [String],
        itemName: String
    ) throws -> [String] {
        let deadline = Date().addingTimeInterval(15)
        while Date() < deadline {
            let alert = app.alerts.firstMatch
            if alert.exists {
                let labels = alert.staticTexts.allElementsBoundByIndex.map(\.label)
                throw failure("\(itemName) scan blocked by app alert: \(labels.joined(separator: ", "))")
            }

            let identifiers = visibleIdentifiers()
            if !identifiers.isEmpty { return identifiers }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }

        throw failure("No hittable \(itemName.lowercased()) appeared within 15 seconds")
    }

    private func visibleRows() -> [XCUIElement] {
        meetingsList.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "meetingRow."))
            .allElementsBoundByIndex
            .filter(\.isHittable)
            .sorted { $0.frame.minY < $1.frame.minY }
    }

    private func visibleDayHeaders() -> [XCUIElement] {
        meetingsList.staticTexts.matching(identifier: "meetingsDayHeader")
            .allElementsBoundByIndex
            .filter(\.isHittable)
            .sorted { $0.frame.minY < $1.frame.minY }
    }

    private func visibleViewport() -> [(String, CGFloat)] {
        let rows = visibleRows().map { ("row:\($0.identifier)", $0.frame.minY) }
        let headers = visibleDayHeaders().map { ("header:\($0.label)", $0.frame.minY) }
        return (rows + headers).sorted { $0.1 < $1.1 }
    }

    private func sameViewport(_ first: [(String, CGFloat)], _ second: [(String, CGFloat)]) -> Bool {
        first.count == second.count && zip(first, second).allSatisfy {
            $0.0.0 == $0.1.0 && abs($0.0.1 - $0.1.1) < 1
        }
    }

    private func waitForPaginationToFinish() throws {
        let spinner = meetingsList.descendants(matching: .any)["meetingsPaginationProgress"].firstMatch
        guard spinner.exists, spinner.isHittable else { return }
        guard spinner.waitToDisappear(timeout: 15) else {
            throw failure("Meetings page loading did not finish within 15 seconds")
        }
    }

    private func waitForViewportChange(from viewport: [(String, CGFloat)]) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { [weak self] _, _ in
                guard let self else { return false }
                return !sameViewport(viewport, visibleViewport())
            },
            object: nil
        )
        return XCTWaiter.wait(for: [expectation], timeout: 15) == .completed
    }

    private func failure(_ message: String) -> NSError {
        NSError(domain: "MeetingsPage", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
