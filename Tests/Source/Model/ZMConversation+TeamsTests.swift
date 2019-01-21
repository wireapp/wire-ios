//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


import WireTesting
@testable import WireDataModel


class ZMConversationTests_Teams: BaseTeamTests {

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

    func testThatItDoesNotReportIsGuestForANonTeamConversation() {
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).isGuest(in: conversation))
    }

    func testThatItDoesNotReportIsGuestForATeamConversation() {
        // given
        conversation.team = team
        conversation.teamRemoteIdentifier = team.remoteIdentifier

        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).isGuest(in: conversation))
    }

    func testThatItReportsIsGuestWhenAConversationDoesNotHaveATeam() {
        // given
        conversation.teamRemoteIdentifier = team.remoteIdentifier

        // then
        XCTAssert(ZMUser.selfUser(in: uiMOC).isGuest(in: conversation))
    }

    func testThatAUserCanAddUsersToAConversationWithoutTeamAndWithoutTeamRemoteIdentifier() {
        // when & then
        XCTAssert(ZMUser.selfUser(in: uiMOC).canAddUser(to: conversation))
    }

    func testThatAUserCantAddUsersToAConversationWhereHeIsGuest() {
        // when
        conversation.teamRemoteIdentifier = team.remoteIdentifier

        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canAddUser(to: conversation))
    }

    func testThatAUserCantAddUsersToAConversationWhereHeIsNotAnActiveMember() {
        // when
        conversation.isSelfAnActiveMember = false

        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canAddUser(to: conversation))
    }

    func testThatAUserCantAddUsersToAConversationWhereHeIsMemberWithUnsufficientPermissions() {
        self.performPretendingUiMocIsSyncMoc {
            // when
            let selfUser = ZMUser.selfUser(in: self.uiMOC)
            let member = Member.getOrCreateMember(for: selfUser, in: self.team, context: self.uiMOC)
            member.permissions = Permissions.none
            self.conversation.team = self.team
            
            // then
            XCTAssertFalse(selfUser.canAddUser(to: self.conversation))
        }
    }

    func testThatAUserCanAddUsersToAConversationWhereHeIsMemberWithSufficientPermissions() {
        self.performPretendingUiMocIsSyncMoc {
            // when
            self.conversation.team = self.team
            let selfUser = ZMUser.selfUser(in: self.uiMOC)
            let member = Member.getOrCreateMember(for: selfUser, in: self.team, context: self.uiMOC)
            member.permissions = .member
            
            // then
            XCTAssert(selfUser.canAddUser(to: self.conversation))
        }
    }

    func testThatAUserCanRemoveUsersToAConversationWithoutTeamAndWithoutTeamRemoteIdentifier() {
        // when & then
        XCTAssert(ZMUser.selfUser(in: uiMOC).canRemoveUser(from: conversation))
    }

    func testThatAUserCantRemoveUsersToAConversationWhereHeIsGuest() {
        // when
        conversation.teamRemoteIdentifier = team.remoteIdentifier

        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canRemoveUser(from: conversation))
    }

    func testThatAUserCantRemoveUsersToAConversationWhereHeIsNotAnActiveMember() {
        // when
        conversation.isSelfAnActiveMember = false

        // then
        XCTAssertFalse(ZMUser.selfUser(in: uiMOC).canRemoveUser(from: conversation))
    }

    func testThatAUserCantRemoveUsersToAConversationWhereHeIsMemberWithUnsufficientPermissions() {
        self.performPretendingUiMocIsSyncMoc {
            // when
            let selfUser = ZMUser.selfUser(in: self.uiMOC)
            let member = Member.getOrCreateMember(for: selfUser, in: self.team, context: self.uiMOC)
            member.permissions = Permissions.none
            self.conversation.team = self.team
            
            // then
            XCTAssertFalse(selfUser.canRemoveUser(from: self.conversation))
        }
    }

    func testThatAUserCanRemoveUsersToAConversationWhereHeIsMemberWithSufficientPermissions() {
        self.performPretendingUiMocIsSyncMoc {
            // when
            self.conversation.team = self.team
            let selfUser = ZMUser.selfUser(in: self.uiMOC)
            let member = Member.getOrCreateMember(for: self.selfUser, in: self.team, context: self.uiMOC)
            member.permissions = .member
            
            // then
            XCTAssert(selfUser.canRemoveUser(from: self.conversation))
        }
    }

    func testThatItSetsTheConversationTeamRemoteIdentifierWhenUpdatingWithTransportData() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = .create()
        let teamId = UUID.create()
        let payload = payloadForConversationMetaData(conversation, activeUsers: [user], teamId: teamId)

        // when
        performPretendingUiMocIsSyncMoc {
            self.conversation.update(withTransportData: payload, serverTimeStamp: nil)
        }

        // then
        XCTAssertNil(Team.fetch(withRemoteIdentifier: teamId, in: uiMOC))
        XCTAssertNotNil(conversation.teamRemoteIdentifier)
        XCTAssertEqual(conversation.teamRemoteIdentifier, teamId)
        XCTAssert(ZMUser.selfUser(in: uiMOC).isGuest(in: conversation))
    }

    // MARK: - Helper

    private func payloadForConversationMetaData(_ conversation: ZMConversation, activeUsers: [ZMUser], teamId: UUID?) -> [String: Any] {
        var payload: [String: Any] = [
            "name": NSNull(),
            "type": NSNumber(value: ZMBackendConversationType.convTypeGroup.rawValue),
            "id": conversation.remoteIdentifier!.transportString(),
            "creator": UUID.create(),
            "members": [
                "others": activeUsers.map { ["id": $0.remoteIdentifier!.transportString()] },
                "self": [
                    "id": "3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                    "otr_archived": NSNumber(value: 0),
                    "otr_archived_ref": NSNull(),
                    "otr_muted": NSNumber(value: 0),
                    "otr_muted_ref": NSNull()
                ]
            ]
        ]

        if let teamId = teamId {
            payload["team"] = teamId
        } else {
            payload["team"] = NSNull()
        }

        return payload
    }

}
