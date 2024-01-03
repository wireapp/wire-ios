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

        expectation(forNotification: AccountDeletedNotification.notificationName, object: nil) { wrappedNote in
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

        expectation(forNotification: AccountDeletedNotification.notificationName, object: nil) { wrappedNote in
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

    // MARK: - Team Update

    func testThatItUpdatesATeamsNameWhenReceivingATeamUpdateUpdateEvent() async {
        // given
        let dataPayload = ["name": "Wire GmbH"]

        // when
        guard let team = await assertThatItUpdatesTeamsProperties(with: dataPayload) else { return XCTFail("No Team") }

        // then
        XCTAssertEqual(team.name, "Wire GmbH")
    }

    func testThatItUpdatesATeamsIconWhenReceivingATeamUpdateUpdateEvent() async {
        // given
        let newAssetId = UUID.create().transportString()
        let dataPayload = ["icon": newAssetId]

        // when
        guard let team = await assertThatItUpdatesTeamsProperties(with: dataPayload) else { return XCTFail("No Team") }

        // then
        XCTAssertEqual(team.pictureAssetId, newAssetId)
    }

    func testThatItUpdatesATeamsIconKeyWhenReceivingATeamUpdateUpdateEvent() async {
        // given
        let newAssetKey = UUID.create().transportString()
        let dataPayload = ["icon_key": newAssetKey]

        // when
        guard let team = await assertThatItUpdatesTeamsProperties(with: dataPayload) else { return XCTFail("No Team") }

        // then
        XCTAssertEqual(team.pictureAssetKey, newAssetKey)
    }

    func assertThatItUpdatesTeamsProperties(
        with dataPayload: [String: Any]?,
        preExistingTeam: Bool = true,
        file: StaticString = #file,
        line: UInt = #line) async -> Team? {

            // given
            let teamId = UUID.create()

            if preExistingTeam {
                syncMOC.performGroupedBlock {
                    let team = Team.fetchOrCreate(with: teamId, create: true, in: self.syncMOC, created: nil)!
                    team.name = "Some Team"
                    team.remoteIdentifier = teamId
                    team.pictureAssetId = UUID.create().transportString()
                    team.pictureAssetKey = UUID.create().transportString()
                    XCTAssert(self.syncMOC.saveOrRollback())
                }

                XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1), file: file, line: line)
                XCTAssertNotNil(Team.fetchOrCreate(with: teamId, create: false, in: uiMOC, created: nil))
            }

            let payload: [String: Any] = [
                "type": "team.update",
                "team": teamId.transportString(),
                "time": Date().transportString(),
                "data": dataPayload ?? NSNull()
            ]

            // when
            await processEvent(fromPayload: payload)

            // then

            return uiMOC.performGroupedAndWait { context in Team.fetchOrCreate(with: teamId, create: false, in: context, created: nil) }
        }

    func testThatItDoesNotCreateATeamIfItDoesNotAlreadyExistWhenReceivingATeamUpdateUpdateEvent() async {
        // given
        let dataPayload = ["name": "Wire GmbH"]

        // then
        let result = await assertThatItUpdatesTeamsProperties(with: dataPayload, preExistingTeam: false)
        XCTAssertNil(result)
    }

    // TODO: consider re-adding these tests for conversation.member-leave with reason "user-deleted"

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
        uiMOC.performAndWait {
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
        await self.sut.processEvents([event], liveEvents: false, prefetchResult: nil)
        syncMOC.performGroupedBlock {
            XCTAssert(self.syncMOC.saveOrRollback(), file: file, line: line)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)
    }

}
