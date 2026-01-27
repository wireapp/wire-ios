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

import WireDataModelSupport
import XCTest
@testable import WireDataModel

final class ZMUserTests_Permissions: ModelObjectsTests {

    let defaultAdminRoleName = "wire_admin"
    var team: Team!
    var conversation: ZMConversation!

    override func setUp() {
        super.setUp()
        team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = .create()
        conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        conversation.addParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: uiMOC), role: nil)
    }

    override func tearDown() {
        team = nil
        conversation = nil
        super.tearDown()
    }

    // MARK: Deleting conversation

    func testThatConversationCanBeDeleted_ByItsCreator() {
        // when
        makeSelfUserTeamMember(withPermissions: .member)
        conversation.creator = selfUser
        conversation.team = team
        conversation.teamRemoteIdentifier = team.remoteIdentifier
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.teamIdentifier = conversation.teamRemoteIdentifier
        selfUser.teamIdentifier = conversation.teamRemoteIdentifier
        conversation.teamRemoteIdentifier = team.remoteIdentifier
        createARoleForSelfUserWith("delete_conversation")

        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canDeleteConversation(conversation))
    }

    func testThatConversationCantBeDeleted_ByItsCreatorIfNotInTeam() {
        // when
        makeSelfUserTeamMember(withPermissions: .member)
        conversation.creator = selfUser
        conversation.team = team
        conversation.teamRemoteIdentifier = team.remoteIdentifier
        createARoleForSelfUserWith("delete_conversation")

        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canDeleteConversation(conversation))
    }

    func testThatConversationCantBeDeleted_ByItsCreatorIfNotAnActiveParticipant() {
        // when
        makeSelfUserTeamMember(withPermissions: .member)
        conversation.removeParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: uiMOC))
        conversation.creator = selfUser
        createARoleForSelfUserWith("delete_conversation")

        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canDeleteConversation(conversation))
    }

    func testThatConversationCantBeDeleted_ByItsCreatorIfANonTeamConversation() {
        // when
        makeSelfUserTeamMember(withPermissions: .member)
        conversation.creator = selfUser
        conversation.teamRemoteIdentifier = nil
        createARoleForSelfUserWith("delete_conversation")

        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canDeleteConversation(conversation))
    }

    func testChannelCanBeDeleted_ByNonCreatorTeamAdmin_Channel() {
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        let adminUser = updateConversationToChannelWithUserToBecomeTeamAdmin()

        XCTAssertFalse(adminUser.canDeleteConversation(conversation))
        makeUserAdmin(adminUser)
        XCTAssertTrue(adminUser.canDeleteConversation(conversation))
    }

    func testChannelCanBeDeleted_ByNonCreatorTeamAdmin_Group() {
        makeSelfUserTeamMember(withPermissions: .member)
        conversation.creator = selfUser
        conversation.teamRemoteIdentifier = nil
        conversation.groupType = .group

        let adminUser = createUserAndAddInConversation()

        // just need one more user in conversation
        _ = createUserAndAddInConversation()

        XCTAssertFalse(adminUser.canDeleteConversation(conversation))
        makeUserAdmin(adminUser)
        XCTAssertFalse(adminUser.canDeleteConversation(conversation))
    }

    // MARK: Guests

    func testThatItDoesNotReportIsGuest_ForANonTeamConversation() {
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).isGuest(in: conversation))
    }

    func testThatItReportsIsGuest_ForAFederatedConversation() {
        let user = ZMUser.selfUser(in: uiMOC)
        user.domain = UUID().transportString()
        conversation.domain = UUID().transportString()

        XCTAssertTrue(user.isGuest(in: conversation))
    }

    func testThatItReportsIsGuest_ForANonTeamUserInATeamConversation() {
        // given
        conversation.team = team
        conversation.teamRemoteIdentifier = team.remoteIdentifier

        // then
        XCTAssertTrue(ZMUser.selfUser(in: uiMOC).isGuest(in: conversation))
    }

    func testThatItReportsIsGuest_WhenAConversationDoesNotHaveATeam() {
        // given
        conversation.teamRemoteIdentifier = team.remoteIdentifier

        // then
        XCTAssert(ZMUser.selfUser(in: uiMOC).isGuest(in: conversation))
    }

    func testGuestsOptionCanUpdatedByTeamAdmin() {
        makeSelfUserTeamMember(withPermissions: .modifyConversationMetaData)
        let adminUser = updateConversationToChannelWithUserToBecomeTeamAdmin()

        XCTAssertFalse(adminUser.canModifyGuestsAccessControlSettings(in: conversation))
        makeUserOwner(adminUser)
        XCTAssertTrue(adminUser.canModifyGuestsAccessControlSettings(in: conversation))
    }

    // MARK: Create services

    func testThatServiceCantBeCreated_ByNonTeamUser() {
        XCTAssertFalse(selfUser.canCreateService)
    }

    func testThatServiceCanBeCreated_ByTeamMemberWithSufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: .member)

        // then
        XCTAssertTrue(selfUser.canCreateService)
    }

    func testThatServiceCantBeCreated_ByTeamMemberWithInsufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: .partner)

        // then
        XCTAssertFalse(selfUser.canCreateService)
    }

    // MARK: Create conversation

    func testThatOneOnOneConversationCanBeCreated_ByNonTeamUser() {
        XCTAssert(selfUser.canCreateConversation(type: .oneOnOne))
    }

    func testThatGroupConversationCanBeCreated_ByNonTeamUser() {
        XCTAssert(selfUser.canCreateConversation(type: .group))
    }

    func testThatGroupConversationCanNotCreated_ByPartner() {
        // given
        makeSelfUserTeamMember(withPermissions: .partner)

        // then
        XCTAssertFalse(selfUser.canCreateConversation(type: .group))
    }

    func testThatConversationCanBeCreated_ByTeamMemberWithSufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: .member)

        // then
        XCTAssert((selfUser?.canCreateConversation(type: .group))!)
    }

    func testThatConversationCantBeCreated_ByTeamMemberWithInsufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: .partner)

        // then
        XCTAssertFalse(selfUser.canDeleteConversation(conversation))
    }

    // MARK: Manage team

    func testThatTeamCantBeManaged_ByNonTeamUser() {
        XCTAssertFalse(selfUser.canManageTeam)
    }

    func testThatTeamCanBeManaged_ByTeamMemberWithSufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: .admin)

        // then
        XCTAssertTrue(selfUser.canManageTeam)
    }

    func testThatTeamCantBeManaged_ByTeamMemberWithInsufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: .member)

        // then
        XCTAssertFalse(selfUser.canManageTeam)
    }

    // MARK: Access company information

    func testThatItAllowsSeeingCompanyInformationBetweenTwoSameTeamUsers() {
        // given
        let (team, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)

        // we add actual team members as well
        let (user1, _) = createUserAndAddMember(to: team)
        let (user2, _) = createUserAndAddMember(to: team)

        user1.name = "Abacus Allison"
        user2.name = "Zygfried Watson"

        // when
        let user1CanSeeUser2 = user1.canAccessCompanyInformation(of: user2)
        let user2CanSeeUser1 = user2.canAccessCompanyInformation(of: user1)

        // then
        XCTAssertTrue(user1CanSeeUser2)
        XCTAssertTrue(user2CanSeeUser1)
    }

    func testThatItDoesNotAllowSeeingCompanyInformationBetweenMemberAndGuest() {
        // given
        let (team, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)

        // we add actual team members as well
        let (user1, _) = createUserAndAddMember(to: team)

        // when
        let guest = ZMUser.insertNewObject(in: uiMOC)
        let guestCanSeeUser1 = guest.canAccessCompanyInformation(of: user1)
        let user1CanSeeGuest = user1.canAccessCompanyInformation(of: guest)

        // then
        XCTAssertFalse(guestCanSeeUser1)
        XCTAssertFalse(user1CanSeeGuest)
    }

    func testThatItDoesNotAllowSeeingCompanyInformationBetweenMembersFromDifferentTeams() {
        // given
        let (team1, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)
        let (team2, _) = createTeamAndMember(for: ZMUser.insert(in: uiMOC, name: "User 2"), with: .member)

        // we add actual team members as well
        let (user1, _) = createUserAndAddMember(to: team1)
        let (user2, _) = createUserAndAddMember(to: team2)

        // when
        let user1CanSeeUser2 = user1.canAccessCompanyInformation(of: user2)
        let user2CanSeeUser1 = user2.canAccessCompanyInformation(of: user1)

        // then
        XCTAssertFalse(user1CanSeeUser2)
        XCTAssertFalse(user2CanSeeUser1)
    }

    // @SF.Federation @SF.Separation @TSFI.UserInterface @S0.2
    func testThatUserCannotSeeCompanyInformationOfAnotherUser_WhenTeamIsTheSame_AndDomainIsDifferent() {
        // given
        let (team, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)

        // we add actual team members as well
        let (user1, _) = createUserAndAddMember(to: team)
        let (user2, _) = createUserAndAddMember(to: team)

        user1.domain = "wire.com"
        user2.domain = "not-wire.com"

        // when
        let user1CanSeeUser2 = user1.canAccessCompanyInformation(of: user2)
        let user2CanSeeUser1 = user2.canAccessCompanyInformation(of: user1)

        // then
        XCTAssertFalse(user1CanSeeUser2)
        XCTAssertFalse(user2CanSeeUser1)
    }

    // MARK: Notifications Setting

    func testThatConversationNotificationSettingsCanBeModified_ByAnyTeamMember() {
        // given
        makeSelfUserTeamMember(withPermissions: [])

        // then
        XCTAssertTrue(ZMUser.selfUser(in: uiMOC).canModifyNotificationSettings(in: conversation))
    }

    func testThatConversationNotificationSettingsCanBeModified_ByTeamGuest() {
        // given
        makeSelfUserTeamMember(withPermissions: [])
        conversation.teamRemoteIdentifier = nil

        // then
        XCTAssertTrue(ZMUser.selfUser(in: uiMOC).canModifyNotificationSettings(in: conversation))
    }

    func testThatConversationNotificationSettingsCantBeModified_ByNonTeamMember() {
        // when & then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyNotificationSettings(in: conversation))
    }

    func testThatConversationNotificationSettingsCantBeModified_ByGuest() {
        // given
        conversation.teamRemoteIdentifier = UUID()

        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyNotificationSettings(in: conversation))
    }

    func testThatConversationNotificationSettingsCantBeModified_ByInactiveParticipant() {
        // given
        conversation.removeParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: uiMOC))

        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyNotificationSettings(in: conversation))
    }

}

