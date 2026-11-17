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

import WireFoundation
import WireLocators
import WireNetwork
import XCTest

/// [collaboration]
final class MeetingTimeZoneTests: WireUITestCase, MeetingJoinTesting {

    private let berlin = "Europe/Berlin"
    private let newYork = "America/New_York"

    @MainActor
    func testCreationUsesDeviceTimeZone_TC_12033() async throws {
        executionTimeAllowance = 900
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host, apiVersion: .v18)
        try await requireConferenceCalling()
        for (index, zone) in [berlin, newYork].enumerated() {
            let page = try index == 0
                ? launchMeetings(for: host, timeZone: zone, apiVersion: 18)
                : restartMeetings(now: nil, timeZone: zone)
            // Schedule through the form and read the zone saved by the backend.
            let title = "TC12033 scheduled \(index)"
            let schedule = try page.schedule()
            schedule.replaceTitle(with: title)
            _ = try schedule.save()
            let scheduledMeetings = try await fixtures.list()
            let scheduled = try XCTUnwrap(scheduledMeetings.first { $0.title == title })
            XCTAssertEqual(scheduled.timeZoneIdentifier, zone)
            XCTAssertTrue(try page.showRow(scheduled).exists)
            capture(title)

            // Create Meet Now in the same zone, then end the call before checking the record.
            XCTAssertTrue(page.createMeetingButton.waitAndTap())
            XCTAssertTrue(page.meetNowOption.waitAndTap())
            let instantForm = try MeetingFormPage()
            let instantTitle = "TC12033 Meet Now \(index)"
            instantForm.replaceTitle(with: instantTitle)
            XCTAssertTrue(instantForm.saveButton.waitAndTap())
            let call = try waitForCall(title: instantTitle)
            _ = try leaveCall(call)
            let saved = try await fixtures.list()
            let immediate = try XCTUnwrap(saved.first { $0.title == instantTitle })
            XCTAssertEqual(immediate.timeZoneIdentifier, zone)
            capture(instantTitle)
        }
    }

    @MainActor
    private func restartMeetings(now: Date?, timeZone: String, apiVersion: Int = 18) throws -> MeetingsPage {
        app.terminate()
        uiTestConfig.meetingsDate = now
        app.launchEnvironment[UITestConfig.environmentKey] = uiTestConfig.encode()
        app.launchEnvironment["TZ"] = timeZone
        app.launchArguments.removeAll { $0 == "-resetData" || $0.hasPrefix("--preferred-api-version=") }
        app.launchArguments.append("--preferred-api-version=\(apiVersion)")
        app.launch()
        return try ConversationsPage().openMeetings()
    }

    private func storedMeeting(_ fixtures: MeetingsTestHelper, id: QualifiedID) async throws -> MeetingResponse {
        try await fixtures.api.getMeeting(id: id)
    }

    @MainActor
    private func assertTime(
        _ meeting: MeetingResponse, on page: MeetingsPage, start: Date? = nil, equals expected: String
    ) throws {
        let row = try page.showRow(meeting, start: start)
        XCTAssertEqual(row.staticTexts[Locators.WireMeetings.MeetingRow.title.rawValue].label, meeting.title)
        XCTAssertEqual(row.staticTexts[Locators.WireMeetings.MeetingRow.time.rawValue].label, expected)
        capture("\(meeting.title) \(expected)")
    }

    private func instant(dayOffset: Int = 0, hour: Int = 9, minute: Int = 0, second: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let year = calendar.component(.year, from: Date()) + 1
        var transition = calendar.date(from: DateComponents(year: year, month: 10, day: 31))!
        // Berlin leaves DST on the last Sunday in October; keep backend fixtures in the future.
        while calendar.component(.weekday, from: transition) != 1 {
            transition = calendar.date(byAdding: .day, value: -1, to: transition)!
        }
        let day = calendar.date(byAdding: .day, value: dayOffset, to: transition)!
        return calendar.date(bySettingHour: hour, minute: minute, second: second, of: day)!
    }
}
