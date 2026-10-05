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

import notify
import WireFoundation
import WireNetwork
import XCTest

/// [calling]
final class MeetingsTests: WireUITestCase {

    private let fixtureDate = Date()

    @MainActor
    func testRecurringMeetingsGroupOccurrencesByLocalDay_TC_11935() async throws {
        let (owner, _, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 0)
        let meetings = try await MeetingsTestHelper(user: owner)
        let now = day(0)
        let daily = try await meetings.create(
            title: "TC11935 daily",
            start: day(2, hour: 9),
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1, until: day(4, hour: 9))
        )
        let weekly = try await meetings.create(
            title: "TC11935 weekly",
            start: day(3, hour: 10),
            recurrence: MeetingRecurrence(frequency: .weekly, interval: 1, until: day(17, hour: 10))
        )
        let everyTwoWeeks = try await meetings.create(
            title: "TC11935 every two weeks",
            start: day(4, hour: 11),
            recurrence: MeetingRecurrence(frequency: .weekly, interval: 2, until: day(32, hour: 11))
        )
        let everyFourWeeks = try await meetings.create(
            title: "TC11935 every four weeks",
            start: day(5, hour: 12),
            recurrence: MeetingRecurrence(frequency: .weekly, interval: 4, until: day(61, hour: 12))
        )

        let meetingsPage = try launchMeetings(for: owner, now: now, locale: "en_GB")
        let expectedRows: [(MeetingResponse, Date)] = [
            (daily, day(2, hour: 9)),
            (daily, day(3, hour: 9)),
            (weekly, day(3, hour: 10)),
            (daily, day(4, hour: 9)),
            (everyTwoWeeks, day(4, hour: 11)),
            (everyFourWeeks, day(5, hour: 12)),
            (weekly, day(10, hour: 10)),
            (weekly, day(17, hour: 10)),
            (everyTwoWeeks, day(18, hour: 11)),
            (everyTwoWeeks, day(32, hour: 11)),
            (everyFourWeeks, day(33, hour: 12)),
            (everyFourWeeks, day(61, hour: 12))
        ]
        try meetingsPage.assertOccurrences(expectedRows, now: now, locale: "en_GB")
        try meetingsPage.scrollToTop(first: daily)