// MARK: Conversation roles

extension ZMUserTests_Permissions {
    func testThatConversationTitleCanBeModified_ByGroupParticipant() {
        // given
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        conversation.conversationType = .group

        createARoleForSelfUserWith("modify_conversation_name")
        // then
        XCTAssertTrue(selfUser.canModifyTitle(in: conversation))
    }

    func testThatConversationTitleCantBeModified_ByGroupParticipant() {
        // given
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        conversation.conversationType = .group

        // then
        XCTAssertFalse(selfUser.canModifyTitle(in: conversation))
    }

    func testCanRenameChannelByTeamAdmin() {
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        let adminUser = updateConversationToChannelWithUserToBecomeTeamAdmin()

        XCTAssertFalse(adminUser.canModifyTitle(in: conversation))
        makeUserAdmin(adminUser)
        XCTAssertTrue(adminUser.canModifyTitle(in: conversation))
    }

    func testCanAddParticipantsInChannelByTeamAdmin() {
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        let adminUser = updateConversationToChannelWithUserToBecomeTeamAdmin()

        XCTAssertFalse(adminUser.canAddUser(to: conversation))
        makeUserOwner(adminUser)
        XCTAssertTrue(adminUser.canAddUser(to: conversation))
    }

    func testCanAddParticipantsInChannelIfAddParticipantsIsAdminAndMember() {
        let user = updateConversationToChannelWithUserToBecomeTeamAdmin()

        XCTAssertFalse(user.canAddUser(to: conversation))
        conversation.privateChannelPermission = .everyone
        conversation.accessRoles.remove(.guest)
        XCTAssertTrue(user.canAddUser(to: conversation))
    }
    
