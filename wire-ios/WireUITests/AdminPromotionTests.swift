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

    private let userHelper = UserHelper.instance(apiVersion: .v18)

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

        // TODO: [WPB-28649] - Remove when v18 is PROD ready.
        try switchToPreferredAPIVersion("18")

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

        try switchToPreferredAPIVersion("18")

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

        try switchToPreferredAPIVersion("18")

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

        try switchToPreferredAPIVersion("18")

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

        try switchToPreferredAPIVersion("18")

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
        var firstLeavingAdmin = owner
        var secondLeavingAdmin = secondAdmin
        try await ownerHelper.login(user: &firstLeavingAdmin)
        try await secondAdminHelper.login(user: &secondLeavingAdmin)

        let firstAdminID = try qualifiedID(of: firstLeavingAdmin)
        let secondAdminID = try qualifiedID(of: secondLeavingAdmin)

        let barrier = SimultaneousStartBarrier(participantCount: 2)
        async let firstResponse = leaveConversationOnceAllAreReady(
            using: ownerHelper,
            userID: firstAdminID,
            conversationID: conversationID,
            barrier: barrier
        )
        async let secondResponse = leaveConversationOnceAllAreReady(
            using: secondAdminHelper,
            userID: secondAdminID,
            conversationID: conversationID,
            barrier: barrier
        )
        let leaveResponses = try await [firstResponse, secondResponse]

        let successfulLeaves = leaveResponses.filter { $0.statusCode == 200 }
        XCTAssertEqual(successfulLeaves.count, 1, "Exactly one leave request should be accepted: \(leaveResponses)")

        let leavingAdmins = [firstLeavingAdmin, secondLeavingAdmin]
        for response in leaveResponses {
            if response.statusCode != 200 {
                XCTAssertEqual(response.statusCode, 403, "Last admin's leave request should be forbidden")
                XCTAssertEqual(
                    response.errorLabel,
                    "adminless-conversation",
                    "Leave request should be rejected because no admin would remain"
                )
            }
        }
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

        XCTAssertTrue(
            conversationDetailsPage.adminCells.firstMatch.waitForExistence(timeout: 30),
            "Group should have an admin after both leave requests"
        )
        XCTAssertEqual(conversationDetailsPage.adminCells.count, 1, "Exactly one admin should remain in the group")
    }

    @MainActor
    func testLastAdminDeleted_promotesEligibleMember_TC_11035() async throws {
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

        // Leave one admin and one eligible member in the group.
        var groupOwner = owner
        try await userHelper.login(user: &groupOwner)
        try await userHelper.updateRole("wire_admin", userID: adminMemberID, conversationID: conversationID)
        try await userHelper.removeParticipant(userID: try qualifiedID(of: groupOwner), conversationID: conversationID)

        // WHEN the only admin is deleted from the team
        let ownerAccessToken = try await userHelper.fetchAccessToken(email: owner.email, password: owner.password)
        try await userHelper.removeTeamMember(
            ownerAccessToken: ownerAccessToken.token,
            ownerPassword: owner.password,
            teamID: teamID,
            userID: adminMemberID.id
        )

        // THEN the eligible member is auto-promoted
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

        let federatedUserID = WireFoundation.QualifiedID(
            id: try XCTUnwrap(UUID(uuidString: federatedUser.id)),
            domain: BackendTarget.qaFederationB.domainInfo
        )
        let conversation = try await helperA.createGroupConversations(
            qualifiedIds: [adminA, federatedUserID],
            owner: groupOwner,
            groupName: groupName
        )
        let conversationID = try XCTUnwrap(conversation.qualifiedID)

        // Federated user cannot replace the last admin.
        try await helperA.updateRole("wire_admin", userID: adminA, conversationID: conversationID)
        try await helperA.removeParticipant(
            userID: try qualifiedID(of: groupOwner, on: .qaFederationA),
            conversationID: conversationID
        )

        try switchBackend(target: .qaFederationB)
        let activeConversationPage = try await loginToBackend(user: federatedUser)
            .openConversation(named: groupName)

        // WHEN the only admin is deleted from the team
        let ownerAccessToken = try await helperA.fetchAccessToken(email: ownerA.email, password: ownerA.password)
        try await helperA.removeTeamMember(
            ownerAccessToken: ownerAccessToken.token,
            ownerPassword: ownerA.password,
            teamID: teamIDA,
            userID: adminA.id
        )

        // THEN the remaining federated user sees the group scheduled for deletion
        XCTAssertTrue(
            activeConversationPage.scheduledForDeletionSystemMessage.waitForExistence(timeout: 30),
            "Expected the group to be scheduled for deletion as there is no eligible admin"
        )
    }

    private func leaveConversationOnceAllAreReady(
        using helper: UserHelper,
        userID: WireFoundation.QualifiedID,
        conversationID: WireFoundation.QualifiedID,
        barrier: SimultaneousStartBarrier
    ) async throws -> (statusCode: Int, errorLabel: String?) {
        await barrier.waitForAllParticipants()
        return try await helper.leaveConversation(userID: userID, conversationID: conversationID)
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
private actor SimultaneousStartBarrier {

    private let participantCount: Int
    private var suspendedParticipants: [CheckedContinuation<Void, Never>] = []

    init(participantCount: Int) {
        self.participantCount = participantCount
    }

    func waitForAllParticipants() async {
        let isLastParticipant = suspendedParticipants.count + 1 == participantCount
        guard isLastParticipant else {
            await withCheckedContinuation { suspendedParticipants.append($0) }
            return
        }

        let continuations = suspendedParticipants
        suspendedParticipants = []
        continuations.forEach { $0.resume() }
    }

}
