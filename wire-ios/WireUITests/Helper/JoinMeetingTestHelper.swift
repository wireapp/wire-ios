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
import WireLocators
import WireNetwork
import XCTest

struct MeetingJoinFixture {
    let host: UserInfo
    let invitee: UserInfo
    let user: UserInfo
    let fixtures: MeetingsTestHelper
    let meeting: MeetingResponse
    let page: MeetingsPage
    let peerID: String?
}

protocol MeetingJoinTesting where Self: WireUITestCase {}

extension MeetingJoinTesting {

    @MainActor
    func launchMeetings(for user: UserInfo, now: Date? = nil) throws -> MeetingsPage {
        app.terminate()
        uiTestConfig.meetingsDate = now
        app.launchEnvironment[UITestConfig.environmentKey] = uiTestConfig.encode()
        app.launchArguments = ["-resetData", "--useEnvStaging", "-AppleLanguages", "(en)", "-AppleLocale", "en_GB"]
        app.setDeveloperFlags([.useWireAuthentication: true])
        app.launch()

        let welcome = try WelcomePage()
        try welcome.typeEmailOrSSO(user.email)
        guard app.buttons[Locators.WelcomePage.nextButton.rawValue].waitAndTap() else {
            throw RuntimeError("The email step did not submit")
        }
        let login = try LoginPage()
        try login.passwordField.tapIfKeyboardNotFocused().typeText(user.password)
        guard app.buttons[Locators.LoginPage.nextButton.rawValue].waitAndTap(timeout: 15) else {
            throw RuntimeError("The password step did not submit")
        }
        let firstTime = try FirstTimePage().acceptFirstTimeAlert()
        guard firstTime.conversationsButton.waitForExistence(timeout: 60) else {
            throw RuntimeError("Initial sign-in did not complete")
        }
        app.dismissAllowIfPresent(timeout: 5)
        // The password sheet can appear after the first-time alert has closed.
        if firstTime.savePasswordSheet.exists {
            capture("Sign-in password sheet")
            guard firstTime.notNowOptionOnSavePasswordSheet.waitAndTap(),
                  firstTime.savePasswordSheet.waitToDisappear() else {
                throw RuntimeError("The save-password sheet did not close")
            }
            capture("Sign-in password sheet dismissed")
        }
        return try ConversationsPage().openMeetings()
    }

    func registerClients(for users: [UserInfo]) async throws {
        for user in users {
            _ = try await testServicesClient.getInstanceId(
                email: user.email, password: user.password, name: user.name, verificationCode: nil
            )
        }
    }

    @MainActor
    func makeMeeting(
        title: String,
        start: Date,
        duration: TimeInterval = 1800,
        recurrence: MeetingRecurrence? = nil,
        asHost: Bool = false,
        withPeer: Bool = false,
        now: Date? = nil
    ) async throws -> MeetingJoinFixture {
        let (host, members, _, _) = try await UserHelper.default.registerMeetingsTeam(
            withMemberCount: withPeer ? 2 : 1
        )
        try await registerClients(for: members)
        let invitee = try XCTUnwrap(members.first)
        let fixtures = try await MeetingsTestHelper(user: host)
        let original = try await fixtures.create(
            title: "\(title) setup", start: start, duration: duration, recurrence: recurrence
        )
        uiTestConfig.meetingsExpectedConversationID = original.conversationID.id
        let hostPage = try launchMeetings(for: host, now: now)
        let form = try hostPage.edit(original)
        form.replaceTitle(with: title)
        try form.addParticipants(members)
        _ = try form.save()
        let stored = try await fixtures.list()
        let meeting = try XCTUnwrap(stored.first { $0.id == original.id })
        var peerID: String?
        if withPeer {
            // Web loads the existing meeting and its MLS group during sign-in.
            try await requireConferenceCalling()
            let environment = try EnvironmentVariables()
            let instances = try await callingServiceClient.createInstances(
                users: [try XCTUnwrap(members.last)], backend: environment.callingBackend, beta: true,
                instanceTypeName: environment.callingInstanceTypeName,
                instanceTypeVersion: environment.callingInstanceTypeVersion
            )
            peerID = try XCTUnwrap(instances.first?.id)
        }
        let user = asHost ? host : invitee
        let page = asHost ? hostPage : try launchMeetings(for: user, now: now)
        _ = try page.showRow(meeting)
        return MeetingJoinFixture(
            host: host, invitee: invitee, user: user, fixtures: fixtures,
            meeting: meeting, page: page, peerID: peerID
        )
    }

