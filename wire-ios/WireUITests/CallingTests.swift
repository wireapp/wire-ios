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
import XCTest

final class CallingTests: WireUITestCase {

    /// Testiny : https://app.testiny.io/IOS/testcases/tc/8801
    @MainActor
    func test_MultipleUsersJoiningGroupCall() async throws {

        let groupName = UserGenerator.generateRandomGroupName()

        let (teamOwner, teamMembers, _, conversationId) = try await userHelper
            .registerTeamWithXMembersAndOptionalGroupConversation(
                memberCount: 5,
                groupName: groupName
            )
        guard let conversationId else {
            XCTFail("conversationId is nil")
            return
        }

        let convId = conversationId.uuidString.lowercased()
        let allParticipants = [teamOwner] + teamMembers
        let appCallee = teamMembers.last!
        let callingServiceAcceptingMembers = Array(teamMembers.dropLast(1))
        let allParticipantInstanceUsers = [teamOwner] + callingServiceAcceptingMembers

        let firstTimePage = try app.loginUser(email: appCallee.email, password: appCallee.password)
        _ = try firstTimePage.acceptPopup(with: self)

        let instances = try await callingServiceClient.createInstances(
            users: allParticipantInstanceUsers,
            backend: CallingTestDefaults.backend,
            beta: CallingTestDefaults.isBeta,
            instanceTypeName: CallingTestDefaults.instanceTypeName,
            instanceTypeVersion: CallingTestDefaults.instanceTypeVersion
        )

        guard let ownerAsCallerInstanceId = instances.first?.id, !ownerAsCallerInstanceId.isEmpty else {
            XCTFail("Owner instanceId is nil")
            return
        }

        _ = try await callingServiceClient.startCall(
            instanceId: ownerAsCallerInstanceId,
            conversationId: convId
        )

        let acceptingCalleeMembersInstanceIds = instances.dropFirst().compactMap(\.id).filter { !$0.isEmpty }

        let responsesByInstanceId = try await callingServiceClient.acceptNextCalls(
            instanceIds: acceptingCalleeMembersInstanceIds,
            conversationId: convId
        )

        XCTAssertEqual(responsesByInstanceId.count, acceptingCalleeMembersInstanceIds.count)

        let incomingCallPage = try IncomingCallPage()
        XCTAssertTrue(incomingCallPage.acceptButton.exists, "Expected call not received")

        let ongoingCallPage = try incomingCallPage.acceptIncommingCall()

        XCTAssertTrue(app.staticTexts[groupName].waitForExistence(timeout: 10), "Conversation title mismatch")

        for user in allParticipants {
            let participantIdentifier = "audioView.\(user.name).minimized.inactive"
            let participantTile = app.buttons[participantIdentifier]

            XCTAssertTrue(
                participantTile.waitForExistence(timeout: 15),
                "Expected \(user.name) to be in the call"
            )
        }
        _ = try ongoingCallPage.endOngoingCall()
    }
}
