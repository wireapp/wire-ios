//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

// MARK: - ConversationTests_Teams

final class ConversationTests_Teams: ZMConversationTestsBase {
    var team: Team!
    var user: ZMUser!
    var member: Member!
    var otherUser: ZMUser!

    override func setUp() {
        super.setUp()

        user = .selfUser(in: uiMOC)
        team = .insertNewObject(in: uiMOC)
        member = .insertNewObject(in: uiMOC)
        otherUser = .insertNewObject(in: uiMOC)
        member.user = user
        member.team = team
        member.permissions = .member

        let otherUserMember = Member.insertNewObject(in: uiMOC)
        otherUserMember.team = team
        otherUserMember.user = otherUser

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
    }

    override func tearDown() {
        team = nil
        user = nil
        member = nil
        otherUser = nil
        super.tearDown()
    }

    func testThatItReturnsNotNilWhenAskedForOneOnOneConversationWithoutTeam() {
        // given
        let oneOnOne = ZMConversation.insertNewObject(in: uiMOC)
        oneOnOne.conversationType = .oneOnOne

        let userOutsideTeam = ZMUser.insertNewObject(in: uiMOC)
        userOutsideTeam.connection = ZMConnection.insertNewObject(in: uiMOC)
        userOutsideTeam.connection?.status = .accepted
        userOutsideTeam.oneOnOneConversation = oneOnOne

        // then
        XCTAssertEqual(userOutsideTeam.oneToOneConversation, oneOnOne)
    }

    func testThatItCreatesAConversationWithMultipleParticipantsInATeam() {
        // given
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        let user2 = ZMUser.insertNewObject(in: uiMOC)

        // when
        let conversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: [user1, user2], team: team)

        // then
        XCTAssertNotNil(conversation)
        XCTAssertEqual(conversation?.conversationType, .group)
        XCTAssertEqual(conversation?.localParticipants, [user1, user2, .selfUser(in: uiMOC)])
        XCTAssertEqual(conversation?.team, team)
    }

    func testThatItCreatesAConversationWithOnlyAGuest() {
        // given
        let (team, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)
        let guest = ZMUser.insertNewObject(in: uiMOC)

        // when
        let conversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: [guest], team: team)
        XCTAssertNotNil(conversation)
    }

    func testThatItCreatesAConversationWithAnotherMember() {
        // given
        let (team, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)
        let otherUser = ZMUser.insertNewObject(in: uiMOC)
        let otherMember = Member.insertNewObject(in: uiMOC)
        otherMember.team = team
        otherMember.user = otherUser

        // when
        let conversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: [otherUser], team: team)
        XCTAssertNotNil(conversation)
        XCTAssertEqual(conversation?.localParticipants, [otherUser, .selfUser(in: uiMOC)])
        XCTAssertTrue(otherUser.isTeamMember)
        XCTAssertEqual(conversation?.team, team)
    }
}

// MARK: - System messages

extension ConversationTests_Teams {
    func testThatItCreatesSystemMessageWithTeamMemberLeave() {
        // given
        let (team, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)
        let otherUser = ZMUser.insertNewObject(in: uiMOC)
        let otherMember = Member.insertNewObject(in: uiMOC)
        otherMember.team = team
        otherMember.user = otherUser
        let conversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: [otherUser], team: team)!
        let previousLastModifiedDate = conversation.lastModifiedDate!
        let timestamp = Date(timeIntervalSinceNow: 100)

        // when
        conversation.appendTeamMemberRemovedSystemMessage(user: otherUser, at: timestamp)

        // then
        guard let message = conversation.lastMessage as? ZMSystemMessage
        else {
            XCTFail("Last message should be system message"); return
        }

        XCTAssertEqual(message.systemMessageType, .teamMemberLeave)
        XCTAssertEqual(message.sender, otherUser)
        XCTAssertEqual(message.users, [otherUser])
        XCTAssertEqual(message.serverTimestamp, timestamp)
        XCTAssertFalse(message.shouldGenerateUnreadCount())
        XCTAssertEqual(
            conversation.lastModifiedDate,
            previousLastModifiedDate,
            "Message should not change lastModifiedDate"
        )
    }
}