    func testCanAddParticipantsInChannelIfAddParticipantsIsAdminAndMemberButGuest() {
        let user = updateConversationToChannelWithUserToBecomeTeamAdmin()

        conversation.privateChannelPermission = .everyone
        conversation.accessRoles.insert(.guest)
        XCTAssertFalse(user.canAddUser(to: conversation))
        
        conversation.accessRoles.remove(.guest)
        XCTAssertTrue(user.canAddUser(to: conversation))
    }

    func testThatGroupParticipantCanAddAnotherMemberToTheConversation() {
        // given
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        conversation.conversationType = .group
        createARoleForSelfUserWith("add_conversation_member")

        // then
        XCTAssertTrue(selfUser.canAddUser(to: conversation))
    }

    func testThatGroupParticipantCantAddAnotherMemberToTheConversation() {
        // given
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        conversation.conversationType = .group

        // then
        XCTAssertFalse(selfUser.canAddUser(to: conversation))
    }

    func testThatGroupParticipantCanRemoveAnotherMemberFromTheConversation() {
        // given
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        conversation.conversationType = .group
        createARoleForSelfUserWith("remove_conversation_member")

        // then
        XCTAssertTrue(selfUser.canRemoveUser(from: conversation))
    }

    func testCanRemoveParticipantInChannelByTeamAdmin() {
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)

