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

/// [core-messenger]
class AdminPromotionTests: WireUITestCase {

    private let userHelper = UserHelper.default

    @MainActor
    func testLastAdmin_promotesNewAdmin_andLeavesGroup_TC_11032() async throws {
        let groupName = UserGenerator.generateRandomConversationName()

        let (owner, teamMembers, _, _) = try await userHelper.registerTeam(
            withMemberCount: 1,
            conversation: .group(groupName)
        )
        let member = try XCTUnwrap(teamMembers.first)
        let teamID = try XCTUnwrap(owner.teamID)
        try await userHelper.unlockAndEnablePreventAdminlessGroupsFeature(teamID: teamID)

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

        try verifyUserLeftGroup(
            conversationDetailsPage,
            leavingUserName: owner.name,
            participantDescription: "Owner"
        )
    }

    @MainActor
    func testLastAdmin_deletesGroup_insteadOfPromoting_TC_11033() async throws {
        let groupName = UserGenerator.generateRandomConversationName()

        let (owner, _, _, _) = try await userHelper.registerTeam(
            withMemberCount: 1,
            conversation: .group(groupName)
        )

        let teamID = try XCTUnwrap(owner.teamID)
        try await userHelper.unlockAndEnablePreventAdminlessGroupsFeature(teamID: teamID)

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

        let (owner, _, _, _) = try await userHelper.registerTeam(
            withMemberCount: 0,
            conversation: .group(groupName)
        )

        let teamID = try XCTUnwrap(owner.teamID)
        try await userHelper.unlockAndEnablePreventAdminlessGroupsFeature(teamID: teamID)

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
    func testLastGuestUserAdmin_CannotLeaveGroup_PromotesNewAdmin_ThenLeaveGroupSuccessfully_TC_11577() async throws {
        let groupName = "Guest User Leave Group Test"
        let (
            owner,
            guestUser
        ) =
            try await createGroupConversationWithTeamMemberAndLastGuestUserAdmin(groupName: groupName)

        let conversationsPage = try app
            .loginUser(email: guestUser.email, password: guestUser.password)
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

        try verifyUserLeftGroup(
            conversationDetailsPage,
            leavingUserName: guestUser.name,
            participantDescription: "Guest user"
        )
    }

    private func createGroupConversationWithTeamMemberAndLastGuestUserAdmin(groupName: String) async throws
        -> (teamMember: UserInfo, personalUser: UserInfo) {
        let (teamMember, guestUser) = try await userHelper.connectDriveEnabledTeamUserWithGuestUser()

        let domain = BackendTarget.staging.domainInfo
        let teamMemberQualifiedID = WireFoundation.QualifiedID(
            id: try XCTUnwrap(UUID(uuidString: teamMember.id)),
            domain: domain
        )
        let guestUserQualifiedID = WireFoundation.QualifiedID(
            id: try XCTUnwrap(UUID(uuidString: guestUser.id)),
            domain: domain
        )

        try await userHelper
            .unlockAndEnablePreventAdminlessGroupsFeature(teamID: try XCTUnwrap(teamMember.teamID))
        try await userHelper
            .unlockAndEnablePreventAdminlessGroupsFeature(teamID: try XCTUnwrap(guestUser.teamID))

        let conversation = try await userHelper.createGroupConversations(
            qualifiedIds: [guestUserQualifiedID],
            owner: teamMember,
            groupName: groupName,
            driveEnabled: true
        )

        let conversationQualifiedID = try XCTUnwrap(conversation.qualifiedID)

        try await userHelper.updateRole(
            "wire_admin",
            userID: guestUserQualifiedID,
            conversationID: conversationQualifiedID
        )

        try await userHelper.removeParticipant(
            userID: teamMemberQualifiedID,
            conversationID: conversationQualifiedID
        )

        return (teamMember, guestUser)
    }

    @MainActor
    private func verifyUserLeftGroup(
        _ conversationDetailsPage: ConversationDetailsPage,
        leavingUserName: String,
        participantDescription: String
    ) throws {
        XCTAssertTrue(
            conversationDetailsPage.userCell(named: leavingUserName).waitForNonExistence(timeout: 5),
            "\(participantDescription) should not appear in participant list after leaving"
        )

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
    func testAdmin_notLastAdmin_leavesGroupWithoutAdminSelectionModal_TC_11031() async throws {
        let groupName = UserGenerator.generateRandomConversationName()

        let (owner, _, _, _) = try await userHelper.createGroupConversationWithAdminsAndMembers(
            groupName: groupName,
            memberCount: 2,
            groupAdminCount: 2,
            preventAdminlessGroupsEnabled: true
        )

        let teamID = try XCTUnwrap(owner.teamID)
        try await userHelper.unlockAndEnablePreventAdminlessGroupsFeature(teamID: teamID)

        let conversationDetailsPage = try app.loginUser(email: owner.email, password: owner.password)
            .acceptPopup()
            .openConversation()
            .openConversationDetails()

        let leavingConversationDetailsPage = try conversationDetailsPage
            .moreOptionsConversationDetails()
            .leaveOptionsConversationDetails()

        XCTAssertFalse(
            leavingConversationDetailsPage.promoteNewAdminButton.exists,
            "Admin selection modal should not appear when self user is not the last admin"
        )

        let leftConversationDetailsPage = try leavingConversationDetailsPage
            .leaveConversation()

        try verifyUserLeftGroup(
            leftConversationDetailsPage,
            leavingUserName: owner.name,
            participantDescription: "Owner"
        )
    }

    @MainActor
    func testLastAdminDeleted_promotesEligibleMember_TC_11035() async throws {
        // GIVEN
        let groupName = UserGenerator.generateRandomConversationName()

        let (owner, teamMembers, qualifiedIDs, conversationId) = try await userHelper.registerTeam(
            withMemberCount: 2,
            conversation: .group(groupName)
        )
        let teamID = try XCTUnwrap(owner.teamID)
        let adminMember = try XCTUnwrap(teamMembers.first)
        let adminMemberID = try XCTUnwrap(qualifiedIDs.first)
        let eligibleMember = try XCTUnwrap(teamMembers.last)
        let conversationID = WireFoundation.QualifiedID(
            id: try XCTUnwrap(conversationId),
            domain: BackendTarget.staging.domainInfo
        )
        try await userHelper.unlockAndEnablePreventAdminlessGroupsFeature(teamID: teamID)

        try await userHelper.promoteMemberAndLeave(userID: adminMemberID, conversationID: conversationID)

        // WHEN
        try await userHelper.removeTeamMemberFromTeam(userID: adminMemberID.id, owner: owner)

        // THEN
        let conversationDetailsPage = try app
            .loginUser(email: eligibleMember.email, password: eligibleMember.password)
            .acceptPopup()
            .openConversation(named: groupName)
            .openConversationDetails()

        XCTAssertTrue(
            conversationDetailsPage.adminCell(named: eligibleMember.name).waitForExistence(timeout: 10),
            "Eligible member should be auto-promoted to admin"
        )
        XCTAssertTrue(
            conversationDetailsPage.userCell(named: adminMember.name).waitForNonExistence(timeout: 5),
            "Deleted admin should not appear in participant list"
        )
    }

    @MainActor
    func testLastAdminDeleted_schedulesGroupDeletion_whenOnlyFederatedMemberRemains_TC_11040() async throws {
        // GIVEN
        let groupName = "Federated \(UserGenerator.generateRandomConversationName())"
        let groupOwnerHelper = UserHelper.instance(backend: .qaFederationA)
        let federatedUserHelper = UserHelper.instance(backend: .qaFederationB)

        let (owner, _, qualifiedIDs, _) = try await groupOwnerHelper.registerTeam(withMemberCount: 1)
        let (federatedOwner, _, _, _) = try await federatedUserHelper.registerTeam(
            withMemberCount: 0,
            names: ["Federated User"]
        )
        let teamID = try XCTUnwrap(owner.teamID)
        let memberID = try XCTUnwrap(qualifiedIDs.first)
        // Schedule the first reminder after one second, with deletion one hour away.
        try await groupOwnerHelper.unlockAndEnablePreventAdminlessGroupsFeature(
            teamID: teamID,
            deletionTimeout: "1h",
            reminderTimeouts: ["3599s"]
        )

        // Connect the team owners of both backends
        var groupOwner = owner
        var federatedUser = federatedOwner
        try await groupOwnerHelper.login(user: &groupOwner)
        try await federatedUserHelper.login(user: &federatedUser)
        try await groupOwnerHelper.sendConnectionRequestToUser(
            domain: BackendTarget.qaFederationB.domainInfo,
            userId: federatedUser.id
        )
        try await federatedUserHelper.acceptConnectionRequestFromUser(
            domain: BackendTarget.qaFederationA.domainInfo,
            user1: federatedUser,
            userId: groupOwner.id
        )

        let federatedUserID = WireFoundation.QualifiedID(
            id: try XCTUnwrap(UUID(uuidString: federatedUser.id)),
            domain: BackendTarget.qaFederationB.domainInfo
        )
        let conversation = try await groupOwnerHelper.createGroupConversations(
            qualifiedIds: [memberID, federatedUserID],
            owner: groupOwner,
            groupName: groupName
        )
        let conversationID = try XCTUnwrap(conversation.qualifiedID)
        try await groupOwnerHelper.promoteMemberAndLeave(
            userID: memberID,
            conversationID: conversationID
        )

        try switchBackend(target: .qaFederationB)
        let activeConversationPage = try await loginToBackend(user: federatedUser)
            .openConversation(named: groupName)

        // WHEN
        try await groupOwnerHelper.removeTeamMemberFromTeam(userID: memberID.id, owner: groupOwner)

        // THEN
        XCTAssertTrue(
            activeConversationPage.scheduledForDeletionSystemMessage.waitForExistence(timeout: 10),
            "Federated user should see the group scheduled for deletion"
        )
    }

    @MainActor
    func testTemporaryGuestIsOnlyMember_groupBecomesGhostGroupAndIsScheduledToBeDeleted_TC_11037() async throws {
        // GIVEN
        let guestGroupName = "Guest \(UserGenerator.generateRandomConversationName())"
        let (owner, teamMembers, qualifiedIDs, _) = try await userHelper.registerTeam(withMemberCount: 1)
        let teamID = try XCTUnwrap(owner.teamID)
        let member = try XCTUnwrap(teamMembers.first)
        let memberID = try XCTUnwrap(qualifiedIDs.first)
        member.teamID = teamID
        // Remind after one and three seconds, then delete after ten seconds.
        try await userHelper.unlockAndEnablePreventAdminlessGroupsFeature(
            teamID: teamID,
            deletionTimeout: "10s",
            reminderTimeouts: ["9s", "7s"]
        )

        let conversation = try await userHelper.createGroupConversations(
            qualifiedIds: [],
            owner: member,
            groupName: guestGroupName
        )
        let guestConversationID = try XCTUnwrap(conversation.qualifiedID)
        var teamOwner = owner
        try await userHelper.login(user: &teamOwner)

        let guestOptionsPage = try app.loginUser(email: member.email, password: member.password)
            .acceptPopup()
            .openConversation(named: guestGroupName)
            .openConversationDetails()
            .openGuestOptions()
            .createLinkWithoutPassword()
        let guestLink = try guestOptionsPage.guestLink()
        let (guest, guestHelper) = try await UserHelper.registerGuest(name: "Guest")
        XCTAssertNotNil(guest.expiresAt, "Guest account should have an expiry date")
        try await guestHelper.joinGuestLink(guestLink)

        // WHEN
        try await userHelper.removeTeamMemberFromTeam(userID: memberID.id, owner: teamOwner)

        // THEN
        let remainingMember = try await guestHelper.waitForOnlyMember(in: guestConversationID)
        XCTAssertEqual(remainingMember.conversationRole, "wire_member", "Guest should not be promoted")

        let reminders = try await guestHelper.waitForAdminlessGroupDeletion(guestConversationID)
        XCTAssertEqual(reminders.count, 2, "Expected both reminders before deletion")
        let conversations = try await guestHelper.conversationsAPI.getConversations(for: [guestConversationID])
        XCTAssertTrue(conversations.notFound.contains(guestConversationID), "Guest group should be deleted")
    }

}
