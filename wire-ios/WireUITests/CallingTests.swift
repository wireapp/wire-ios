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

final class CallingTests: WireUITestCase {

    struct GroupCallSetupResponse {
        let conversationId: String
        let groupName: String
        let allParticipants: [UserInfo]
        let appCallee: UserInfo
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
            appCallee: appUserWhoWillJoinTheCall,
            callingServiceUsers: callingServiceUsers
        )
    }

    private func loginAndDismissFirstTimePopup(user: UserInfo) throws {
        let firstTimePage = try app.loginUser(email: user.email, password: user.password)
        _ = try firstTimePage.acceptPopup(with: self)
    }

    private func createCallingServiceInstances(users: [UserInfo]) async throws -> [CallingServiceInstance] {
        try await callingServiceClient.createInstances(
            users: users,
            backend: CallingTestDefaults.backend,
            beta: CallingTestDefaults.isBeta,
            instanceTypeName: CallingTestDefaults.instanceTypeName,
            instanceTypeVersion: CallingTestDefaults.instanceTypeVersion
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

    private func verifyParticipantsVisible(_ participants: [UserInfo]) {
        for user in participants {
            let participantIdentifier = Locators.OngoingCallView.participantIdentifier(user.name)
            XCTAssertTrue(
                app.buttons[participantIdentifier].waitForExistence(timeout: 15),
                "Expected \(user.name) to be in the call"
            )
        }
    }

    /// Testiny : https://app.testiny.io/IOS/testcases/tc/8801
    /// Team Owner create group conversation and initiate a group call with members
    @MainActor
    func test_MultipleUsersJoiningGroupCall() async throws {

        let teamAndGroupCallSetup = try await makeTeamAndGroupCallSetup(memberCount: 5)

        try loginAndDismissFirstTimePopup(user: teamAndGroupCallSetup.appCallee)

        let instances = try await createCallingServiceInstances(users: teamAndGroupCallSetup.callingServiceUsers)

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
        verifyParticipantsVisible(teamAndGroupCallSetup.allParticipants)

        _ = try ongoingCallPage.endOngoingCall()
    }
}
