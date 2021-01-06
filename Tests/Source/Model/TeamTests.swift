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

final class TeamTests: ZMConversationTestsBase {

    func testThatItCreatesANewTeamIfThereIsNone() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let uuid = UUID.create()
            var created = false

            withUnsafeMutablePointer(to: &created) {
                // when
                let sut = Team.fetchOrCreate(with: uuid, create: true, in: self.syncMOC, created: $0)

                // then
                XCTAssertNotNil(sut)
                XCTAssertEqual(sut?.remoteIdentifier, uuid)
            }
            XCTAssertTrue(created)
        }
    }

    func testThatItReturnsAnExistingTeamIfThereIsOne() {
        // given
        let sut = Team.insertNewObject(in: uiMOC)
        let uuid = UUID.create()
        sut.remoteIdentifier = uuid

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // when
        var created = false
        withUnsafeMutablePointer(to: &created) {
            let existing = Team.fetchOrCreate(with: uuid, create: false, in: uiMOC, created: $0)

            // then
            XCTAssertNotNil(existing)
            XCTAssertEqual(existing, sut)
        }
        XCTAssertFalse(created)
    }

    func testThatItReturnsGuestsOfATeam() throws {
        // given
        let (team, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)

        // we add actual team members as well
        createUserAndAddMember(to: team)
        createUserAndAddMember(to: team)

        // when
        let guest = ZMUser.insertNewObject(in: uiMOC)
        guard let conversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: [guest], team: team) else { XCTFail(); return }

        // then
        XCTAssertTrue(guest.isGuest(in: conversation))
        XCTAssertFalse(guest.isTeamMember)
    }
    
    func testThatItDoesNotReturnABotAsGuestOfATeam() throws {
        // given
        let (team, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)
        
        // we add an actual team member as well
        createUserAndAddMember(to: team)
        
        // when
        let guest = ZMUser.insertNewObject(in: uiMOC)
        let bot = ZMUser.insertNewObject(in: uiMOC)
        bot.serviceIdentifier = UUID.create().transportString()
        bot.providerIdentifier = UUID.create().transportString()
        XCTAssert(bot.isServiceUser)
        guard let conversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: [guest, bot], team: team) else { XCTFail(); return }
        
        // then
        XCTAssert(guest.isGuest(in: conversation))
        XCTAssertFalse(bot.isGuest(in: conversation))
        XCTAssertFalse(bot.isTeamMember)
    }

    func testThatItDoesNotReturnUsersAsGuestsIfThereIsNoTeam() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = .create()
        let otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser.remoteIdentifier = .create()
        let users = [user, otherUser]

        // when
        guard let conversation = ZMConversation.insertGroupConversation(moc: uiMOC, participants: users) else { return XCTFail("No conversation") }

        // then
        users.forEach {
            XCTAssertFalse($0.isGuest(in: conversation))
            XCTAssertFalse($0.isTeamMember)
        }
    }

    func testThatItDoesNotReturnGuestsOfOtherTeams() throws {
        // given
        let (team1, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)
        let (team2, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)

        // we add actual team members as well
        createUserAndAddMember(to: team1)
        let (otherUser, _) = createUserAndAddMember(to: team2)

        let guest = ZMUser.insertNewObject(in: uiMOC)

        // when
        guard let conversation1 = ZMConversation.insertGroupConversation(moc: uiMOC, participants: [guest], team: team1) else { XCTFail(); return }
        guard let conversation2 = ZMConversation.insertGroupConversation(moc: uiMOC, participants: [otherUser], team: team2) else { XCTFail(); return }

        // then
        XCTAssertTrue(guest.isGuest(in: conversation1))
        XCTAssertFalse(guest.isGuest(in: conversation2))
        XCTAssertFalse(otherUser.isGuest(in: conversation1))
        XCTAssertFalse(guest.isTeamMember)
        XCTAssertFalse(guest.isTeamMember)
    }

    func testThatItUpdatesATeamWithPayload() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let team = Team.insertNewObject(in: self.syncMOC)
            let userId = UUID.create()
            let assetId = UUID.create().transportString(), assetKey = UUID.create().transportString()

            let payload = [
                "name": "Wire GmbH",
                "creator": userId.transportString(),
                "icon": assetId,
                "icon_key": assetKey
            ]

            // when
            team.update(with: payload)

            // then
            XCTAssertEqual(team.creator?.remoteIdentifier, userId)
            XCTAssertEqual(team.name, "Wire GmbH")
            XCTAssertEqual(team.pictureAssetId, assetId)
            XCTAssertEqual(team.pictureAssetKey, assetKey)
        }
    }

    func testThatItUpdatesATeamWithPayloadAndMergesDuplicateCreators() {
        syncMOC.performGroupedBlockAndWait {
            // given
            let team = Team.insertNewObject(in: self.syncMOC)
            let userId = UUID.create()
            let user1 = ZMUser.insert(in: self.syncMOC, name: "Creator")
            user1.remoteIdentifier = userId
            let user2 = ZMUser.insert(in: self.syncMOC, name: "Creator")
            user2.remoteIdentifier = userId

            let assetId = UUID.create().transportString(), assetKey = UUID.create().transportString()

            let payload = [
                "name": "Wire GmbH",
                "creator": userId.transportString(),
                "icon": assetId,
                "icon_key": assetKey
            ]

            // when
            team.update(with: payload)

            // then
            XCTAssertEqual(team.creator?.remoteIdentifier, userId)
            XCTAssertEqual(team.name, "Wire GmbH")
            XCTAssertEqual(team.pictureAssetId, assetId)
            XCTAssertEqual(team.pictureAssetKey, assetKey)

            let afterMerge = ZMUser.fetchAll(with: userId, in: self.syncMOC)
            XCTAssertEqual(afterMerge.count, 1)
        }
    }

    
    func testThatMembersMatchingQueryReturnsMembersSortedAlphabeticallyByName() {
        // given
        let (team, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)
        
        // we add actual team members as well
        let (user1, member1) = createUserAndAddMember(to: team)
        let (user2, member2) = createUserAndAddMember(to: team)
        
        user1.name = "Abacus Allison"
        user2.name = "Zygfried Watson"
        
        // when
        let result = team.members(matchingQuery: "")
        
        // then
        XCTAssertEqual(result, [member1, member2])
    }
    
    func testThatMembersMatchingQueryReturnCorrectMember() {
        // given
        let (team, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)
        
        // we add actual team members as well
        let (user1, membership) = createUserAndAddMember(to: team)
        let (user2, _) = createUserAndAddMember(to: team)
        
        user1.name = "UserA"
        user2.name = "UserB"
        
        // when
        let result = team.members(matchingQuery: "userA")
        
        // then
        XCTAssertEqual(result, [membership])
    }
    
    func testThatMembersMatchingHandleReturnCorrectMember() {
        // given
        let (team, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)
        
        // we add actual team members as well
        let (user1, membership) = createUserAndAddMember(to: team)
        let (user2, _) = createUserAndAddMember(to: team)
        
        user1.name = "UserA"
        user1.setHandle("098")
        user2.name = "UserB"
        user2.setHandle("another")
        
        // when
        let result = team.members(matchingQuery: "098")
        
        // then
        XCTAssertEqual(result, [membership])
    }
    
    func testThatMembersMatchingQueryDoesNotReturnSelfUser() {
        // given
        let (team, _) = createTeamAndMember(for: .selfUser(in: uiMOC), with: .member)
        
        // we add actual team members as well"
        let (user1, membership) = createUserAndAddMember(to: team)
        
        user1.name = "UserA"
        selfUser.name = "UserB"
        
        // when
        let result = team.members(matchingQuery: "user")
        
        // then
        XCTAssertEqual(result, [membership])
    }

    // MARK: - Features

    func testItCreatesDefaultsUponFirstAccess() {
        let sut = createTeam(in: uiMOC)

        for name in Feature.Name.allCases {
            switch name {
            case .appLock:
                // Given
                XCTAssertNil(Feature.fetch(name: .appLock, context: uiMOC))

                // When
                let appLock1 = sut.feature(for: Feature.AppLock.self)

                // Then
                XCTAssertEqual(appLock1.status, .enabled)
                XCTAssertEqual(appLock1.config.enforceAppLock, false)
                XCTAssertEqual(appLock1.config.inactivityTimeoutSecs, 60)
            }
        }
    }

    func testItEnqueuesBackendRefreshForFeature_WhenFeatureExistsInCoreData() {
        // Given
        let sut = createTeam(in: uiMOC)

        let feature = Feature.createOrUpdate(
            name: .appLock,
            status: .enabled,
            config: nil,
            team: sut,
            context: uiMOC
        )

        XCTAssertFalse(feature.needsToBeUpdatedFromBackend)

        // When
        sut.enqueueBackendRefresh(for: .appLock)

        // Then
        XCTAssertTrue(feature.needsToBeUpdatedFromBackend)
    }
    
    func testItEnqueuesBackendRefreshForFeature_WhenThereIsNoFeatureInCoreData() {
        // Given
        let sut = createTeam(in: uiMOC)
        XCTAssertNil(Feature.fetch(name: .appLock, context: uiMOC))
        
        // When
        sut.enqueueBackendRefresh(for: .appLock)

        // Then
        guard let feature = Feature.fetch(name: .appLock, context: uiMOC) else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(feature.needsToBeUpdatedFromBackend)
    }
    
}
