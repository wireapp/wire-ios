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

/// Prefixed 'Z' in the class name to run these tests at the end, just to avoid if this test may impact others due to alert keep showing
final class ZCallingTests: WireUITestCase {

    struct GroupCallSetupResponse {
        let conversationId: String
        let groupName: String
        let allParticipants: [UserInfo]
        let appUserWhoWillJoinTheCall: UserInfo
        let callingServiceUsers: [UserInfo]
    }

    private func makeTeamAndGroupCallSetup(
        memberCount: Int,
        groupName: String? = nil
    ) async throws -> GroupCallSetupResponse {
        let groupName = groupName ?? UserGenerator.generateRandomGroupName()

        let (teamOwner, teamMembers, _, conversationId) = try await userHelper
            .registerTeam(
                withMemberCount: memberCount,
                groupName: groupName
            )

        let convId = try XCTUnwrap(conversationId, "conversationId is nil").uuidString.lowercased()

        let allParticipants = [teamOwner] + teamMembers
        let appUserWhoWillJoinTheCall = try XCTUnwrap(teamMembers.last)

        let callingServiceAcceptingMembers = Array(teamMembers.dropLast(1))
        let callingServiceUsers = [teamOwner] + callingServiceAcceptingMembers

        return GroupCallSetupResponse(
            conversationId: convId,
            groupName: groupName,
            allParticipants: allParticipants,
            appUserWhoWillJoinTheCall: appUserWhoWillJoinTheCall,
            callingServiceUsers: callingServiceUsers
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

        let ongoingCallPage = try incomingCallPage.acceptIncommingCall(with: self)
        XCTAssertTrue(app.staticTexts[groupName].waitForExistence(timeout: 10), "Conversation title mismatch")

        return ongoingCallPage
    }

    /// Testiny : https://app.testiny.io/IOS/testcases/tc/8801
    /// Team Owner create group conversation and initiate a group call with members
    @MainActor
    func test_MultipleUsersJoiningGroupCall() async throws {

        let teamAndGroupCallSetup = try await makeTeamAndGroupCallSetup(memberCount: 3)

        let firstTimePage = try app.loginUser(
            email: teamAndGroupCallSetup.appUserWhoWillJoinTheCall.email,
            password: teamAndGroupCallSetup.appUserWhoWillJoinTheCall.password
        )
        _ = try firstTimePage.acceptPopup(with: self)

        let instances: [CallingServiceInstance]
        do {
            instances = try await createCallingServiceInstances(users: teamAndGroupCallSetup.callingServiceUsers)

            let ownerInstanceId = try requireOwnerInstanceId(from: instances)

            _ = try await callingServiceClient.startCall(
                instanceId: ownerInstanceId,
                conversationId: teamAndGroupCallSetup.conversationId
            )

            let acceptingIds = instances.dropFirst().compactMap(\.id).filter { !$0.isEmpty }
            let responses = try await callingServiceClient.acceptNextCalls(
                instanceIds: acceptingIds,
                conversationId: teamAndGroupCallSetup.conversationId
            )
            XCTAssertEqual(responses.count, acceptingIds.count)

            let ongoingCallPage = try acceptIncomingCall(groupName: teamAndGroupCallSetup.groupName)

            let participantIdentifier = Locators.OngoingCallPage
                .participantIdentifier(teamAndGroupCallSetup.appUserWhoWillJoinTheCall.name)

            XCTAssertTrue(
                app.buttons[participantIdentifier].waitForExistence(timeout: 15),
                "Expected \(teamAndGroupCallSetup.appUserWhoWillJoinTheCall.name) to be in the call OR took more than 15 seconds to join"
            )

            let conversationsPage = try ongoingCallPage.endOngoingCall()
            XCTAssertTrue(
                conversationsPage.conversationCell.exists,
                "Conversation List is not showing after ending the call"
            )
        } catch {
            throw XCTSkip("⚠️ Calling service failed..Skipping this test")
        }
    }
}
