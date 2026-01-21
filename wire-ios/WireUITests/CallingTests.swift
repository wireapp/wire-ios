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

    @MainActor
    func test_CallingInGroupConversation() async throws {

        let groupName = UserGenerator.generateRandomGroupName()
        let (_, teamOwner) = try await userHelper.registerUserAsTeamOwner()
        let ownerAccessToken = try await userHelper.fetchAccessToken(
            email: teamOwner.email,
            password: teamOwner.password
        )

        let countOfMembers = 2

        var qualifiedIds: [QualifiedID] = []
        var teamMembers: [UserInfo] = []

        for _ in 0 ..< countOfMembers {
            let (qualifiedId, teamMember) = try await userHelper.registerUsersAsTeamMember(
                ownerAccessToken: ownerAccessToken.token,
                teamID: teamOwner.teamID!
            )
            qualifiedIds.append(qualifiedId)
            teamMembers.append(teamMember)
        }

        try await userHelper.createGroupConversations(
            qualifiedIds: qualifiedIds,
            owner: teamOwner,
            groupName: groupName
        )
        let (conversationId, _) = try await userHelper.getConversationId(matching: .groupName(groupName))
        guard let conversationId else {
            XCTFail("Failed to resolve conversationId for group \(groupName)")
            return
        }

        let conversationDetailsPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup(with: self)

//        try await userHelper.disableConsentPopup(for: teamMembers[0])

        do {
            let instance = try await callingServiceClient.createInstance(
                name: "Test",
                userInfo: teamMembers[0],
                backend: "MASTER",
                beta: true,
                instanceTypeName: "chrome",
                instanceTypeVersion: "103.0.5060.53"
            )
            XCTAssertNotNil(instance.id)
            let instanceId = instance.id ?? ""
            try await callingServiceClient.startCall(
                instanceId: instanceId,
                conversationId: conversationId.uuidString,
                timeoutMillis: 3_600_000
            )

        } catch {
            XCTFail("CallingService flow failed: \(error)")
            throw error
        }
    }
}
