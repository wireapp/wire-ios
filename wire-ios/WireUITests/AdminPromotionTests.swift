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

import WireUtilities
import XCTest

class AdminPromotionTests: WireUITestCase {

    override func additionalDeveloperFlags() -> [DeveloperFlag: Bool] {
        [.preventAdminlessGroups: true]
    }

    @MainActor
    func testLastAdmin_promotesNewAdmin_andLeavesGroup_TC_11008() async throws {
        let groupName = UserGenerator.generateRandomConversationName()

        let (owner, teamMembers, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 1,
            conversation: .group(groupName)
        )
        let member = try XCTUnwrap(teamMembers.first)

        let conversationDetailsPage = try app.loginUser(email: owner.email, password: owner.password)
            .acceptPopup()
            .openConversation()
            .openConversationDetails()
            .moreOptionsConversationDetails()
            .leaveOptionsConversationDetails()
            .tapPromoteNewAdmin()
            .selectUser(named: member.name)
            .tapPromote()

        // Member is now in the admin section
        XCTAssertTrue(
            conversationDetailsPage.adminCell(named: member.name).waitForExistence(timeout: 5),
            "Promoted member should appear in the admin section"
        )

        // Self user is no longer a participant
        XCTAssertFalse(
            conversationDetailsPage.userCell(named: owner.name).exists,
            "Owner should not appear in participant list after leaving"
        )

        // Active conversation shows "you left" and input is disabled
        let activeConversationPage = try conversationDetailsPage.closeConversationDetails()

        XCTAssertTrue(
            activeConversationPage.userLeftSystemMessage.waitForExistence(timeout: 5),
            "Expected 'you left' system message"
        )
        XCTAssertFalse(
            activeConversationPage.inputMessageField.exists,
            "Input bar should not be available after leaving"
        )
    }
}
