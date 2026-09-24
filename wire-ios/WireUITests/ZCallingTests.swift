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
import XCTest

/// Prefixed 'Z' in the class name to run these tests at the end, just to avoid if this test may impact others due to
/// alert keep showing
/// [calling]
final class ZCallingTests: WireUITestCase {

    struct GroupCallScenario {
        let conversationId: String
        let groupName: String
        let teamOwner: UserInfo
        let appUserReceivingCall: UserInfo
        let callingServiceUsers: [UserInfo]
    }

    private func makeTeamAndGroupCallSetup(
        memberCount: Int,
        groupName: String? = nil,
        preferredNames: [String] = []
    ) async throws -> GroupCallScenario {
        let groupName = groupName ?? UserGenerator.generateRandomConversationName()

        let (teamOwner, teamMembers, _, conversationId) = try await UserHelper.default
            .registerTeam(
                withMemberCount: memberCount,
                conversation: .group(groupName),
                names: preferredNames
            )

        let convId = try XCTUnwrap(conversationId, "conversationId is nil").uuidString.lowercased()

        let appUserReceivingCall = try XCTUnwrap(teamMembers.last)
        let callingServiceUsers = [teamOwner] + teamMembers.dropLast()

        return GroupCallScenario(
            conversationId: convId,
            groupName: groupName,
            teamOwner: teamOwner,
            appUserReceivingCall: appUserReceivingCall,
            callingServiceUsers: Array(callingServiceUsers)
        )
    }

    private func createCallingServiceInstances(users: [UserInfo]) async throws -> [CallingServiceInstance] {
        let envVariables = try EnvironmentVariables()

        return try await callingServiceClient.createInstances(
            users: users,
            backend: envVariables.callingBackend,
            beta: true,
            instanceTypeName: envVariables.callingInstanceTypeName,
            instanceTypeVersion: envVariables.callingInstanceTypeVersion
        )
    }

    private func requireOwnerInstanceId(from instances: [CallingServiceInstance]) throws -> String {
        let ownerId = try XCTUnwrap(instances.first?.id, "Owner instanceId is nil")
        XCTAssertFalse(ownerId.isEmpty, "Owner instanceId is empty")
        return ownerId
    }

    private func sortedByName(_ users: [UserInfo]) -> [UserInfo] {
        users.sorted { firstUser, secondUser in
            firstUser.name.localizedCaseInsensitiveCompare(secondUser.name) == .orderedAscending
        }
    }

    private func acceptIncomingCall(groupName: String) throws -> OngoingCallPage {
        let incomingCallPage = try IncomingCallPage()
        XCTAssertTrue(incomingCallPage.acceptButton.exists, "Expected call not received")

        let ongoingCallPage = try incomingCallPage.acceptIncommingCall()
        let conversationTitle = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", groupName)
        ).firstMatch
        XCTAssertTrue(conversationTitle.waitForExistence(timeout: 10), "Conversation title mismatch")

