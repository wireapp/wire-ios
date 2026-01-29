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
        let (teamOwner: teamOwner, teamMembers: teamMembers, conversationId: conversationId) = try await  userHelper
            .setupTeamWith2MembersAndGroupConversation(groupName: groupName)

        let firstTimePage = try app.loginUser(email: teamMembers[0].email, password: teamMembers[0].password)
        _ = try firstTimePage.acceptPopupOnTeamMemberSetup(with: self)
            .setUsername(teamMembers[0].username)

        // create instance
        let instance = try await callingServiceClient.createInstance(
            name: CallingTestDefaults.testName,
            userInfo: teamOwner,
            backend: CallingTestDefaults.backend,
            beta: CallingTestDefaults.isBeta,
            instanceTypeName: CallingTestDefaults.instanceTypeName,
            instanceTypeVersion: CallingTestDefaults.instanceTypeVersion
        )
        XCTAssertNotNil(instance.id)

        // start group call
        let instanceId = instance.id ?? ""
        try await callingServiceClient.startCall(
            instanceId: instanceId,
            conversationId: conversationId.uuidString.lowercased()
        )
        
        print()
        // button with label Accept
    }
}