    @MainActor
    func joinButton(_ meeting: MeetingResponse, on page: MeetingsPage, start: Date? = nil) -> XCUIElement {
        page.row(meeting, start: start).buttons[Locators.WireMeetings.MeetingRow.joinButton.rawValue]
    }

    @MainActor
    func assertJoinNow(_ meeting: MeetingResponse, on page: MeetingsPage, start: Date? = nil) throws {
        try page.openMenu(for: meeting, start: start)
        let action = app.buttons["Join now"]
        guard action.waitForExistence(timeout: 5), action.isEnabled else {
            throw RuntimeError("Join now is not available")
        }
        app.navigationBars["Meetings"].tap()
        guard action.waitToDisappear(timeout: 5) else { throw RuntimeError("The meeting menu did not close") }
    }

    @MainActor
    func join(
        _ meeting: MeetingResponse, on page: MeetingsPage, start: Date? = nil, fromMenu: Bool = false
    ) throws -> OngoingCallPage {
        if fromMenu {
            try page.openMenu(for: meeting, start: start)
            guard app.buttons["Join now"].waitAndTap() else { throw RuntimeError("Join now did not respond") }
        } else {
            _ = try page.showRow(meeting, start: start)
            guard joinButton(meeting, on: page, start: start).waitAndTap() else {
                throw RuntimeError("Join did not respond")
            }
        }
        return try waitForCall(title: meeting.title)
    }