        return ongoingCallPage
    }

    private func tapIncomingCallNotification(conversationName: String) {
        let incomingCallPredicate = NSPredicate(
            format: "label CONTAINS[c] %@ OR value CONTAINS[c] %@",
            conversationName,
            conversationName
        )
        let springboardNotification = springboard.descendants(matching: .any)
            .matching(incomingCallPredicate)
            .firstMatch

        if springboardNotification.waitAndTap(timeout: 15) {
            return
        }

        let appNotification = app.descendants(matching: .any)
            .matching(incomingCallPredicate)
            .firstMatch

        XCTAssertTrue(
            appNotification.waitAndTap(timeout: 3),
            "Incoming call notification did not appear"
        )
    }

    private func verifyOngoingCallBannerAndResume(
        ongoingCallPage: OngoingCallPage,
        conversationName: String
    ) throws -> OngoingCallPage {
        XCTAssertTrue(ongoingCallPage.timeLabel.waitForExistence(timeout: 10), "Call timer did not appear")

        let activeConversationPage = try ongoingCallPage.minimizeCallUI()

        XCTAssertTrue(
            activeConversationPage.openOngoingCallButton.waitForExistence(timeout: 5),
            "Ongoing call banner did not appear"
        )
        XCTAssertTrue(
            activeConversationPage.conversationTitleButton.label.contains(conversationName),
            "Account did not switch to the expected call conversation"
        )

        return try activeConversationPage.resumeCallUI()
    }

    /// Team Owner creates group conversation and initiates a group call with members via calling service
    /// [critical]
    @MainActor
    func testMultipleUsersJoiningGroupCall_TC_8910_8880() async throws {

        let teamAndGroupCallSetup = try await makeTeamAndGroupCallSetup(memberCount: 3)

        let firstTimePage = try app.loginUser(
            email: teamAndGroupCallSetup.appUserReceivingCall.email,
            password: teamAndGroupCallSetup.appUserReceivingCall.password
        )
        _ = try firstTimePage.acceptPopup()

        let instances: [CallingServiceInstance]

        instances = try await createCallingServiceInstances(users: teamAndGroupCallSetup.callingServiceUsers)

        let ownerInstanceId = try requireOwnerInstanceId(from: instances)

        _ = try await callingServiceClient.startCall(
            instanceId: ownerInstanceId,
            conversationId: teamAndGroupCallSetup.conversationId
        )

        let acceptingIds = instances.dropFirst().compactMap(\.id).filter { !$0.isEmpty }
        let responses = try await callingManager.acceptNextCalls(
            instanceIds: acceptingIds,
            conversationId: teamAndGroupCallSetup.conversationId
        )
        XCTAssertEqual(responses.count, acceptingIds.count)

        let ongoingCallPage = try acceptIncomingCall(groupName: teamAndGroupCallSetup.groupName)

        XCTAssertTrue(
            ongoingCallPage.participant(named: teamAndGroupCallSetup.appUserReceivingCall.name)
                .waitForExistence(timeout: 15),
            "Expected \(teamAndGroupCallSetup.appUserReceivingCall.name) to be in the call OR took more than 15 seconds to join"
        )

        let conversationsPage = try ongoingCallPage.endOngoingCall()
        XCTAssertTrue(
            conversationsPage.conversationCell.exists,
            "Conversation List is not showing after ending the call"
        )
    }

    @MainActor
    func testGroupCallParticipantNameOrInitialsVisible_TC_8887() async throws {
        // GIVEN

        let teamAndGroupCallSetup = try await makeTeamAndGroupCallSetup(memberCount: 2)

        let firstTimePage = try app.loginUser(
            email: teamAndGroupCallSetup.appUserReceivingCall.email,
            password: teamAndGroupCallSetup.appUserReceivingCall.password
        )
        _ = try firstTimePage.acceptPopup()

        let instances = try await createCallingServiceInstances(users: teamAndGroupCallSetup.callingServiceUsers)
        let ownerInstanceId = try requireOwnerInstanceId(from: instances)

        // WHEN
        _ = try await callingServiceClient.startCall(
            instanceId: ownerInstanceId,
            conversationId: teamAndGroupCallSetup.conversationId
        )

        let acceptingIds = instances.dropFirst().compactMap(\.id).filter { !$0.isEmpty }
        if !acceptingIds.isEmpty {
            _ = try await callingManager.acceptNextCalls(
                instanceIds: acceptingIds,
                conversationId: teamAndGroupCallSetup.conversationId
            )
        }

        let ongoingCallPage = try acceptIncomingCall(groupName: teamAndGroupCallSetup.groupName)

        // THEN
        for participant in teamAndGroupCallSetup.callingServiceUsers {
            XCTAssertTrue(
                ongoingCallPage.participant(named: participant.name).waitForExistence(timeout: 15),
                "Expected participant \(participant.name) to be visible in the call"
            )
        }

        _ = try ongoingCallPage.endOngoingCall()
    }

    @MainActor
    func testGroupCallToggleMicrophoneCameraAndSpeaker_TC_8881_8882_8883() async throws {
        // GIVEN
        let teamAndGroupCallSetup = try await makeTeamAndGroupCallSetup(memberCount: 1)

        let firstTimePage = try app.loginUser(
            email: teamAndGroupCallSetup.teamOwner.email,
            password: teamAndGroupCallSetup.teamOwner.password
        )

        // WHEN
        let ongoingCallPage = try firstTimePage.acceptPopup()
            .openConversation()
            .initiateCall()

        // THEN
        XCTAssertEqual(
            ongoingCallPage.microphoneButton.label,
            "Turn off microphone",
            "Microphone button should be visible and ON when the call starts"
        )

        XCTAssertEqual(
            ongoingCallPage.cameraButton.label,
            "Turn on camera",
            "Camera button should be visible and OFF when the call starts"
        )

        XCTAssertEqual(
            ongoingCallPage.speakerButton.label,
            "Turn on speaker",
            "Speaker button should be visible and OFF when the call starts"
        )

        ongoingCallPage
            .verifyMicrophoneToggle()
            .verifyCameraToggle()
            .verifySpeakerToggle()
    }

    @MainActor
    func testGroupCallInitiateMinimizeMaximizeAndHangUp_TC_8879_8889_8890_8885_8909() async throws {
        // GIVEN
        let teamAndGroupCallSetup = try await makeTeamAndGroupCallSetup(memberCount: 1)

        let firstTimePage = try app.loginUser(
            email: teamAndGroupCallSetup.teamOwner.email,
            password: teamAndGroupCallSetup.teamOwner.password
        )

        // WHEN
        let ongoingCallPage = try await firstTimePage.acceptPopup()
            .openConversation()
            .initiateCall()
            .minimizeCallUI()
            .backgroundAndResume(app: app, forDelay: 2)
            .resumeCallUI()

        // THEN
        let activeConversationPage = try ongoingCallPage.hangUpOngoingCall()
        XCTAssertTrue(
            activeConversationPage.openOngoingCallButton.waitForNonExistence(timeout: 4),
            "Ongoing call still visible after hanging up the call"
        )
    }

    /// Call participant switches from audio call to video call and back
    /// [critical]
    @MainActor
    func testSwitchBetweenAudioAndVideoCallAndShowsParticipantVideo_TC_8888_9497() async throws {

        let teamAndGroupCallSetup = try await makeTeamAndGroupCallSetup(memberCount: 1)

        let firstTimePage = try app.loginUser(
            email: teamAndGroupCallSetup.appUserReceivingCall.email,
            password: teamAndGroupCallSetup.appUserReceivingCall.password
        )
        let conversationsPage = try firstTimePage.acceptPopup()

        let instances = try await createCallingServiceInstances(users: teamAndGroupCallSetup.callingServiceUsers)
        let acceptingIds = instances.compactMap(\.id).filter { !$0.isEmpty }
        XCTAssertEqual(acceptingIds.count, teamAndGroupCallSetup.callingServiceUsers.count)

        async let acceptingResponses = callingManager.acceptNextCalls(
            instanceIds: acceptingIds,
            conversationId: teamAndGroupCallSetup.conversationId
        )

        let ongoingCallPage = try conversationsPage
            .openConversation()
            .initiateCall()

        let responses = try await acceptingResponses
        XCTAssertEqual(responses.count, acceptingIds.count)

        for instanceId in acceptingIds {
            try await callingManager.waitForCurrentCallStatus(
                instanceId: instanceId,
                expectedStatuses: ["ACTIVE"],
                timeout: 30
            )
        }

        try await callingManager.verifyPeerConnections(
            instanceIds: acceptingIds,
            expectedCount: 1,
            timeout: 30
        )

        try ongoingCallPage.turnOnVideo()

        for instanceId in acceptingIds {
            try await callingManager.switchVideoOn(instanceId: instanceId)
        }

        try await callingManager.verifyPeerConnections(
            instanceIds: acceptingIds,
            expectedCount: 1,
            timeout: 30
        )

        XCTAssertTrue(
            ongoingCallPage.turnOffCameraButton.waitForExistence(timeout: 10),
            "Camera did not switch on"
        )

        for callingServiceUser in teamAndGroupCallSetup.callingServiceUsers {
            _ = ongoingCallPage.isOtherParticipantVideoTileVisible(for: callingServiceUser.name)
        }

        try ongoingCallPage.turnOffVideo()
        XCTAssertTrue(
            ongoingCallPage.turnOnCameraButton.waitForExistence(timeout: 10),
            "Camera did not switch off"
        )
    }

    /// [critical]
    @MainActor
    func testParticipantCanSeeSharedScreen_TC_8891() async throws {
        // GIVEN
        let teamAndGroupCallSetup = try await makeTeamAndGroupCallSetup(memberCount: 1)

        let firstTimePage = try app.loginUser(
            email: teamAndGroupCallSetup.appUserReceivingCall.email,
            password: teamAndGroupCallSetup.appUserReceivingCall.password
        )
        _ = try firstTimePage.acceptPopup()

        let instances = try await createCallingServiceInstances(users: teamAndGroupCallSetup.callingServiceUsers)
        let ownerInstanceId = try requireOwnerInstanceId(from: instances)

        // WHEN
        _ = try await callingServiceClient.startCall(
            instanceId: ownerInstanceId,
            conversationId: teamAndGroupCallSetup.conversationId
        )

        let ongoingCallPage = try acceptIncomingCall(groupName: teamAndGroupCallSetup.groupName)
        try await callingManager.waitForCurrentCallStatus(
            instanceId: ownerInstanceId,
            expectedStatuses: ["ACTIVE"],
            timeout: 30
        )
        _ = try await callingManager.switchScreenSharingOn(instanceId: ownerInstanceId)

        // THEN
        ongoingCallPage
            .isOtherParticipantScreenSharingVisible(for: teamAndGroupCallSetup.teamOwner.name)
            .verifyScreenSharingQRCodes(
                for: teamAndGroupCallSetup.teamOwner.name,
                // Calling service screen-share test image uses the same QR marker payloads as zautomation.
                expectedContentInQRCode: [
                    "http://screen-right",
                    "http://screen-bottom"
                ]
            )
    }

    @MainActor
    func testJoinCallForInactiveAndActiveAccountWhenAppInForeground_TC_8900_8897() async throws {
        // GIVEN
        let user1InactiveAccountSetup = try await makeTeamAndGroupCallSetup(
            memberCount: 1,
            groupName: "InactiveUserGroup"
        )
        let user2ActiveAccountSetup = try await makeTeamAndGroupCallSetup(
            memberCount: 1,
            groupName: "ActiveUserGroup"
        )

        _ = try app.loginUser(
            email: user1InactiveAccountSetup.appUserReceivingCall.email,
            password: user1InactiveAccountSetup.appUserReceivingCall.password
        )
        .acceptPopup()
        .openUserProfilePage()
        .tapAddAccountOrTeamButton()

        _ = try app.loginUser(
            email: user2ActiveAccountSetup.appUserReceivingCall.email,
            password: user2ActiveAccountSetup.appUserReceivingCall.password
        )
        .acceptPopup()

        let user1InactiveOwnerInstances = try await createCallingServiceInstances(
            users: [user1InactiveAccountSetup.teamOwner]
        )
        let user1InactiveOwnerInstanceId = try requireOwnerInstanceId(from: user1InactiveOwnerInstances)

        // WHEN - inactive account receives a call while app is in foreground.
        _ = try await callingServiceClient.startCall(
            instanceId: user1InactiveOwnerInstanceId,
            conversationId: user1InactiveAccountSetup.conversationId
        )

        // Tapping the incoming call notification switches from active account to inactive account while joining the
        // call.
        tapIncomingCallNotification(conversationName: user1InactiveAccountSetup.groupName)
        let ongoingCallPage = try acceptIncomingCall(groupName: user1InactiveAccountSetup.groupName)

        // THEN
        XCTAssertTrue(ongoingCallPage.timeLabel.waitForExistence(timeout: 10), "Call timer did not appear")

        ongoingCallPage.endCallButton.tapAndWait()
        XCTAssertTrue(ongoingCallPage.timeLabel.waitForNonExistence(timeout: 5), "Call timer still visible")
        try await callingManager.stopCurrentCall(instanceId: user1InactiveOwnerInstanceId)

        // WHEN - same account receives a call while active and app is in foreground.
        _ = try await callingServiceClient.startCall(
            instanceId: user1InactiveOwnerInstanceId,
            conversationId: user1InactiveAccountSetup.conversationId
        )

        let activeAccountOngoingCallPage = try acceptIncomingCall(groupName: user1InactiveAccountSetup.groupName)

        // THEN
        XCTAssertTrue(activeAccountOngoingCallPage.timeLabel.waitForExistence(timeout: 10), "Call timer did not appear")
    }

    @MainActor
    func testUserCanDeclineAndRejoinOngoingGroupCall_TC_9493_9503_8886() async throws {
        // GIVEN
        let teamAndGroupCallSetup = try await makeTeamAndGroupCallSetup(memberCount: 1)

        let firstTimePage = try app.loginUser(
            email: teamAndGroupCallSetup.appUserReceivingCall.email,
            password: teamAndGroupCallSetup.appUserReceivingCall.password
        )
        _ = try firstTimePage.acceptPopup()

        let instances = try await createCallingServiceInstances(users: teamAndGroupCallSetup.callingServiceUsers)
        let ownerInstanceId = try requireOwnerInstanceId(from: instances)

        // WHEN
        _ = try await callingServiceClient.startCall(
            instanceId: ownerInstanceId,
            conversationId: teamAndGroupCallSetup.conversationId
        )

        let incomingCallPage = try IncomingCallPage()
        XCTAssertTrue(incomingCallPage.declineButton.exists, "Decline button did not show up")

        // THEN
        let conversationsPage = try incomingCallPage.declineIncomingCall()
        XCTAssertTrue(
            conversationsPage.joinCallButton.waitForExistence(timeout: 10),
            "Join call button did not show up after declining the call"
        )

        // WHEN
        let joinedCallPage = try conversationsPage.joinOngoingCall(groupName: teamAndGroupCallSetup.groupName)

        // THEN
        joinedCallPage.verifyGroupNameAndTimerShowingOnceCallJoined(
            groupName: teamAndGroupCallSetup.groupName
        )

        let conversationListPage = try joinedCallPage.endOngoingCall()

        // WHEN
        let rejoinedCallPage = try conversationListPage.joinOngoingCall(groupName: teamAndGroupCallSetup.groupName)

        // THEN
        rejoinedCallPage.verifyGroupNameAndTimerShowingOnceCallJoined(
            groupName: teamAndGroupCallSetup.groupName
        )
    }

    @MainActor
    func testCallParticipantTilesShownInAlphabeticalOrder_TC_9462() async throws {
        // GIVEN
        let teamAndGroupCallSetup = try await makeTeamAndGroupCallSetup(
            memberCount: 3,
            preferredNames: ["A", "B", "C", "D"]
        )

        let firstTimePage = try app.loginUser(
            email: teamAndGroupCallSetup.appUserReceivingCall.email,
            password: teamAndGroupCallSetup.appUserReceivingCall.password
        )
        _ = try firstTimePage.acceptPopup()

        let instances = try await createCallingServiceInstances(users: teamAndGroupCallSetup.callingServiceUsers)
        let ownerInstanceId = try requireOwnerInstanceId(from: instances)

        // WHEN
        _ = try await callingServiceClient.startCall(
            instanceId: ownerInstanceId,
            conversationId: teamAndGroupCallSetup.conversationId
        )

        let acceptingIds = instances.dropFirst().compactMap(\.id).filter { !$0.isEmpty }
        let responses = try await callingManager.acceptNextCalls(
            instanceIds: acceptingIds,
            conversationId: teamAndGroupCallSetup.conversationId
        )
        XCTAssertEqual(responses.count, acceptingIds.count)

        let ongoingCallPage = try acceptIncomingCall(groupName: teamAndGroupCallSetup.groupName)

        // THEN
        // Self user should be shown first, then other participants should be shown in alphabetical order.
        let expectedAudioOrder = [teamAndGroupCallSetup.appUserReceivingCall.name] +
            sortedByName(teamAndGroupCallSetup.callingServiceUsers).map(\.name)
        ongoingCallPage.verifyParticipantsShownInOrder(expectedAudioOrder)

        let videoFirstUser = try XCTUnwrap(sortedByName(teamAndGroupCallSetup.callingServiceUsers).last)
        let videoFirstUserIndex = try XCTUnwrap(
            teamAndGroupCallSetup.callingServiceUsers.firstIndex { $0 === videoFirstUser }
        )
        let videoFirstInstanceId = instances[videoFirstUserIndex].id
        try await callingManager.waitForCurrentCallStatus(
            instanceId: videoFirstInstanceId,
            expectedStatuses: ["ACTIVE"],
            timeout: 30
        )
        // WHEN - switched video on
        try await callingManager.switchVideoOn(instanceId: videoFirstInstanceId)
        XCTAssertTrue(
            ongoingCallPage.videoView(for: videoFirstUser.name).waitForExistence(timeout: 20),
            "Video tile did not appear for \(videoFirstUser.name)"
        )

        // When a participant enables video, self user stays first, video participant shows next,
        // and remaining participants stay in alphabetical order.
        let expectedVideoOrder = [
            teamAndGroupCallSetup.appUserReceivingCall.name,
            videoFirstUser.name
        ] + sortedByName(teamAndGroupCallSetup.callingServiceUsers.filter { $0.email != videoFirstUser.email })
            .map(\.name)

        // THEN
        ongoingCallPage.verifyParticipantsShownInOrder(expectedVideoOrder)
    }
}