        let adminUser = updateConversationToChannelWithUserToBecomeTeamAdmin()

        XCTAssertFalse(adminUser.canRemoveUser(from: conversation))
        makeUserAdmin(adminUser)
        XCTAssertTrue(adminUser.canRemoveUser(from: conversation))
    }

    func testThatGroupParticipantCantRemoveAnotherMemberFromTheConversation() {
        // given
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        conversation.conversationType = .group

        // then
        XCTAssertFalse(selfUser.canRemoveUser(from: conversation))
    }

    func testThatGroupParticipantCanModifyConversationMessageTimer() {
        // given
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        conversation.conversationType = .group
        createARoleForSelfUserWith("modify_conversation_message_timer")

        // then
        XCTAssertTrue(selfUser.canModifyEphemeralSettings(in: conversation))
    }

    func testThatGroupParticipantCantModifyConversationMessageTimer() {
        // given
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        conversation.conversationType = .group

        // then
        XCTAssertFalse(selfUser.canModifyEphemeralSettings(in: conversation))
    }

    func testCanModifyMessageTimer_InChannelByTeamAdmin() {
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)

        let adminUser = updateConversationToChannelWithUserToBecomeTeamAdmin()

        XCTAssertFalse(adminUser.canModifyEphemeralSettings(in: conversation))
        makeUserAdmin(adminUser)
        XCTAssertTrue(adminUser.canModifyEphemeralSettings(in: conversation))
    }

    func testThatGroupParticipantCanModifyConversationReceiptMode() {
        // given
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        conversation.conversationType = .group
        createARoleForSelfUserWith("modify_conversation_receipt_mode")

        // then
        XCTAssertTrue(selfUser.canModifyReadReceiptSettings(in: conversation))
    }

    func testThatGroupParticipantCantModifyConversationReceiptMode() {
        // given
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        conversation.conversationType = .group

        // then
        XCTAssertFalse(selfUser.canModifyReadReceiptSettings(in: conversation))
    }

    func testCanReadReceipts_InChannelByTeamAdmin() {
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)

        let adminUser = updateConversationToChannelWithUserToBecomeTeamAdmin()

        XCTAssertFalse(adminUser.canModifyReadReceiptSettings(in: conversation))
        makeUserOwner(adminUser)
        XCTAssertTrue(adminUser.canModifyReadReceiptSettings(in: conversation))
    }

    func testThatGroupParticipantCanModifyOtherConversationMember() {
        // given
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        conversation.conversationType = .group
        createARoleForSelfUserWith("modify_other_conversation_member")

        // then
        XCTAssertTrue(selfUser.canModifyOtherMember(in: conversation))
    }

    func testThatGroupParticipantCantModifyOtherConversationMember() {
        // given
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        conversation.conversationType = .group

        // then
        XCTAssertFalse(selfUser.canModifyOtherMember(in: conversation))
    }

    func testModifyOtherMember_InChannelByTeamAdmin() {
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        let adminUser = updateConversationToChannelWithUserToBecomeTeamAdmin()

        XCTAssertFalse(adminUser.canModifyOtherMember(in: conversation))
        makeUserAdmin(adminUser)
        XCTAssertTrue(adminUser.canModifyOtherMember(in: conversation))
    }

    func testThatConversationCreatorWithAdminRoleCanDeleteConversation() {
        // given
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        conversation.conversationType = .group
        conversation.creator = selfUser
        createARoleForSelfUserWith("delete_conversation")

        // then
        XCTAssertTrue(selfUser.canDeleteConversation(conversation))
    }

    func testThatNoConversationCreatorWithAdminRoleCantDeleteConversation() {
        // given
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        conversation.conversationType = .group
        createARoleForSelfUserWith("delete_conversation")

        // then
        XCTAssertFalse(selfUser.canDeleteConversation(conversation))
    }

    func testThatGroupParticipantCantDeleteConversation() {
        // given
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        conversation.conversationType = .group

        // then
        XCTAssertFalse(selfUser.canDeleteConversation(conversation))
    }

    func testThatGuestAccessControlInNonTeamConversationCantBeModified_ByAnyTeamMember() {
        // given
        makeSelfUserTeamMember(withPermissions: .modifyConversationMetaData)
        conversation.conversationType = .group
        createARoleForSelfUserWith("modify_conversation_access")
        conversation.teamRemoteIdentifier = nil
        conversation.team = nil

        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyGuestsAccessControlSettings(in: conversation))
    }

    // MARK: - Channel access level

    func testAccessOptionAllowed_ForChannel_andTeamAdmin() {
        makeSelfUserTeamMember(withPermissions: .modifyConversationMetaData)
        let adminUser = updateConversationToChannelWithUserToBecomeTeamAdmin()

        XCTAssertFalse(adminUser.canModifyChannelAccessLevelSettings(in: conversation))
        makeUserAdmin(adminUser)
        XCTAssertTrue(adminUser.canModifyChannelAccessLevelSettings(in: conversation))
    }

    func testAccessOptionNotAllowed_ForChannel_MemberButTeamOwnerFromOtherTeam() {
        makeSelfUserTeamMember(withPermissions: .modifyConversationMetaData)
        let adminUser = updateConversationToChannelWithUserToBecomeTeamAdmin()

        makeUserAdmin(adminUser)
        XCTAssertTrue(adminUser.canModifyChannelAccessLevelSettings(in: conversation))

        let team2 = Team.insertNewObject(in: uiMOC)
        team2.remoteIdentifier = .create()

        ModelHelper().addUser(adminUser, to: team2, in: uiMOC)
        makeUserAdmin(adminUser)
        XCTAssertFalse(adminUser.canModifyChannelAccessLevelSettings(in: conversation))
    }

    func testAccessOption_ForChannel_MemberNotTeamAdminButAssignedAdmin() {
        makeSelfUserTeamMember(withPermissions: .modifyConversationMetaData)
        let adminUser = updateConversationToChannelWithUserToBecomeTeamAdmin()

        makeUserAdmin(adminUser)
        XCTAssertTrue(adminUser.canModifyChannelAccessLevelSettings(in: conversation))

        let memberUserAssignedAsAdmin = createUserAndAddInConversation()
        XCTAssertFalse(memberUserAssignedAsAdmin.canModifyChannelAccessLevelSettings(in: conversation))

        let participantRole = ParticipantRole.create(
            managedObjectContext: uiMOC,
            user: memberUserAssignedAsAdmin,
            conversation: conversation
        )
        participantRole.role = makeAdminRole(actionName: ConversationAction.modifyAddPermission.name)
        memberUserAssignedAsAdmin.participantRoles = Set([participantRole])

        XCTAssertTrue(memberUserAssignedAsAdmin.canModifyChannelAccessLevelSettings(in: conversation))
    }

    // MARK: - Private

    private func makeAdminRole(actionName: String? = nil) -> Role {
        let adminRole = Role.insertNewObject(in: uiMOC)
        adminRole.name = defaultAdminRoleName
        if let actionName {
            let action = Action.insertNewObject(in: uiMOC)
            action.name = actionName
            adminRole.actions = Set([action])
        }
        return adminRole
    }

    private func createARole(user: ZMUser, actionName: String) {
        let participantRole = ParticipantRole.insertNewObject(in: uiMOC)
        participantRole.conversation = conversation
        participantRole.user = selfUser

        participantRole.role = makeAdminRole(actionName: actionName)

        user.participantRoles = Set([participantRole])
    }

    private func createARoleForSelfUserWith(_ actionName: String) {
        createARole(user: selfUser, actionName: actionName)
    }

    private func makeSelfUserTeamMember(withPermissions permissions: Permissions) {
        performPretendingUiMocIsSyncMoc {
            self.conversation.team = self.team
            self.conversation.teamRemoteIdentifier = self.team.remoteIdentifier
            let member = Member.getOrUpdateMember(for: self.selfUser, in: self.team, context: self.uiMOC)
            member.permissions = permissions
        }
    }

    private func createUserAndAddInConversation() -> ZMUser {
        let user = ModelHelper().createUser(qualifiedID: .random(), in: uiMOC)
        ModelHelper().addUser(user, to: team, in: uiMOC)
        conversation.addParticipantAndUpdateConversationState(user: user)
        return user
    }

    private func updateConversationToChannelWithUserToBecomeTeamAdmin() -> ZMUser {
        let adminUser = createUserAndAddInConversation()

        // just need one more user in conversation
        _ = createUserAndAddInConversation()

        // make sure to update conversation, because of potential force set of conversationType to OneOnOne when
        // conditions are met
        // see ZMConversation.m:439 '- (ZMConversationType)conversationType'
        conversation.groupType = .channel
        conversation.conversationType = .group

        return adminUser
    }

    func makeUserAdmin(_ user: ZMUser) {
        user.membership?.setTeamRole(.admin)
    }

    func makeUserOwner(_ user: ZMUser) {
        user.membership?.setTeamRole(.owner)
    }
}
