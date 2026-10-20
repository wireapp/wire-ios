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
import WireLocators
import WireNetwork
import XCTest

/// [collaboration]
final class MeetNowTests: WireUITestCase {

    @MainActor
    private func launchMeetings(for user: UserInfo, locale: String = "en_GB") throws -> MeetingsPage {
        app.terminate()
        app.launchEnvironment[UITestConfig.environmentKey] = uiTestConfig.encode()
        app.launchArguments = ["-resetData", "--useEnvStaging", "-AppleLanguages", "(en)", "-AppleLocale", locale]
        app.setDeveloperFlags([.useWireAuthentication: true])
        app.launch()
        return try app.loginUser(email: user.email, password: user.password).acceptPopup().openMeetings()
    }

    @MainActor
    private func openMeetNow(from page: MeetingsPage) throws -> MeetingFormPage {
        guard page.createMeetingButton.waitAndTap(), page.meetNowOption.waitAndTap() else {
            throw RuntimeError("Meet Now did not appear")
        }
        return try MeetingFormPage()
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
        XCTAssertEqual(meetings.count, 1, "Meet Now must create exactly one meeting")
        let meeting = try XCTUnwrap(meetings.first)
        XCTAssertEqual(meeting.title, title)
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
    private func waitForCall(title: String) throws -> OngoingCallPage {
        let timer = app.staticTexts[Locators.OngoingCallPage.timeLabel.rawValue]
        let microphonePermission = springboard.alerts.buttons["Allow"].firstMatch
        let durationPattern = "^[0-9]+:[0-5][0-9]$"
        let callOrPermission = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            microphonePermission.exists || (timer.exists && timer.label.range(
                of: durationPattern, options: .regularExpression
            ) != nil)
        }, object: nil)
        guard XCTWaiter().wait(for: [callOrPermission], timeout: 30) == .completed else {
            throw RuntimeError("Meet Now did not open the call or request microphone access")
        }
        if microphonePermission.exists { microphonePermission.tap() }
        let established = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND label MATCHES %@", durationPattern),
            object: timer
        )
        guard XCTWaiter().wait(for: [established], timeout: 30) == .completed else {
            throw RuntimeError("Meet Now did not enter the call without an additional Join action")
        }
        let call = try OngoingCallPage()
        call.verifyGroupNameAndTimerShowingOnceCallJoined(groupName: title)
        return call
    }

    @MainActor
    private func assertMeetingRow(
        _ meeting: MeetingResponse,
        on page: MeetingsPage,
        locale: String = "en_GB"
    ) throws {
        let row = try page.showRow(meeting)
        XCTAssertEqual(row.staticTexts[Locators.WireMeetings.MeetingRow.title.rawValue].label, meeting.title)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: locale)
        formatter.timeStyle = .short
        let expectedTime = "\(formatter.string(from: meeting.startTime)) - \(formatter.string(from: meeting.endTime))"
        XCTAssertEqual(
            row.staticTexts[Locators.WireMeetings.MeetingRow.time.rawValue].label
                .replacingOccurrences(of: "\u{202F}", with: " "),
            expectedTime.replacingOccurrences(of: "\u{202F}", with: " ")
        )
        try page.assertRows([meeting], now: Date(), locale: locale)
    }

    private func holdCreation() throws -> Int32 {
        let failureID = UUID().uuidString
        let name = "\(UITestConfig.meetingsCreateFailureNotificationPrefix).\(failureID)"
        var token: Int32 = NOTIFY_TOKEN_INVALID
        guard notify_register_check(name, &token) == UInt32(NOTIFY_STATUS_OK) else {
            throw RuntimeError("Meeting create control could not be registered")
        }
        guard notify_set_state(token, 0) == UInt32(NOTIFY_STATUS_OK) else {
            notify_cancel(token)
            throw RuntimeError("Meeting create control could not hold the request")
        }
        uiTestConfig.meetingsCreateFailureID = failureID
        return token
    }

    @MainActor
    func testCancelMeetNow_TC_11971() async throws {
        let (host, users, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 1)
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host)
        let form = try openMeetNow(from: page)
        XCTAssertTrue(form.titleField.exists)
        let emptyTitleValue = form.titleField.value as? String
        XCTAssertTrue(form.participantsButton.exists)
        XCTAssertTrue(form.cancelButton.exists)
        XCTAssertEqual(form.saveButton.label, "Start")
        XCTAssertFalse(form.saveButton.isEnabled)
        XCTAssertFalse(form.startDateButton.exists)
        XCTAssertFalse(form.startTimeButton.exists)
        XCTAssertFalse(app.buttons[Locators.WireMeetings.MeetingForm.endDate.rawValue].exists)
        XCTAssertFalse(form.endTimeButton.exists)
        XCTAssertFalse(form.repeatButton.exists)
        _ = try form.cancel()
        XCTAssertTrue(page.noUpcomingMeetingsText.waitForExistence(timeout: 10))
        let afterEmptyCancel = try await fixtures.list()
        XCTAssertTrue(afterEmptyCancel.isEmpty)
        XCTAssertFalse(app.buttons[Locators.OngoingCallPage.endOngoingCallButton.rawValue].exists)

        let populatedForm = try openMeetNow(from: page)
        XCTAssertEqual(populatedForm.titleField.value as? String, emptyTitleValue)
        populatedForm.replaceTitle(with: "TC11971 discarded")
        try populatedForm.addParticipants(users)
        XCTAssertEqual(populatedForm.participantsButton.value as? String, "1")
        XCTAssertTrue(populatedForm.saveButton.isEnabled)
        _ = try populatedForm.cancel()
        XCTAssertTrue(page.noUpcomingMeetingsText.waitForExistence(timeout: 10))
        XCTAssertEqual(page.meetingRows.count, 0)
        let afterPopulatedCancel = try await fixtures.list()
        XCTAssertTrue(afterPopulatedCancel.isEmpty)
        XCTAssertFalse(app.buttons[Locators.OngoingCallPage.endOngoingCallButton.rawValue].exists)

        let reopenedForm = try openMeetNow(from: page)
        // Empty UIKit text fields can expose the placeholder as their value.
        XCTAssertFalse(reopenedForm.saveButton.isEnabled)
        XCTAssertEqual(reopenedForm.titleField.value as? String, emptyTitleValue)
        XCTAssertEqual(reopenedForm.participantsButton.value as? String, "0")
        _ = try reopenedForm.cancel()
    }

    @MainActor
    func testMeetNowTitleValidation_TC_11973() async throws {
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host)
        let form = try openMeetNow(from: page)
        XCTAssertFalse(form.saveButton.isEnabled)
        form.replaceTitle(with: "   ")
        XCTAssertFalse(form.saveButton.isEnabled)
        let beforeValidTitle = try await fixtures.list()
        XCTAssertTrue(beforeValidTitle.isEmpty)

        for title in ["TC11973 Standard title", String(repeating: "A", count: 64), String(repeating: "😀", count: 64)] {
            form.replaceTitle(with: title)
            XCTAssertEqual(form.titleField.value as? String, title)
            XCTAssertTrue(form.saveButton.isEnabled)
            XCTAssertFalse(form.titleError.exists)
        }
        let invalidTitle = String(repeating: "B", count: 65)
        form.replaceTitle(with: invalidTitle)
        XCTAssertEqual(form.titleField.value as? String, invalidTitle)
        XCTAssertTrue(form.titleError.waitForExistence(timeout: 5))
        XCTAssertFalse(form.saveButton.isEnabled)
        // The separate 256-byte limit also applies when the character count is below 64.
        form.replaceTitle(with: String(repeating: "🧑🏽‍💻", count: 32))
        XCTAssertTrue(form.titleError.waitForExistence(timeout: 5))
        XCTAssertFalse(form.saveButton.isEnabled)
        let beforeStart = try await fixtures.list()
        XCTAssertTrue(beforeStart.isEmpty)

        let title = "TC11973 Meet Now & + / 😀"
        form.replaceTitle(with: title)
        XCTAssertEqual(form.titleField.value as? String, title)
        XCTAssertTrue(form.saveButton.isEnabled)
        XCTAssertTrue(form.saveButton.waitAndTap())
        let call = try waitForCall(title: title)
        let meeting = try await onlyMeeting(fixtures, title: title)
        XCTAssertTrue(call.minimizeCallButton.waitAndTap())
        try assertMeetingRow(meeting, on: MeetingsPage())
    }

    @MainActor
    func testMeetNowParticipants_TC_11974() async throws {
        let (host, users, ids, _) = try await UserHelper.default.registerMeetingsTeam(
            withMemberCount: 3, names: ["Meet Now Host", "Meet Now Alice", "Meet Now Bob", "Meet Now Carol"]
        )
        try await registerClients(for: users)
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host)
        let form = try openMeetNow(from: page)
        let title = "TC11974 selected participants"
        form.replaceTitle(with: title)
        try form.openParticipants()
        for (index, user) in users.enumerated() {
            try form.selectMember(user)
            XCTAssertEqual(form.selectedMembersButton.value as? String, String(index + 1))
            try form.clearMemberSearch()
        }
        for excludedUser in [host, users[0]] {
            form.searchMember(excludedUser.name)
            XCTAssertTrue(form.noMemberSearchResults.waitForExistence(timeout: 10))
            XCTAssertFalse(form.member(excludedUser).exists)
            try form.clearMemberSearch()
        }
        try form.confirmParticipants()
        try form.openParticipants()
        XCTAssertTrue(form.member(users[1]).waitAndTap())
        XCTAssertEqual(form.selectedMembersButton.value as? String, "2")
        try form.confirmParticipants()
        XCTAssertEqual(form.titleField.value as? String, title)
        XCTAssertEqual(form.participantsButton.value as? String, "2")
        XCTAssertTrue(form.participantsButton.label.contains(users[0].name))
        XCTAssertTrue(form.participantsButton.label.contains(users[2].name))
        XCTAssertFalse(form.participantsButton.label.contains(users[1].name))
        XCTAssertTrue(form.saveButton.waitAndTap())
        let call = try waitForCall(title: title)
        let meeting = try await onlyMeeting(fixtures, title: title)
        try await assertMembers(fixtures, meeting: meeting, host: host, invitees: [ids[0], ids[2]])
        let inviteeFixtures = try await MeetingsTestHelper(user: users[0])
        let inviteeMeetings = try await inviteeFixtures.list()
        XCTAssertEqual(inviteeMeetings.map(\.id), [meeting.id])
        XCTAssertTrue(call.minimizeCallButton.waitAndTap())
        let hostPage = try MeetingsPage()
        try assertMeetingRow(meeting, on: hostPage)
        XCTAssertTrue(hostPage.row(meeting).descendants(matching: .any)[
            Locators.WireMeetings.MeetingDetails.attendingLabel.rawValue
        ].waitForExistence(timeout: 10))

        // One simulator checks the accounts in sequence. It does not verify two simultaneous iOS devices.
        let inviteePage = try launchMeetings(for: users[0], locale: "en_US")
        try assertMeetingRow(meeting, on: inviteePage, locale: "en_US")
    }

    @MainActor
    func testRepeatedMeetNowStart_TC_11983() async throws {
        let token = try holdCreation()
        defer { notify_cancel(token) }
        let (host, users, ids, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 1)
        try await registerClients(for: users)
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host)
        let form = try openMeetNow(from: page)
        let title = "TC11983 repeated Start"
        form.replaceTitle(with: title)
        try form.addParticipants(users)
        guard form.saveButton.waitForExistence(timeout: 5), form.saveButton.isHittable else {
            throw RuntimeError("Start was not available")
        }
        let startFrame = form.saveButton.frame
        let startPosition = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: startFrame.midX, dy: startFrame.midY))
        // Use the same screen position after Start becomes a loading indicator.
        startPosition.doubleTap()
        startPosition.tap()
        guard form.loadingIndicator.waitForExistence(timeout: 10), !form.saveButton.exists else {
            throw RuntimeError("Start did not change to a loading indicator")
        }
        let whilePending = try await fixtures.list()
        XCTAssertTrue(whilePending.isEmpty)
        guard notify_set_state(token, 2) == UInt32(NOTIFY_STATUS_OK) else {
            throw RuntimeError("Meeting create control could not release the request")
        }
        let call = try waitForCall(title: title)
        let meeting = try await onlyMeeting(fixtures, title: title)
        try await assertMembers(fixtures, meeting: meeting, host: host, invitees: ids)
        XCTAssertTrue(call.minimizeCallButton.waitAndTap())
        try assertMeetingRow(meeting, on: MeetingsPage())
    }

    @MainActor
    func testRetryMeetNowAfterConnectionFailure_TC_11984() async throws {
        let token = try holdCreation()
        defer { notify_cancel(token) }
        let (host, users, ids, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 1)
        try await registerClients(for: users)
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host)
        let form = try openMeetNow(from: page)
        let title = "TC11984 retry retained details"
        form.replaceTitle(with: title)
        try form.addParticipants(users)
        XCTAssertTrue(form.saveButton.waitAndTap())
        guard form.loadingIndicator.waitForExistence(timeout: 10), !form.saveButton.exists else {
            throw RuntimeError("Start did not change to a loading indicator")
        }
        let whilePending = try await fixtures.list()
        XCTAssertTrue(whilePending.isEmpty)
        guard notify_set_state(token, 1) == UInt32(NOTIFY_STATUS_OK) else {
            throw RuntimeError("Meeting create control could not fail the request")
        }
        let alert = form.schedulingErrorAlert
        guard alert.waitForExistence(timeout: 10) else { throw RuntimeError("The start error did not appear") }
        XCTAssertEqual(alert.label, "Could not start meeting")
        XCTAssertTrue(alert.staticTexts.allElementsBoundByIndex.contains {
            $0.label == "Something went wrong while starting the meeting. Please try again."
        })
        let afterFailure = try await fixtures.list()
        XCTAssertTrue(afterFailure.isEmpty)
        XCTAssertTrue(alert.buttons[Locators.WireMeetings.MeetingForm.errorDismiss.rawValue].firstMatch.waitAndTap())
        XCTAssertEqual(form.titleField.value as? String, title)
        XCTAssertEqual(form.participantsButton.value as? String, "1")
        XCTAssertTrue(form.participantsButton.label.contains(users[0].name))
        guard notify_set_state(token, 2) == UInt32(NOTIFY_STATUS_OK) else {
            throw RuntimeError("Meeting create control could not restore the request")
        }
        XCTAssertTrue(form.saveButton.waitAndTap())
        _ = try waitForCall(title: title)
        let meeting = try await onlyMeeting(fixtures, title: title)
        try await assertMembers(fixtures, meeting: meeting, host: host, invitees: ids)
    }

    @MainActor
    func testMeetNowReportsParticipantWithoutClient_TC_11985() async throws {
        let (host, users, ids, _) = try await UserHelper.default.registerMeetingsTeam(
            withMemberCount: 2, names: ["Meet Now Host", "User A", "User C"]
        )
        try await registerClients(for: [users[0]])
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host)
        let form = try openMeetNow(from: page)
        let title = "TC11985 partial participants"
        form.replaceTitle(with: title)
        try form.addParticipants(users)
        XCTAssertEqual(form.participantsButton.value as? String, "2")
        XCTAssertTrue(form.saveButton.waitAndTap())
        let alert = app.alerts["Meeting created"]
        guard alert.waitForExistence(timeout: 30) else { throw RuntimeError("The participant warning did not appear") }
        XCTAssertEqual(alert.label, "Meeting created")
        let warningLabels = alert.staticTexts.allElementsBoundByIndex.map(\.label)
        guard warningLabels.contains("\(users[1].name) could not be added to the group.") else {
            throw RuntimeError("Unexpected participant warning: \(warningLabels)")
        }
        let meeting = try await onlyMeeting(fixtures, title: title)
        try await assertMembers(fixtures, meeting: meeting, host: host, invitees: [ids[0]])
        guard alert.buttons["OK"].waitAndTap() else { throw RuntimeError("The participant warning could not close") }
        _ = try waitForCall(title: title)
        let afterAcknowledgement = try await onlyMeeting(fixtures, title: title)
        XCTAssertEqual(afterAcknowledgement.id, meeting.id)
        try await assertMembers(fixtures, meeting: meeting, host: host, invitees: [ids[0]])
    }

    @MainActor
    func testMeetNowAfterBackgroundResume_TC_11986() async throws {
        let (host, users, ids, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 1)
        try await registerClients(for: users)
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host)
        let form = try openMeetNow(from: page)
        let title = "TC11986 resume retained details"
        form.replaceTitle(with: title)
        try form.addParticipants(users)
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 10))
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(form.titleField.waitForExistence(timeout: 10))
        XCTAssertEqual(form.titleField.value as? String, title)
        XCTAssertEqual(form.participantsButton.value as? String, "1")
        XCTAssertTrue(form.participantsButton.label.contains(users[0].name))
        XCTAssertTrue(form.saveButton.isEnabled)
        XCTAssertTrue(form.saveButton.waitAndTap())
        _ = try waitForCall(title: title)
        let meeting = try await onlyMeeting(fixtures, title: title)
        try await assertMembers(fixtures, meeting: meeting, host: host, invitees: ids)
    }
}