    @MainActor
    func waitForCall(title: String) throws -> OngoingCallPage {
        let timer = app.staticTexts[Locators.OngoingCallPage.timeLabel.rawValue]
        let permission = springboard.alerts.buttons["Allow"].firstMatch
        let pattern = "^[0-9]+:[0-5][0-9]$"
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            permission.exists || (timer.exists && timer.label.range(of: pattern, options: .regularExpression) != nil)
        }, object: nil)
        guard XCTWaiter().wait(for: [ready], timeout: 30) == .completed else {
            throw RuntimeError("The meeting call or microphone permission did not appear")
        }
        if permission.exists { permission.tap() }
        let connected = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND label MATCHES %@", pattern), object: timer
        )
        guard XCTWaiter().wait(for: [connected], timeout: 30) == .completed else {
            throw RuntimeError("The meeting call did not connect directly")
        }
        let call = try OngoingCallPage()
        call.verifyGroupNameAndTimerShowingOnceCallJoined(groupName: title)
        capture("\(title) connected")
        return call
    }

    @MainActor
    func leaveCall(_ call: OngoingCallPage) throws -> MeetingsPage {
        guard call.endCallButton.waitAndTap(), call.endCallButton.waitToDisappear(timeout: 15) else {
            throw RuntimeError("The meeting call did not end locally")
        }
        let feedback = app.buttons["score_close"]
        if feedback.waitForExistence(timeout: 2) { feedback.tap() }
        return try MeetingsPage()
    }

    func armPeer(_ id: String) async throws {
        _ = try await callingServiceClient.acceptNext(
            instanceId: id, request: CallRequest(
                conversationId: "", timeout: CallingServiceClient.Constants.callTimeoutMilliseconds
            )
        )
    }

    @MainActor
    func joinPeer(_ id: String, user: UserInfo, meeting: MeetingResponse) async throws -> String {
        do {
            _ = try await callingServiceClient.startCall(
                instanceId: id, conversationId: meeting.conversationID.id.uuidString.lowercased()
            )
            return try await assertPeer(id, user: user, meeting: meeting)
        } catch {
            let state = try? await callingServiceClient.getInstanceStatus(instanceIds: [id]).first
            let details = XCTAttachment(string: """
            Instance: \(state?.instanceStatus ?? "unknown")
            Call: \(state?.currentCall?.id ?? "none")
            Status: \(state?.currentCall?.status ?? "none")
            Conversation: \(state?.currentCall?.conversationId ?? "none")
            Expected conversation: \(meeting.conversationID.id.uuidString.lowercased())
            """)
            details.name = "Meeting peer status"
            details.lifetime = .keepAlways
            add(details)
            if let (data, response) = try? await callingServiceClient.sendHttpRequest(
                endpoint: callingServiceClient.instanceEndpoint(instanceId: id, path: "screenshot"),
                body: CallingServiceEmptyBody?.none, method: .get, contentType: nil, accept: nil
            ), response.statusCode == 200, response.mimeType == "image/png" {
                let screenshot = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
                screenshot.name = "Meeting peer screenshot"
                screenshot.lifetime = .keepAlways
                add(screenshot)
            }
            throw error
        }
    }

    func requireConferenceCalling() async throws {
        let features = try await UserHelper.default.featureConfigsAPI.getFeatureConfigs()
        guard features.contains(where: {
            guard case let .conferenceCalling(config) = $0 else { return false }
            return config.status == .enabled
        }) else { throw RuntimeError("The call test requires conference calling to be enabled") }
    }

    func callControl(_ id: String, state: String) throws -> Int32 {
        let name = "\(UITestConfig.meetingsCallControlNotificationPrefix).\(id).\(state)"
        var token: Int32 = NOTIFY_TOKEN_INVALID
        guard notify_register_check(name, &token) == NOTIFY_STATUS_OK else {
            throw RuntimeError("The Meetings call control could not be registered")
        }
        return token
    }

    func assertCallStarts(_ expected: UInt64, starts: Int32, conversation: Int32) throws {
        var count: UInt64 = 0
        guard notify_get_state(starts, &count) == NOTIFY_STATUS_OK, count == expected else {
            throw RuntimeError("Expected \(expected) native call starts, received \(count)")
        }
        if expected > 0 {
            var matches: UInt64 = 0
            guard notify_get_state(conversation, &matches) == NOTIFY_STATUS_OK, matches == 1 else {
                throw RuntimeError("The native call did not start in the meeting conversation")
            }
        }
    }

    @discardableResult
    func assertPeer(
        _ id: String,
        user: UserInfo,
        meeting: MeetingResponse,
        callID: String? = nil
    ) async throws -> String {
        try await callingManager.waitForCurrentCallStatus(instanceId: id, expectedStatuses: ["ACTIVE"], timeout: 30)
        try await callingManager.verifyPeerConnections(instanceIds: [id], expectedCount: 1, timeout: 30)
        let flows = try await callingServiceClient.getFlows(instanceId: id)
        guard flows.map({ $0.remoteUserId.lowercased() }) == [user.id.lowercased()] else {
            throw RuntimeError("The remote call did not connect to exactly the app user")
        }
        let currentCall = try await callingServiceClient.getCurrentCall(instanceId: id)
        guard currentCall.conversationId?.lowercased() == meeting.conversationID.id.uuidString.lowercased() else {
            throw RuntimeError("The remote call is not associated with the meeting conversation")
        }
        let currentID = try XCTUnwrap(currentCall.id)
        guard !currentID.isEmpty else { throw RuntimeError("The remote call has no ID") }
        if let callID, currentID != callID { throw RuntimeError("The active remote call was replaced") }
        return currentID
    }

    @MainActor
    func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
