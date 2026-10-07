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
import notify
import WireFoundation
import WireNetwork
import XCTest

/// [collaboration]
final class ScheduleMeetingTests: WireUITestCase {

    private let fixtureDate = Date()

    private func date(hour: Int = 10, minute: Int = 0, dayOffset: Int = 0) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: 2 + dayOffset, to: calendar.startOfDay(for: fixtureDate))!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    @MainActor
    private func launchMeetings(for user: UserInfo, now: Date, locale: String = "en_GB") throws -> MeetingsPage {
        app.terminate()
        uiTestConfig.meetingsDate = now
        app.launchEnvironment[UITestConfig.environmentKey] = uiTestConfig.encode()
        app.launchArguments = ["-resetData", "--useEnvStaging", "-AppleLanguages", "(en)", "-AppleLocale", locale]
        app.setDeveloperFlags([.useWireAuthentication: true])
        app.launch()
        return try app.loginUser(email: user.email, password: user.password).acceptPopup().openMeetings()
    }

    private func registerClients(for users: [UserInfo]) async throws {
        for user in users {
            _ = try await testServicesClient.getInstanceId(
                email: user.email, password: user.password, name: user.name, verificationCode: nil
            )
        }
    }

    private func onlyMeeting(_ fixtures: MeetingsTestHelper, title: String) async throws -> MeetingResponse {
        let meetings = try await fixtures.list()
        XCTAssertEqual(meetings.count, 1, "Scheduling must create exactly one meeting")
        let meeting = try XCTUnwrap(meetings.first)
        XCTAssertEqual(meeting.title, title)
        XCTAssertGreaterThan(meeting.endTime, meeting.startTime)
        XCTAssertTrue(Calendar.current.isDate(meeting.startTime, inSameDayAs: meeting.endTime))
        return meeting
    }

    private func assertMembers(
        _ fixtures: MeetingsTestHelper,
        meeting: MeetingResponse,
        host: UserInfo,
        invitees: [QualifiedID] = []
    ) async throws {
        let result = try await fixtures.conversationsAPI.getConversations(for: [meeting.conversationID])
        XCTAssertTrue(result.notFound.isEmpty)
        XCTAssertTrue(result.failed.isEmpty)
        let conversation = try XCTUnwrap(result.found.first)
        let members = try XCTUnwrap(conversation.members)
        XCTAssertEqual(meeting.creatorID.id, UUID(uuidString: host.id))
        XCTAssertEqual(members.selfMember?.qualifiedID?.id, UUID(uuidString: host.id))
        XCTAssertEqual(Set(members.others.compactMap(\.qualifiedID)), Set(invitees))
        XCTAssertEqual(members.others.count, invitees.count, "The conversation has missing or duplicate invitees")
    }

    @MainActor
    func testCancelScheduleMeeting_TC_11948() async throws {
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host)
        for locale in ["en_GB", "en_US"] {
            let page = try launchMeetings(for: host, now: date(minute: 7), locale: locale)
            let form = try page.schedule()
            XCTAssertTrue(form.titleField.exists)
            XCTAssertTrue(form.participantsButton.exists)
            XCTAssertTrue(form.repeatButton.exists)
            form.assertDateTimes(start: date(minute: 15), end: date(hour: 11, minute: 15), locale: locale)
            XCTAssertFalse(form.saveButton.isEnabled)
            _ = try form.cancel()
            XCTAssertTrue(page.noUpcomingMeetingsText.waitForExistence(timeout: 10))
            let afterEmptyCancel = try await fixtures.list()
            XCTAssertTrue(afterEmptyCancel.isEmpty)

            let changedForm = try page.schedule()
            changedForm.replaceTitle(with: "TC11948 discarded")
            changedForm.selectRepeat("Daily")
            XCTAssertTrue(changedForm.saveButton.isEnabled)
            _ = try changedForm.cancel()
            XCTAssertTrue(page.noUpcomingMeetingsText.waitForExistence(timeout: 10))
            XCTAssertEqual(page.meetingRows.count, 0)
            let afterChangedCancel = try await fixtures.list()
            XCTAssertTrue(afterChangedCancel.isEmpty)
        }
    }

    @MainActor
    func testDefaultScheduleDateAndDuration_TC_11950() async throws {
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host)
        let datasets: [(now: Date, start: Date, end: Date)] = [
            (date(minute: 7), date(minute: 15), date(hour: 11, minute: 15)),
            (date(), date(minute: 15), date(hour: 11, minute: 15)),
            (date(hour: 23), date(hour: 23, minute: 15), date(hour: 23, minute: 45)),
            (date(hour: 23, minute: 50), date(hour: 0, dayOffset: 1), date(hour: 1, dayOffset: 1)),
            // A default at 23:45 has no valid end. Keep this assertion to expose the product defect.
            (date(hour: 23, minute: 30), date(hour: 0, dayOffset: 1), date(hour: 1, dayOffset: 1))
        ]
        for dataset in datasets {
            let page = try launchMeetings(for: host, now: dataset.now)
            let form = try page.schedule()
            form.assertDateTimes(start: dataset.start, end: dataset.end)
            _ = try form.cancel()
        }
        let meetings = try await fixtures.list()
        XCTAssertTrue(meetings.isEmpty)
    }

}
