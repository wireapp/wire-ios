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
import WireUtilities
import XCTest

class AdminPromotionTests: WireUITestCase {

    override func additionalDeveloperFlags() -> [DeveloperFlag: Bool] {
        [.preventAdminlessGroups: true]
    }

    @MainActor
    func testLastAdmin_promotesNewAdmin_andLeavesGroup_TC_11032() async throws {
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
        XCTAssertTrue(
            conversationDetailsPage.userCell(named: owner.name).waitForNonExistence(timeout: 0.5),
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

    @MainActor
    func testLastAdmin_deletesGroup_insteadOfPromoting_TC_11033() async throws {
        let groupName = UserGenerator.generateRandomConversationName()

        let (owner, _, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 1,
            conversation: .group(groupName)
        )

        let conversationsPage = try app.loginUser(email: owner.email, password: owner.password)
            .acceptPopup()
            .openConversation()
            .openConversationDetails()
            .moreOptionsConversationDetails()
            .leaveOptionsConversationDetails()
            .tapDeleteConversationAndConfirm()

        // We go back to the conversations list
        XCTAssertTrue(
            conversationsPage.conversationsButton.waitForExistence(timeout: 5),
            "Expected to get back to conversations list"
        )

        // The conversation has been deleted
        XCTAssertTrue(
            conversationsPage.conversationCell(named: groupName).waitForNonExistence(timeout: 0.5),
            "Conversation should be deleted"
        )
    }

    @MainActor
    func testLastAdmin_onlySeesDeleteGroupOption_whenNoEligibleMembers_TC_11034() async throws {
        let groupName = UserGenerator.generateRandomConversationName()

        let (owner, _, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 0,
            conversation: .group(groupName)
        )

        let conversationDetailsPage = try app.loginUser(email: owner.email, password: owner.password)
            .acceptPopup()
            .openConversation()
            .openConversationDetails()
            .moreOptionsConversationDetails()
            .leaveOptionsConversationDetails()

        // We only see the delete button
        XCTAssertTrue(
            conversationDetailsPage.deleteConversationButton.waitForExistence(timeout: 5),
            "Expected to see the delete button"
        )
        XCTAssertFalse(
            conversationDetailsPage.promoteNewAdminButton.exists,
            "Should not see the promote button"
        )
    }

    @MainActor
    func testAdmin_notLastAdmin_leavesGroupWithoutAdminSelectionModal_TC_11031() async throws {
        let groupName = UserGenerator.generateRandomConversationName()

        let (owner, teamMembers, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 2,
            conversation: .group(groupName)
        )
        let secondAdmin = try XCTUnwrap(teamMembers.last)

        let conversationDetailsPage = try app.loginUser(email: owner.email, password: owner.password)
            .acceptPopup()
            .openConversation()
            .openConversationDetails()
            .openUserDetailsPage(byName: secondAdmin.name)
            .enableGroupAdmin()
            .goBackToConversationDetailsPage()

        XCTAssertTrue(
            conversationDetailsPage.adminCell(named: secondAdmin.name).waitForExistence(timeout: 5),
            "Second admin should appear in the admin section"
        )

        let leavingConversationDetailsPage = try conversationDetailsPage
            .moreOptionsConversationDetails()
            .leaveOptionsConversationDetails()

        XCTAssertFalse(
            leavingConversationDetailsPage.promoteNewAdminButton.exists,
            "Admin selection modal should not appear when self user is not the last admin"
        )

        let leftConversationDetailsPage = try leavingConversationDetailsPage
            .leaveConversation()

        XCTAssertTrue(
            leftConversationDetailsPage.userCell(named: owner.name).waitForNonExistence(timeout: 0.5),
            "Owner should not appear in participant list after leaving"
        )

        let activeConversationPage = try leftConversationDetailsPage.closeConversationDetails()

        XCTAssertTrue(
            activeConversationPage.userLeftSystemMessage.waitForExistence(timeout: 5),
            "'you left' system message missing"
        )
        XCTAssertFalse(
            activeConversationPage.inputMessageField.exists,
            "Input bar still showing available after leaving"
        )
    }

    func testLastPersonalUserAdmin_CannotLeaveGroup_PromotesNewAdmin_ThenLeaveGroupSuccessfully_TC_11577() async throws {
        let groupName = "Personal User Leave Group Test"
        let (
            owner,
            personalUser
        ) =
            try await createGroupConversationWithTeamMemberAndLastPersonalUserAdmin(groupName: groupName)

        let conversationsPage = try app
            .loginUser(email: personalUser.email, password: personalUser.password)
            .acceptPopup()

        let conversationDetailsPage = try conversationsPage.openConversationWithGuest(groupName: groupName)
            .openConversationDetails()
            .moreOptionsConversationDetails()
            .leaveOptionsConversationDetails()
            .tapCannotLeaveAlert() // cannot leave group
            .appParticipantToConversation()
            .tapMemberCells(withLabelPrefixes: [owner.name])
            .addSelectedParticipant() // adds eligible member
            .moreOptionsConversationDetails()
            .leaveOptionsConversationDetails()
            .tapPromoteNewAdmin() // promotes the member
            .selectUser(named: owner.name)
            .tapPromote()

        // Team member is now in the admin section
        XCTAssertTrue(
            conversationDetailsPage.adminCell(named: owner.name).waitForExistence(timeout: 5),
            "Promoted member should appear in the admin section"
        )

        // Personal user is no longer a participant
        XCTAssertTrue(
            conversationDetailsPage.userCell(named: personalUser.name).waitForNonExistence(timeout: 0.5),
            "Personal user should not appear in participant list after leaving"
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

    private func createGroupConversationWithTeamMemberAndLastPersonalUserAdmin(groupName: String) async throws
        -> (teamMember: UserInfo, personalUser: UserInfo) {
        let (teamMember, personalUser) = try await UserHelper.default.connectTeamUserWithPersonalUser()

        let domain = BackendTarget.staging.domainInfo
        let teamMemberQualifiedID = WireFoundation.QualifiedID(
            id: try XCTUnwrap(UUID(uuidString: teamMember.id)),
            domain: domain
        )
        let personalUserQualifiedID = WireFoundation.QualifiedID(
            id: try XCTUnwrap(UUID(uuidString: personalUser.id)),
            domain: domain
        )

        let conversation = try await UserHelper.default.createGroupConversations(
            qualifiedIds: [personalUserQualifiedID],
            owner: teamMember,
            groupName: groupName,
            driveEnabled: true
        )

        let conversationQualifiedID = try XCTUnwrap(conversation.qualifiedID)

        try await UserHelper.default.updateRole(
            "wire_admin",
            userID: personalUserQualifiedID,
            conversationID: conversationQualifiedID
        )

        try await UserHelper.default.removeParticipant(
            userID: teamMemberQualifiedID,
            conversationID: conversationQualifiedID
        )

        return (teamMember, personalUser)
    }

}
