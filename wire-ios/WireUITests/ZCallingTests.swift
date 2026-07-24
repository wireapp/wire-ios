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
        groupName: String? = nil
    ) async throws -> GroupCallScenario {
        let groupName = groupName ?? UserGenerator.generateRandomConversationName()

        let (teamOwner, teamMembers, _, conversationId) = try await UserHelper.default
            .registerTeam(
                withMemberCount: memberCount,
                conversation: .group(groupName)
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

    private func acceptIncomingCall(groupName: String) throws -> OngoingCallPage {
        let incomingCallPage = try IncomingCallPage()
        XCTAssertTrue(incomingCallPage.acceptButton.exists, "Expected call not received")

        let ongoingCallPage = try incomingCallPage.acceptIncommingCall()
        XCTAssertTrue(app.staticTexts[groupName].waitForExistence(timeout: 10), "Conversation title mismatch")

        return ongoingCallPage
    }

    /// Team Owner creates group conversation and initiates a group call with members via calling service
    /// [critical]
    @MainActor
    func testMultipleUsersJoiningGroupCall_TC_8910_TC_8880() async throws {

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
    func testSwitchBetweenAudioAndVideoCallAndShowsParticipantVideo_TC_8888_TC_9497() async throws {

        let teamAndGroupCallSetup = try await makeTeamAndGroupCallSetup(memberCount: 2)

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
            try await callingManager.waitForCurrentCall(
                instanceId: instanceId,
                timeout: 10
            )
        }

        try ongoingCallPage.turnOnVideo()

        for instanceId in acceptingIds {
            _ = try await callingManager.switchVideoOn(instanceId: instanceId)
        }

        XCTAssertTrue(
            ongoingCallPage.turnOffCameraButton.waitForExistence(timeout: 10),
            "Camera did not switch on"
        )

        for callingServiceUser in teamAndGroupCallSetup.callingServiceUsers {
            ongoingCallPage.isOtherParticipantVideoTileVisible(for: callingServiceUser.name)
        }

        try await callingManager.verifyReceiveAudioAndVideo(instanceIds: acceptingIds)

        try ongoingCallPage.turnOffVideo()
        XCTAssertTrue(
            ongoingCallPage.turnOnCameraButton.waitForExistence(timeout: 10),
            "Camera did not switch off"
        )
    }

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
        try await callingManager.waitForCurrentCall(instanceId: ownerInstanceId, timeout: 10)
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
}
