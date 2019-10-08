//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

import XCTest

class ZMUserTests_Permissions: ModelObjectsTests {
    
    var team: Team!
    var conversation: ZMConversation!
    
    override func setUp() {
        super.setUp()
        team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = .create()
        conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
    }
    
    override func tearDown() {
        team = nil
        conversation = nil
        super.tearDown()
    }
    
    func makeSelfUserTeamMember(withPermissions permissions: Permissions) {
        self.performPretendingUiMocIsSyncMoc {
            self.conversation.team = self.team
            self.conversation.teamRemoteIdentifier = self.team.remoteIdentifier
            let member = Member.getOrCreateMember(for: self.selfUser, in: self.team, context: self.uiMOC)
            member.permissions = permissions
        }
    }
    
    // MARK: Adding & Removing services
    
    func testThatUserCantAddOrRemoveServicesToAConversation_ByNonTeamUser() {
        // when & then
        XCTAssert(ZMUser.selfUser(in: uiMOC).canAddUser(to: conversation))
    }
    
    func testThatUserCantAddOrRemoveServicesToAConversation_ByGuest() {
        // when
        conversation.teamRemoteIdentifier = team.remoteIdentifier
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canAddUser(to: conversation))
    }
    
    func testThatUserCantAddOrRemoveServicesToAConversation_ByInactiveParticipant() {
        // when
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        conversation.isSelfAnActiveMember = false
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canAddUser(to: conversation))
    }
    
    func testThatUserCantAddOrRemoveServicesToAConversation_ByATeamMemberWithInsufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: Permissions.admin.subtracting(.addRemoveConversationMember))
        
        // then
        XCTAssertFalse(selfUser.canAddUser(to: self.conversation))
    }
    
    func testThatUserCanAddOrRemoveServicesToAConversation_ByATeamMemberWithSufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        
        // then
        XCTAssertTrue(selfUser.canAddUser(to: self.conversation))
    }

    // MARK: Adding & Rmoving users
    
    func testThatUserCanAddOrRemoveUsersToAConversation_ByNonTeamUser() {
        // when & then
        XCTAssert(ZMUser.selfUser(in: uiMOC).canAddUser(to: conversation))
    }
    
    func testThatUserCantAddOrRemoveUsersToAConversation_ByGuest() {
        // when
        conversation.teamRemoteIdentifier = team.remoteIdentifier
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canAddUser(to: conversation))
    }
    
    func testThatUserCantAddOrRemoveUsersToAConversation_ByInactiveParticipant() {
        // when
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        conversation.isSelfAnActiveMember = false
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canAddUser(to: conversation))
    }
    
    func testThatUserCantAddOrRemoveUsersToAConversation_ByATeamMemberWithInsufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: Permissions.admin.subtracting(.addRemoveConversationMember))
        
        // then
        XCTAssertFalse(selfUser.canAddUser(to: self.conversation))
    }
    
    func testThatUserCanAddOrRemoveUsersToAConversation_ByATeamMemberWithSufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: .addRemoveConversationMember)
        
        // then
        XCTAssertTrue(selfUser.canAddUser(to: self.conversation))
    }
    
    // MARK: Deleting conversation
    
    func testThatConversationCanBeDeleted_ByItsCreator() {
        // when
        makeSelfUserTeamMember(withPermissions: .member)
        conversation.creator = selfUser
        
        // then
        XCTAssertTrue(ZMUser.selfUser(in: uiMOC).canDeleteConversation(conversation))
    }
    
    func testThatConversationCantBeDeleted_ByItsCreatorIfNotAnActiveParticipant() {
        // when
        makeSelfUserTeamMember(withPermissions: .member)
        conversation.isSelfAnActiveMember = false
        conversation.creator = selfUser
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canDeleteConversation(conversation))
    }
    
    func testThatConversationCantBeDeleted_ByItsCreatorIfANonTeamConversation() {
        // when
        makeSelfUserTeamMember(withPermissions: .member)
        conversation.creator = selfUser
        conversation.teamRemoteIdentifier = nil
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canDeleteConversation(conversation))
    }
    
    // MARK: Guests
    
    func testThatItDoesNotReportIsGuest_ForANonTeamConversation() {
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).isGuest(in: conversation))
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
    
    func testThatConversationCanBeCreated_ByNonTeamUser() {
        XCTAssertTrue(selfUser.canCreateConversation)
    }
    
    func testThatConversationCanBeCreated_ByTeamMemberWithSufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: .member)
        
        // then
        XCTAssertTrue(selfUser.canCreateConversation)
    }
    
    func testThatConversationCantBeCreated_ByTeamMemberWithInsufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: .partner)
        
        // then
        XCTAssertFalse(selfUser.canCreateConversation)
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
    
    // MARK: Read Receipts Setting
    
    func testThatReadReceiptSettingsCantBeModified_ByNonTeamMember() {
        // when & then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyReadReceiptSettings(in: conversation))
    }
    
    func testThatReadReceiptSettingsCantBeModified_ByGuest() {
        // given
        conversation.teamRemoteIdentifier = UUID()
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyReadReceiptSettings(in: conversation))
    }
    
    func testThatReadReceiptSettingsCanBeModified_ByTeamMemberWithSufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: .modifyConversationMetaData)
        
        // then
        XCTAssertTrue(ZMUser.selfUser(in: uiMOC).canModifyReadReceiptSettings(in: conversation))
    }
    
    func testThatReadReceiptSettingsCantBeModified_ByTeamMemberWithInsufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: Permissions.admin.subtracting(.modifyConversationMetaData))
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyReadReceiptSettings(in: conversation))
    }
    
    func testThatReadReceiptSettingsCantBeModified_ByInactiveParticipant() {
        // given
        conversation.isSelfAnActiveMember = false
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyReadReceiptSettings(in: conversation))
    }
    
    // MARK: Ephermeral Setting
    
    func testThatEphemeralSettingsCanBeModified_ByActiveParticipant() {
        // when & then
        XCTAssertTrue(ZMUser.selfUser(in: uiMOC).canModifyEphemeralSettings(in: conversation))
    }
    
    func testThatEphemeralSettingsCantBeModified_ByGuest() {
        // given
        conversation.teamRemoteIdentifier = UUID()
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyEphemeralSettings(in: conversation))
    }
    
    func testThatEphemeralSettingsCanBeModified_ByTeamGuest() {
        // given
        makeSelfUserTeamMember(withPermissions: .modifyConversationMetaData)
        conversation.teamRemoteIdentifier = nil
        
        // then
        XCTAssertTrue(ZMUser.selfUser(in: uiMOC).canModifyEphemeralSettings(in: conversation))
    }
    
    func testThatEphemeralSettingsCanBeModified_ByTeamMemberWithSufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: .modifyConversationMetaData)
        
        // then
        XCTAssertTrue(ZMUser.selfUser(in: uiMOC).canModifyEphemeralSettings(in: conversation))
    }
    
    func testThatEphemeralSettingsCantBeModified_ByTeamMemberWithInsufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: Permissions.admin.subtracting(.modifyConversationMetaData))
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyEphemeralSettings(in: conversation))
    }
    
    func testThatEphemeralSettingsCantBeModified_ByInactiveParticipant() {
        // given
        conversation.isSelfAnActiveMember = false
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyEphemeralSettings(in: conversation))
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
        conversation.isSelfAnActiveMember = false
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyNotificationSettings(in: conversation))
    }
    
    // MARK: Access Control
    
    func testThatConversationAccessControlCanBeModified_ByTeamMemberWithSufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: .modifyConversationMetaData)
        conversation.conversationType = .group
        
        // then
        XCTAssertTrue(ZMUser.selfUser(in: uiMOC).canModifyAccessControlSettings(in: conversation))
    }
    
    func testThatConversationAccessControlCantBeModified_ByNonTeamMember() {
        // when & then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyAccessControlSettings(in: conversation))
    }
    
    func testThatConversationAccessControlCantBeModified_ByGuest() {
        // given
        conversation.teamRemoteIdentifier = UUID()
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyAccessControlSettings(in: conversation))
    }
    
    func testThatConversationAccessControlCantBeModified_ByTeamMemberWithInsufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: Permissions.admin.subtracting(.modifyConversationMetaData))
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyAccessControlSettings(in: conversation))
    }
    
    func testThatConversationAccessControlCantBeModified_ByInactiveParticipant() {
        // given
        conversation.isSelfAnActiveMember = false
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyAccessControlSettings(in: conversation))
    }
    
    // MARK: Conversation Title
    
    func testThatConversationTitleCanBeModified_ByActiveParticipant() {
        // when & then
        XCTAssertTrue(ZMUser.selfUser(in: uiMOC).canModifyTitle(in: conversation))
    }
    
    func testThatConversationTitleCanBeModified_ByGuest() {
        // given
        conversation.teamRemoteIdentifier = UUID()
        
        // then
        XCTAssertTrue(ZMUser.selfUser(in: uiMOC).canModifyTitle(in: conversation))
    }
    
    func testThatConversationTitleCanBeModified_ByTeamMemberWithSufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: .modifyConversationMetaData)
        
        // then
        XCTAssertTrue(ZMUser.selfUser(in: uiMOC).canModifyTitle(in: conversation))
    }
    
    func testThatConversationTitleCantBeModified_ByTeamMemberWithInsufficientPermissions() {
        // given
        makeSelfUserTeamMember(withPermissions: Permissions.admin.subtracting(.modifyConversationMetaData))
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyTitle(in: conversation))
    }
    
    func testThatConversationTitleCantBeModified_ByInactiveParticipant() {
        // given
        conversation.isSelfAnActiveMember = false
        
        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canModifyTitle(in: conversation))
    }
}
