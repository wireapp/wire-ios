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
@testable import WireSyncEngine

final class TeamDownloadRequestStrategy_EventsTests: MessagingTest {

    var sut: TeamDownloadRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!
    var mockSyncStatus: MockSyncStatus!

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockSyncStatus = MockSyncStatus(
            managedObjectContext: syncMOC,
            lastEventIDRepository: lastEventIDRepository
        )
        sut = TeamDownloadRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: mockApplicationStatus, syncStatus: mockSyncStatus)

        syncMOC.performGroupedBlockAndWait {
            let user = ZMUser.selfUser(in: self.syncMOC)
            user.remoteIdentifier = self.userIdentifier
            self.syncMOC.saveOrRollback()
        }
    }

    override func tearDown() {
        mockApplicationStatus = nil
        mockSyncStatus = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Team Create
    // The team.create update event is only sent to the creator of the team

    func testThatItDoesNotCreateALocalTeamWhenReceivingTeamCreateUpdateEvent() async {
        // given
        let teamId = UUID.create()
        let payload: [String: Any] = [
            "type": "team.create",
            "team": teamId.transportString(),
            "time": Date().transportString(),
            "data": NSNull()
        ]

        // when
        await processEvent(fromPayload: payload)

        // then
        XCTAssertNil(Team.fetchOrCreate(with: teamId, create: false, in: uiMOC, created: nil))
    }

    func testThatItDoesNotSetNeedsToBeUpdatedFromBackendForExistingTeamWhenReceivingTeamCreateUpdateEvent() async {
        // given
        let teamId = UUID.create()

        syncMOC.performGroupedBlock {
            _ = Team.fetchOrCreate(with: teamId, create: true, in: self.syncMOC, created: nil)
            XCTAssert(self.syncMOC.saveOrRollback())
        }

        let payload: [String: Any] = [
            "type": "team.create",
            "team": teamId.transportString(),
            "time": Date().transportString(),
            "data": NSNull()
        ]

        // when
        await processEvent(fromPayload: payload)

        // then
        guard let team = Team.fetchOrCreate(with: teamId, create: false, in: uiMOC, created: nil) else { return XCTFail("No team created") }
        XCTAssertFalse(team.needsToBeUpdatedFromBackend)
    }

    // MARK: - Team Delete

    func testThatRequestAccountDeletionWhenReceivingATeamDeleteUpdateEvent() async {
        // given
        let teamId = UUID.create()

        syncMOC.performGroupedBlock {
            _ = Team.fetchOrCreate(with: teamId, create: true, in: self.syncMOC, created: nil)
            XCTAssert(self.syncMOC.saveOrRollback())
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertNotNil(Team.fetch(with: teamId, in: uiMOC))

        let payload: [String: Any] = [
            "type": "team.delete",
            "team": teamId.transportString(),
            "time": Date().transportString(),
            "data": NSNull()
        ]

        customExpectation(forNotification: AccountDeletedNotification.notificationName, object: nil) { wrappedNote in
            guard
                (wrappedNote.userInfo?[AccountDeletedNotification.userInfoKey] as? AccountDeletedNotification) != nil
            else {
                return false
            }
            return true
        }

        // when
        await processEvent(fromPayload: payload)

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItRequestAccountDeletionWhenReceivingATeamDeleteUpdateEvent() async {
        // given
        let conversationId = UUID.create()
        let teamId = UUID.create()

        syncMOC.performGroupedBlock {
            let team = Team.fetchOrCreate(with: teamId, create: true, in: self.syncMOC, created: nil)
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = conversationId
            conversation.team = team
            XCTAssert(self.syncMOC.saveOrRollback())
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        XCTAssertNotNil(Team.fetch(with: teamId, in: uiMOC))

        let payload: [String: Any] = [
            "type": "team.delete",
            "team": teamId.transportString(),
            "time": Date().transportString(),
            "data": NSNull()
        ]

        customExpectation(forNotification: AccountDeletedNotification.notificationName, object: nil) { wrappedNote in
            guard
                (wrappedNote.userInfo?[AccountDeletedNotification.userInfoKey] as? AccountDeletedNotification) != nil
            else {
                return false
            }
            return true
        }

        // when
        await processEvent(fromPayload: payload)

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: - Team Member-Leave

    func testThatItDeletesAMemberWhenReceivingATeamMemberLeaveUpdateEventForAnotherUser() async {
        // given
        let teamId = UUID.create()
        let userId = UUID.create()

        syncMOC.performGroupedBlock {
            let user = ZMUser.insertNewObject(in: self.syncMOC)
            user.remoteIdentifier = userId
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = teamId
            let member = Member.getOrCreateMember(for: user, in: team, context: self.syncMOC)
            XCTAssertNotNil(member)
            XCTAssertEqual(user.membership, member)
            XCTAssert(self.syncMOC.saveOrRollback())
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        let payload: [String: Any] = [
            "type": "team.member-leave",
            "team": teamId.transportString(),
            "time": Date().transportString(),
            "data": ["user": userId.transportString()]
        ]

        // when
        await processEvent(fromPayload: payload)

        // then
        syncMOC.performGroupedBlockAndWait {
            XCTAssertNotNil(ZMUser.fetch(with: userId, in: self.syncMOC))

            // users won't be deleted as we might be in other (non-team) conversations with them
            guard let team = Team.fetch(with: teamId, in: self.syncMOC) else { return XCTFail("No team") }
            XCTAssertEqual(team.members, [])
        }
    }

    func testThatItRequestAccountDeletionWhenReceivingATeamMemberLeaveUpdateEventForSelfUser() async {
        let teamId = UUID.create()
        var userId: UUID!

        syncMOC.performGroupedBlockAndWait {
            // given
            let user = ZMUser.selfUser(in: self.syncMOC)
            userId = user.remoteIdentifier!
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = teamId
            let member = Member.getOrCreateMember(for: user, in: team, context: self.syncMOC)
            XCTAssertNotNil(member)
            XCTAssertEqual(user.membership, member)
        }

        // expect
        customExpectation(forNotification: AccountDeletedNotification.notificationName, object: nil) { wrappedNote in
            guard
                (wrappedNote.userInfo?[AccountDeletedNotification.userInfoKey] as? AccountDeletedNotification) != nil
            else {
                return false
            }
            return true
        }

        // when
        let payload: [String: Any] = [
            "type": "team.member-leave",
            "team": teamId.transportString(),
            "time": Date().transportString(),
            "data": ["user": userId.transportString()]
        ]
        await processEvent(fromPayload: payload)

        // then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItRemovesAMemberFromAllGroupConversationsSheWasPartOfWhenReceivingAMemberLeaveForThatMember() async {
        let teamId = UUID.create()
        let teamConversationId = UUID.create(), conversationId = UUID.create()
        let userId = UUID.create()

        syncMOC.performGroupedBlockAndWait {
            // given
            let user = ZMUser.insertNewObject(in: self.syncMOC)
            user.remoteIdentifier = userId
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = .create()
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = teamId
            let teamConversation1 = ZMConversation.insertNewObject(in: self.syncMOC)
            teamConversation1.remoteIdentifier = teamConversationId
            teamConversation1.conversationType = .group
            teamConversation1.addParticipantAndUpdateConversationState(user: user, role: nil)
            teamConversation1.team = team
            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: [user, otherUser])
            conversation?.remoteIdentifier = conversationId
            let member = Member.getOrCreateMember(for: user, in: team, context: self.syncMOC)
            XCTAssertNotNil(member)
            XCTAssertEqual(user.membership, member)
        }

        // when
        let payload: [String: Any] = [
            "type": "team.member-leave",
            "team": teamId.transportString(),
            "time": Date().transportString(),
            "data": ["user": userId.transportString()]
        ]
        await processEvent(fromPayload: payload)

        // then
        syncMOC.performGroupedBlockAndWait {
            guard let user = ZMUser.fetch(with: userId, in: self.syncMOC) else { return XCTFail("No User") }
            guard Team.fetch(with: teamId, in: self.syncMOC) != nil else { return XCTFail("No User") }
            XCTAssertNil(user.membership)
            guard let teamConversation = ZMConversation.fetch(with: teamConversationId, in: self.syncMOC) else { return XCTFail("No Team Conversation") }
            guard let conversation = ZMConversation.fetch(with: conversationId, in: self.syncMOC) else { return XCTFail("No Conversation") }
            XCTAssertFalse(teamConversation.localParticipants.contains(user))
            XCTAssertFalse(conversation.localParticipants.contains(user))
        }
    }

    func testThatItAppendsASystemMessageToAllTeamConversationsSheWasPartOfWhenReceivingAMemberLeaveForThatMember() async {
        let teamId = UUID.create()
        let teamConversationId = UUID.create(), teamAnotherConversationId = UUID.create(), conversationId = UUID.create()
        let userId = UUID.create()

        syncMOC.performGroupedBlockAndWait {
            // given
            let user = ZMUser.insertNewObject(in: self.syncMOC)
            user.remoteIdentifier = userId
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = .create()

            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = teamId

            let teamConversation1 = ZMConversation.insertNewObject(in: self.syncMOC)
            teamConversation1.remoteIdentifier = teamConversationId
            teamConversation1.conversationType = .group
            teamConversation1.addParticipantAndUpdateConversationState(user: user, role: nil)
            teamConversation1.team = team

            let teamConversation2 = ZMConversation.insertNewObject(in: self.syncMOC)
            teamConversation2.remoteIdentifier = teamAnotherConversationId
            teamConversation2.conversationType = .group
            teamConversation2.addParticipantAndUpdateConversationState(user: user, role: nil)
            teamConversation2.team = team

            let conversation = ZMConversation.insertGroupConversation(moc: self.syncMOC, participants: [user, otherUser])
            conversation?.remoteIdentifier = conversationId
            let member = Member.getOrCreateMember(for: user, in: team, context: self.syncMOC)
            XCTAssertNotNil(member)
            XCTAssertEqual(user.membership, member)
        }

        // when
        let timestamp = Date(timeIntervalSinceNow: -30)
        let payload: [String: Any] = [
            "type": "team.member-leave",
            "team": teamId.transportString(),
            "time": timestamp.transportString(),
            "data": ["user": userId.transportString()]
        ]
        await processEvent(fromPayload: payload)

        // then
        syncMOC.performGroupedBlockAndWait {
            guard let user = ZMUser.fetch(with: userId, in: self.syncMOC) else { return XCTFail("No User") }
            guard Team.fetch(with: teamId, in: self.syncMOC) != nil else { return XCTFail("No User") }
            XCTAssertNil(user.membership)
            guard let teamConversation = ZMConversation.fetch(with: teamConversationId, in: self.syncMOC) else { return XCTFail("No Team Conversation") }
            guard let teamAnotherConversation = ZMConversation.fetch(with: teamAnotherConversationId, in: self.syncMOC) else { return XCTFail("No Team Conversation") }
            guard let conversation = ZMConversation.fetch(with: conversationId, in: self.syncMOC) else { return XCTFail("No Conversation") }

            self.checkLastMessage(in: teamConversation, isLeaveMessageFor: user, at: timestamp)
            self.checkLastMessage(in: teamAnotherConversation, isLeaveMessageFor: user, at: timestamp)

            if let lastMessage = conversation.lastMessage as? ZMSystemMessage, lastMessage.systemMessageType == .teamMemberLeave {
                XCTFail("Should not append leave message to regular conversation")
            }
        }
    }

    private func checkLastMessage(in conversation: ZMConversation, isLeaveMessageFor user: ZMUser, at timestamp: Date, file: StaticString = #file, line: UInt = #line) {
        guard let lastMessage = conversation.lastMessage as? ZMSystemMessage else { XCTFail("Last message is not system message", file: file, line: line); return }
        guard lastMessage.systemMessageType == .teamMemberLeave else { XCTFail("System message is not teamMemberLeave: but '\(lastMessage.systemMessageType.rawValue)'", file: file, line: line); return }
        guard let serverTimestamp = lastMessage.serverTimestamp else { XCTFail("System message should have timestamp", file: file, line: line); return }
        XCTAssertEqual(serverTimestamp.timeIntervalSince1970, timestamp.timeIntervalSince1970, accuracy: 0.1, file: file, line: line)
        return
    }

    // MARK: - Team Member-Update

    func testThatItFlagsAmemberTobeUpdatedFromTheBackendWhenReceivingTeamMemberUpdateEvent() async {
        // given
        let teamId = UUID.create()
        let userId = UUID.create()

        syncMOC.performGroupedBlock {
            let team = Team.fetchOrCreate(with: teamId, create: true, in: self.syncMOC, created: nil)!
            let user = ZMUser.fetchOrCreate(with: userId, domain: nil, in: self.syncMOC)
            user.needsToBeUpdatedFromBackend = false
            let member = Member.getOrCreateMember(for: user, in: team, context: self.syncMOC)
            member.needsToBeUpdatedFromBackend = false
            XCTAssert(self.syncMOC.saveOrRollback())
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        let payload: [String: Any] = [
            "type": "team.member-update",
            "team": teamId.transportString(),
            "time": Date().transportString(),
            "data": ["user": userId.transportString()]
        ]

        // when
        await processEvent(fromPayload: payload)

        // then
        await uiMOC.perform { [self] in
            guard let user = ZMUser.fetch(with: userId, in: uiMOC) else { return XCTFail("No user") }
            guard let team = Team.fetch(with: teamId, in: uiMOC) else { return XCTFail("No team") }
            guard let member = user.membership else { return XCTFail("No member") }

            XCTAssertFalse(user.needsToBeUpdatedFromBackend)
            XCTAssert(member.needsToBeUpdatedFromBackend)
            XCTAssertFalse(team.needsToBeUpdatedFromBackend)
            XCTAssertFalse(team.needsToRedownloadMembers)
            XCTAssertEqual(member.team, team)
        }
    }

    // MARK: - Team Conversation-Create

    func testThatItIgnoresTeamConversationCreateUpdateEvent() async {
        // given
        let conversationId = UUID.create()
        let teamId = UUID.create()

        syncMOC.performGroupedBlockAndWait {
            _ = Team.fetchOrCreate(with: teamId, create: true, in: self.syncMOC, created: nil)
        }

        let payload: [String: Any] = [
            "type": "team.conversation-create",
            "team": teamId.transportString(),
            "time": Date().transportString(),
            "data": ["conv": conversationId.transportString()]
        ]

        // when
        await processEvent(fromPayload: payload)

        // then
        syncMOC.performGroupedBlockAndWait {
            XCTAssertNil(ZMConversation.fetch(with: conversationId, in: self.syncMOC))
        }
    }

    // MARK: - Helper

    private func processEvent(fromPayload eventPayload: [String: Any], file: StaticString = #file, line: UInt = #line) async {
        guard let event = ZMUpdateEvent(fromEventStreamPayload: eventPayload as ZMTransportData, uuid: nil) else {
            return XCTFail("Unable to create update event from payload", file: file, line: line)
        }

        // when
        self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        syncMOC.performGroupedBlock {
            XCTAssert(self.syncMOC.saveOrRollback(), file: file, line: line)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)
    }

}