        XCTAssertEqual(try meetingsPage.showRow(daily).staticTexts["meetingRecurrence"].label, "Daily")
        XCTAssertTrue(try meetingsPage.showRow(weekly, start: day(3, hour: 10)).staticTexts["Weekly"].exists)
        XCTAssertTrue(
            try meetingsPage.showRow(everyTwoWeeks, start: day(4, hour: 11))
                .staticTexts["Every 2 weeks"].exists
        )
        let fourWeekRow = try meetingsPage.showRow(everyFourWeeks, start: day(5, hour: 12))
        XCTAssertTrue(fourWeekRow.staticTexts["Every 4 weeks"].exists)
        XCTAssertFalse(fourWeekRow.staticTexts["Monthly"].exists)
    }

    @MainActor
    func testMeetingsPaginationKeepsOccurrenceOrderAfterScrollingBack_TC_11936() async throws {
        let (owner, _, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 0)
        let meetings = try await MeetingsTestHelper(user: owner)
        let now = day(0)
        // Meet Now uses the same API with a one-hour meeting that starts now.
        let instant = try await meetings.create(title: "Meet now", start: now, duration: 3600)
        var singleMeetings: [MeetingResponse] = []

        for offset in [3, 12, 22, 32] {
            singleMeetings.append(try await meetings.create(
                title: "TC11936 scheduled \(offset)",
                start: day(offset, hour: 8)
            ))
        }
        let daily = try await meetings.create(
            title: "TC11936 finite daily recurrence",
            start: day(2, hour: 9),
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1, until: day(42, hour: 9))
        )

        let meetingsPage = try launchMeetings(for: owner, now: now, locale: "en_GB")
        // Pagination uses occurrences. Keep 46 rows without creating 43 MLS conversations at login.
        let expectedRows = [(instant, now)] + singleMeetings.map { ($0, $0.startTime) }
            + (2 ... 42).map { (daily, day($0, hour: 9)) }
        try meetingsPage.assertOccurrences(expectedRows, now: now, locale: "en_GB")
        XCTAssertFalse(app.buttons["Show More"].exists)
        XCTAssertFalse(app.buttons["Load More"].exists)

        try meetingsPage.scrollToTop(first: instant)
        try meetingsPage.assertOccurrences(expectedRows, now: now, locale: "en_GB")
    }

    @MainActor
    func testDuplicateMeetingsKeepActionsBoundToSelectedRecord_TC_11942() async throws {
        let (owner, _, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 0)
        let fixtures = try await MeetingsTestHelper(user: owner)
        let start = day(3, hour: 10)
        let originalTitle = "TC11942 same visible details"
        let first = try await fixtures.create(title: originalTitle, start: start)
        let second = try await fixtures.create(title: originalTitle, start: start)
        XCTAssertNotEqual(first.id, second.id, "The fixtures must be separate backend meeting records")

        let page = try launchMeetings(for: owner, now: day(0))
        let firstRow = page.row(first)
        let secondRow = page.row(second)
        XCTAssertTrue(firstRow.waitForExistence(timeout: 15), "First duplicate meeting did not appear")
        XCTAssertTrue(secondRow.waitForExistence(timeout: 15), "Second duplicate meeting did not appear")
        XCTAssertNotEqual(firstRow.identifier, secondRow.identifier)
        XCTAssertEqual(page.meetingRows.count, 2)
        XCTAssertEqual(firstRow.staticTexts["meetingTime"].label, secondRow.staticTexts["meetingTime"].label)
        XCTAssertEqual(firstRow.staticTexts["meetingTitle"].label, originalTitle)
        XCTAssertEqual(secondRow.staticTexts["meetingTitle"].label, originalTitle)

        // Change only the selected second row. Its ID must stay stable, and
        // the first duplicate must keep its original title.
        let form = try page.edit(second)
        form.replaceTitle(with: "TC11942 selected second")
        _ = try form.save()

        XCTAssertTrue(secondRow.staticTexts.matching(
            NSPredicate(format: "label == %@", "TC11942 selected second")
        ).firstMatch.waitForExistence(timeout: 15))
        XCTAssertEqual(secondRow.staticTexts["meetingTitle"].label, "TC11942 selected second")
        XCTAssertEqual(firstRow.staticTexts["meetingTitle"].label, originalTitle)

        let backendRows = try await fixtures.list()
        XCTAssertEqual(backendRows.first(where: { $0.id == first.id })?.title, originalTitle)
        XCTAssertEqual(backendRows.first(where: { $0.id == second.id })?.title, "TC11942 selected second")

        try page.openMenu(for: first)
        XCTAssertTrue(app.buttons["Delete meeting for all"].waitAndTap())
        XCTAssertTrue(app.alerts.buttons["Delete"].waitAndTap())
        XCTAssertTrue(firstRow.waitToDisappear(timeout: 15))
        try page.assertRows([second])
        let remaining = try await fixtures.list()
        XCTAssertEqual(remaining.map(\.id), [second.id])
        XCTAssertEqual(remaining.first?.title, "TC11942 selected second")
    }

    @MainActor
    func testMeetingsRefreshAfterBackgroundResume_TC_11944() async throws {
        let (owner, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: owner)
        var initial: [MeetingResponse] = []
        for offset in 2 ... 6 {
            initial.append(try await fixtures.create(title: "Meeting \(offset)", start: day(offset)))
        }
        let recurring = try await fixtures.create(
            title: "Meetings across loaded pages", start: day(7),
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1, until: day(41))
        )
        let recurringRows = (7 ... 41).map { (recurring, day($0)) }
        let page = try launchMeetings(for: owner, now: day(0))
        try page.assertOccurrences(
            initial.map { ($0, $0.startTime) } + recurringRows, now: day(0), locale: "en_GB"
        )
        try page.scrollToTop(first: initial[0])
        XCTAssertTrue(page.row(initial[0]).isHittable)

        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 5))
        let moved = try await fixtures.update(
            meeting: initial[4], title: "Moved while backgrounded", start: day(42)
        )
        let deleted = initial[0]
        try await fixtures.delete(deleted)
        let created = try await fixtures.create(title: "Created while backgrounded", start: day(43))

        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        XCTAssertTrue(page.row(deleted).waitToDisappear(timeout: 20))
        try page.showRow(created)
        let expected = initial.filter { $0.id != moved.id && $0.id != deleted.id } + [moved, created]
        try page.assertOccurrences(
            expected.map { ($0, $0.startTime) } + recurringRows, now: day(0), locale: "en_GB"
        )
        XCTAssertFalse(page.row(deleted).exists)
        try page.scrollToTop(first: expected[0])
        XCTAssertEqual(try page.showRow(moved).staticTexts["meetingTitle"].label, moved.title)
        XCTAssertEqual(try page.showRow(created).staticTexts["meetingTitle"].label, created.title)
    }

    @MainActor
    func testMeetingsListRetryAfterFetchFailure_TC_11947() async throws {
        let (owner, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: owner)
        let first = try await fixtures.create(title: "Retry first", start: day(1))
        let second = try await fixtures.create(title: "Retry second", start: day(2))
        let failureID = UUID().uuidString
        let name = "\(UITestConfig.meetingsFailureNotificationPrefix).\(failureID)"
        var token: Int32 = NOTIFY_TOKEN_INVALID
        XCTAssertEqual(notify_register_check(name, &token), UInt32(NOTIFY_STATUS_OK))
        defer { notify_cancel(token) }
        XCTAssertEqual(notify_set_state(token, 0), UInt32(NOTIFY_STATUS_OK))
        uiTestConfig.meetingsFailureID = failureID

        let page = try launchMeetings(for: owner, now: day(0))
        let progress = app.descendants(matching: .any)["meetingsLoadProgress"].firstMatch
        XCTAssertTrue(progress.waitForExistence(timeout: 10))
        XCTAssertFalse(page.noUpcomingMeetingsText.exists)
        XCTAssertEqual(page.meetingRows.count, 0)
        XCTAssertEqual(notify_set_state(token, 1), UInt32(NOTIFY_STATUS_OK))
        let error = app.staticTexts["Could not load meetings. Please try again."]
        let retry = app.buttons["meetingsLoadRetryButton"]
        XCTAssertTrue(error.waitForExistence(timeout: 15))
        XCTAssertTrue(retry.isEnabled)
        XCTAssertFalse(page.noUpcomingMeetingsText.exists)

        XCTAssertEqual(notify_set_state(token, 2), UInt32(NOTIFY_STATUS_OK))
        retry.tap()
        XCTAssertTrue(page.row(first).waitForExistence(timeout: 15))
        XCTAssertFalse(error.exists)
        XCTAssertFalse(retry.exists)
        try page.assertRows([first, second])
    }

    @MainActor
    func testCompletedMeetingsRemainUntilLocalMidnight_TC_11934() async throws {
        let (owner, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: owner)
        let oneOff = try await fixtures.create(title: "Completed one-off", start: day(0, hour: 10))
        let recurring = try await fixtures.create(
            title: "Completed daily occurrence", start: day(0, hour: 11),
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1, until: day(1, hour: 11))
        )
        let calendar = Calendar.current
        let beforeMidnight = try XCTUnwrap(calendar.date(bySettingHour: 23, minute: 59, second: 0, of: day(0)))
        let afterMidnight = calendar.startOfDay(for: day(1)).addingTimeInterval(60)
        let nextOccurrence = day(1, hour: 11)
        XCTAssertLessThan(oneOff.endTime, beforeMidnight)
        XCTAssertLessThan(recurring.endTime, beforeMidnight)
        let clockID = UUID().uuidString
        uiTestConfig.meetingsClockID = clockID
        let page = try launchMeetings(for: owner, now: beforeMidnight)
        try page.assertOccurrences([
            (oneOff, oneOff.startTime), (recurring, recurring.startTime), (recurring, nextOccurrence)
        ])
        try page.assertDayHeaders([day(0), day(1)], now: beforeMidnight, locale: "en_GB")
        try page.scrollToTop(first: oneOff)
        XCTAssertTrue(page.row(oneOff).isHittable)
        XCTAssertTrue(page.row(recurring).isHittable)

        let name = "\(UITestConfig.meetingsClockNotificationPrefix).\(clockID)"
        XCTAssertEqual(notify_post(name), UInt32(NOTIFY_STATUS_OK))
        XCTAssertTrue(page.row(oneOff).waitToDisappear(timeout: 20))
        XCTAssertTrue(page.row(recurring).waitToDisappear(timeout: 20))
        XCTAssertTrue(page.row(recurring, start: nextOccurrence).waitForExistence(timeout: 20))
        try page.assertOccurrences([(recurring, nextOccurrence)])
        try page.assertDayHeaders([day(1)], now: afterMidnight, locale: "en_GB")
        let stored = try await fixtures.list()
        XCTAssertEqual(Set(stored.map(\.id)), Set([oneOff.id, recurring.id]))
    }

    private func registerClients(for users: [UserInfo]) async throws {
        for user in users {
            _ = try await testServicesClient.getInstanceId(
                email: user.email, password: user.password, name: user.name, verificationCode: nil
            )
        }
    }

    @MainActor
    private func assertMenu(on page: MeetingsPage, meeting: MeetingResponse, isHost: Bool) throws {
        try page.openMenu(for: meeting)
        XCTAssertTrue(app.buttons["Join now"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Join now"].isEnabled)
        XCTAssertEqual(app.buttons["Edit meeting"].exists, isHost)
        XCTAssertEqual(app.buttons["Delete meeting for all"].exists, isHost)
        XCTAssertEqual(app.buttons["Delete meeting for me"].exists, !isHost)
        if isHost {
            XCTAssertTrue(app.buttons["Edit meeting"].isEnabled)
            XCTAssertTrue(app.buttons["Delete meeting for all"].isEnabled)
        } else {
            XCTAssertTrue(app.buttons["Delete meeting for me"].isEnabled)
        }
        app.navigationBars.staticTexts["Meetings"].tap()
        XCTAssertTrue(app.buttons["Join now"].waitToDisappear(timeout: 5))
    }

    private func day(_ offset: Int, hour: Int = 9) -> Date {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: offset + 1, to: calendar.startOfDay(for: fixtureDate))!
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
    }

    @MainActor
    private func launchMeetings(
        for user: UserInfo,
        now: Date,
        locale: String = "en_GB"
    ) throws -> MeetingsPage {
        app.terminate()
        uiTestConfig.meetingsDate = now
        app.launchEnvironment[UITestConfig.environmentKey] = uiTestConfig.encode()
        app.launchArguments = ["-resetData", "--useEnvStaging", "-AppleLanguages", "(en)", "-AppleLocale", locale]
        app.setDeveloperFlags([.useWireAuthentication: true])
        app.launch()
        return try app.loginUser(email: user.email, password: user.password).acceptPopup().openMeetings()
    }

    @MainActor
    func testEmptyMeetingsListShowsCreationOptions_TC_11932() async throws {
        let (teamOwner, _, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 0)
        let meetingsPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
            .openMeetings()

        XCTAssertTrue(
            meetingsPage.noUpcomingMeetingsText.waitForExistence(timeout: 10),
            "The empty upcoming meetings message did not appear"
        )
        XCTAssertEqual(meetingsPage.meetingRows.count, 0, "The empty list contained meeting rows")
        XCTAssertEqual(meetingsPage.dayHeaders.count, 0, "The empty list contained day headers")
        XCTAssertTrue(meetingsPage.createMeetingButton.isEnabled, "The create meeting button was disabled")

        meetingsPage.createMeetingButton.tap()

        XCTAssertTrue(meetingsPage.meetNowOption.waitForExistence(timeout: 5), "Meet Now did not appear")
        XCTAssertTrue(meetingsPage.scheduleMeetingOption.exists, "Schedule a Meeting did not appear")
    }
}
