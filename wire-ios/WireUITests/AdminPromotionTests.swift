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
    func testTwoAdminsLeaveAtTheSameTime_onlyOneAdminRemains_TC_11064() async throws {
        // GIVEN
        let groupName = UserGenerator.generateRandomConversationName()

        let (owner, admins, members, conversation) = try await userHelper.createGroupConversationWithAdminsAndMembers(
            groupName: groupName,
            memberCount: 3,
            groupAdminCount: 2,
            preventAdminlessGroupsEnabled: true
        )
        let secondAdmin = try XCTUnwrap(admins.last)
        let conversationID = try XCTUnwrap(conversation.qualifiedID)

        let ownerHelper = UserHelper.makeIsolatedInstance()
        let secondAdminHelper = UserHelper.makeIsolatedInstance()
        var leavingAdmins = [owner, secondAdmin]
        try await ownerHelper.login(user: &leavingAdmins[0])
        try await secondAdminHelper.login(user: &leavingAdmins[1])

        // WHEN
        let barrier = AdminLeaveBarrier()
        async let firstResponse = leaveConversationOnceAllAreReady(
            using: ownerHelper,
            user: leavingAdmins[0],
            conversationID: conversationID,
            barrier: barrier
        )
        async let secondResponse = leaveConversationOnceAllAreReady(
            using: secondAdminHelper,
            user: leavingAdmins[1],
            conversationID: conversationID,
            barrier: barrier
        )
        let leaveResponses = try await [firstResponse, secondResponse]

        // THEN
        let successfulLeaves = leaveResponses.filter { $0.statusCode == 200 }
        XCTAssertEqual(successfulLeaves.count, 1, "Exactly one leave request should be accepted: \(leaveResponses)")

        let rejectedLeave = try XCTUnwrap(leaveResponses.first { $0.statusCode != 200 })
        XCTAssertEqual(rejectedLeave.statusCode, 403, "Last admin's leave request should be forbidden")
        XCTAssertEqual(rejectedLeave.errorLabel, "adminless-conversation", "Last admin should not be allowed to leave")
        let observer = try XCTUnwrap(members.first)
        let conversationDetailsPage = try app.loginUser(email: observer.email, password: observer.password)
            .acceptPopup()
            .openConversation(named: groupName)
            .openConversationDetails()

        for (admin, response) in zip(leavingAdmins, leaveResponses) {
            if response.statusCode == 200 {
                XCTAssertTrue(
                    conversationDetailsPage.userCell(named: admin.name).waitForNonExistence(timeout: 10),
                    "Admin whose request was accepted should not appear in participant list after leaving"
                )
            } else {
                XCTAssertTrue(
                    conversationDetailsPage.adminCell(named: admin.name).waitForExistence(timeout: 10),
                    "Admin whose request was rejected should still be admin of the group"
                )
            }
        }

        XCTAssertEqual(conversationDetailsPage.adminCells.count, 1, "Exactly one admin should remain in the group")
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
        try await userHelper.removeTeamMember(userID: adminMemberID.id, owner: owner)

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
        let groupName = UserGenerator.generateRandomConversationName()
        let helperA = UserHelper.instance(backend: .qaFederationA)
        let helperB = UserHelper.instance(backend: .qaFederationB)

        let (ownerA, _, qualifiedIDsA, _) = try await helperA.registerTeam(withMemberCount: 1)
        let (ownerB, _, _, _) = try await helperB.registerTeam(withMemberCount: 0)
        let teamIDA = try XCTUnwrap(ownerA.teamID)
        let adminA = try XCTUnwrap(qualifiedIDsA.first)
        // Schedule the first reminder after one second, with deletion one hour away.
        try await helperA.unlockAndEnablePreventAdminlessGroupsFeature(
            teamID: teamIDA,
            deletionTimeout: "1h",
            reminderTimeouts: ["3599s"]
        )

        // Connect the team owners of both backends
        var groupOwner = ownerA
        var federatedUser = ownerB
        try await helperA.login(user: &groupOwner)
        try await helperB.login(user: &federatedUser)
        try await helperA.sendConnectionRequestToUser(
            domain: BackendTarget.qaFederationB.domainInfo,
            userId: federatedUser.id
        )
        try await helperB.acceptConnectionRequestFromUser(
            domain: BackendTarget.qaFederationA.domainInfo,
            user1: federatedUser,
            userId: groupOwner.id
        )

        let federatedUserID = try qualifiedID(of: federatedUser, on: .qaFederationB)
        let conversation = try await helperA.createGroupConversations(
            qualifiedIds: [adminA, federatedUserID],
            owner: groupOwner,
            groupName: groupName
        )
        let conversationID = try XCTUnwrap(conversation.qualifiedID)

        try await helperA.promoteMemberAndLeave(userID: adminA, conversationID: conversationID)

        try switchBackend(target: .qaFederationB)
        let activeConversationPage = try await loginToBackend(user: federatedUser)
            .openConversation(named: groupName)

        // WHEN
        try await helperA.removeTeamMember(userID: adminA.id, owner: ownerA)

        // THEN
        XCTAssertTrue(
            activeConversationPage.scheduledForDeletionSystemMessage.waitForExistence(timeout: 30),
            "Expected the group to be scheduled for deletion as there is no eligible admin"
        )
    }

    private func leaveConversationOnceAllAreReady(
        using helper: UserHelper,
        user: UserInfo,
        conversationID: WireFoundation.QualifiedID,
        barrier: AdminLeaveBarrier
    ) async throws -> (statusCode: Int, errorLabel: String?) {
        await barrier.waitForBothAdmins()
        return try await helper.leaveConversation(userID: try qualifiedID(of: user), conversationID: conversationID)
    }

    @MainActor
    func testTemporaryGuestIsOnlyMember_groupBecomesGhostGroupAndIsDeleted_TC_11037() async throws {

        // GIVEN
        let groupName = UserGenerator.generateRandomConversationName()
        let (owner, teamMembers, qualifiedIDs, conversationId) = try await userHelper.registerTeam(
            withMemberCount: 1,
            conversation: .group(groupName)
        )
        let teamID = try XCTUnwrap(owner.teamID)
        let member = try XCTUnwrap(teamMembers.first)
        let memberID = try XCTUnwrap(qualifiedIDs.first)
        let conversationID = WireFoundation.QualifiedID(
            id: try XCTUnwrap(conversationId),
            domain: BackendTarget.staging.domainInfo
        )
        // Remind after one and three seconds; allow time for the backend worker before deletion.
        try await userHelper.unlockAndEnablePreventAdminlessGroupsFeature(
            teamID: teamID,
            deletionTimeout: "10s",
            reminderTimeouts: ["9s", "7s"]
        )

        let guestOptionsPage = try app.loginUser(email: owner.email, password: owner.password)
            .acceptPopup()
            .openConversation(named: groupName)
            .openConversationDetails()
            .openGuestOptions()
            .createLinkWithoutPassword()
        let guestLink = try guestOptionsPage.guestLink()
        let guestHelper = UserHelper.makeIsolatedInstance()
        let guest = try await guestHelper.registerGuest(name: "Guest")
        XCTAssertNotNil(guest.expiresAt, "Guest account should have an expiry date")
        try await guestHelper.joinGuestLink(guestLink)

        let conversationDetailsPage = try guestOptionsPage.goBackToConversationDetails()
            .moreOptionsConversationDetails()
            .leaveOptionsConversationDetails()
            .tapPromoteNewAdmin()
            .selectUser(named: member.name)
            .tapPromote()

        try verifyUserLeftGroup(
            conversationDetailsPage,
            leavingUserName: owner.name,
            participantDescription: "Owner"
        )

        // WHEN
        let ghostGroupStart = Date()
        try await userHelper.removeTeamMember(userID: memberID.id, owner: owner)

        // THEN
        let remainingMember = try await guestHelper.waitForOnlyMember(in: conversationID)
        XCTAssertEqual(remainingMember.qualifiedID?.id, guest.id, "Guest should be the only member")
        XCTAssertEqual(remainingMember.conversationRole, "wire_member", "Guest should not be promoted")

        let (reminders, deletedAt) = try await guestHelper.waitForAdminlessGroupDeletion(conversationID)
        XCTAssertEqual(reminders.count, 2, "Expected both reminders before deletion")
        let deletionDate = try XCTUnwrap(reminders.first?.scheduledDeletionDate)
        XCTAssertEqual(deletionDate.timeIntervalSince(ghostGroupStart), 10, accuracy: 3)
        XCTAssertEqual(
            reminders.last?.scheduledDeletionDate,
            deletionDate,
            "Reminders should keep the same deletion date"
        )
        XCTAssertGreaterThanOrEqual(deletedAt, deletionDate, "Group should not be deleted before its countdown ends")
        let conversations = try await guestHelper.conversationsAPI.getConversations(for: [conversationID])
        XCTAssertTrue(conversations.notFound.contains(conversationID), "Ghost group should be deleted")
    }

    private func qualifiedID(
        of user: UserInfo,
        on backend: BackendTarget = .staging
    ) throws -> WireFoundation.QualifiedID {
        WireFoundation.QualifiedID(
            id: try XCTUnwrap(UUID(uuidString: user.id)),
            domain: backend.domainInfo
        )
    }

}

/// Waits until both admins are ready to send their leave requests.
private actor AdminLeaveBarrier {

    private var waitingAdmin: CheckedContinuation<Void, Never>?

    func waitForBothAdmins() async {
        if let waitingAdmin {
            self.waitingAdmin = nil
            waitingAdmin.resume()
        } else {
            await withCheckedContinuation { waitingAdmin = $0 }
        }
    }

}
