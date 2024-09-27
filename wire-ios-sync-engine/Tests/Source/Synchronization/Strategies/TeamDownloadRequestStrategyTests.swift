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

final class TeamDownloadRequestStrategyTests: MessagingTest {
    // MARK: Internal

    var sut: TeamDownloadRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!
    var mockSyncStatus: MockSyncStatus!
    let teamID = UUID.create()

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockSyncStatus = MockSyncStatus(
            managedObjectContext: syncMOC,
            lastEventIDRepository: lastEventIDRepository
        )
        sut = TeamDownloadRequestStrategy(
            withManagedObjectContext: syncMOC,
            applicationStatus: mockApplicationStatus,
            syncStatus: mockSyncStatus
        )

        syncMOC.performGroupedAndWait {
            let user = ZMUser.selfUser(in: self.syncMOC)
            user.remoteIdentifier = UUID()
            user.teamIdentifier = self.teamID
        }
    }

    override func tearDown() {
        mockApplicationStatus = nil
        mockSyncStatus = nil
        sut = nil
        super.tearDown()
    }

    func sampleResponse(team: Team, creatorId: UUID, isBound: Bool = true) -> [String: Any] {
        sampleResponse(
            teamID: team.remoteIdentifier!,
            creatorId: creatorId,
            isBound: isBound
        )
    }

    func sampleResponse(teamID: UUID, creatorId: UUID, isBound: Bool = true) -> [String: Any] {
        [
            "id": teamID.transportString(),
            "creator": creatorId.transportString(),
            "name": "Wire GmbH",
            "icon": "",
            "icon_key": "",
            "binding": isBound ? true : false,
        ]
    }

    // MARK: Incremental Sync

    func testThatPredicateIsCorrect() {
        // given
        syncMOC.performAndWait {
            let team1 = Team.insertNewObject(in: self.syncMOC)
            team1.remoteIdentifier = .create()
            team1.needsToBeUpdatedFromBackend = true

            let team2 = Team.insertNewObject(in: self.syncMOC)
            team2.remoteIdentifier = .create()
            team2.needsToBeUpdatedFromBackend = false

            // then
            XCTAssertTrue(sut.downstreamSync.predicateForObjectsToDownload.evaluate(with: team1))
            XCTAssertFalse(sut.downstreamSync.predicateForObjectsToDownload.evaluate(with: team2))
        }
    }

    func testThatItDoesNotGenerateARequestInitially() {
        XCTAssertNil(sut.nextRequest(for: .v0))
    }

    func testThatItDoesNotCreateARequestIfThereIsNoTeamNeedingToBeUpdated() {
        syncMOC.performGroupedAndWait {
            // given
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = .create()
            self.mockApplicationStatus.mockSynchronizationState = .online

            // when
            team.needsToBeUpdatedFromBackend = false
            self.boostrapChangeTrackers(with: team)

            // then
            XCTAssertNil(self.sut.nextRequest(for: .v0))
        }
    }

    func testThatItCreatesAReuqestForATeamThatNeedsToBeUpdatedFromTheBackend() {
        syncMOC.performGroupedAndWait {
            // given
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = .create()
            self.mockApplicationStatus.mockSynchronizationState = .online

            // when
            team.needsToBeUpdatedFromBackend = true
            self.boostrapChangeTrackers(with: team)

            // then
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(request.path, "/teams/\(team.remoteIdentifier!.transportString())")
        }
    }

    func testThatItUpdatesTheTeamWithTheResponse() {
        var team: Team!
        let creatorId = UUID.create()

        syncMOC.performGroupedBlock {
            // given
            team = Team.insertNewObject(in: self.syncMOC)
            self.mockApplicationStatus.mockSynchronizationState = .online
            team.remoteIdentifier = .create()

            team.needsToBeUpdatedFromBackend = true
            self.boostrapChangeTrackers(with: team)
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }

            // when
            let payload = self.sampleResponse(team: team, creatorId: creatorId)
            let response = ZMTransportResponse(
                payload: payload as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            // when
            request.complete(with: response)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertFalse(team.needsToBeUpdatedFromBackend)
            XCTAssertEqual(team.name, "Wire GmbH")
            guard let creator = team.creator else { return XCTFail("No creator") }
            XCTAssertEqual(creator.remoteIdentifier, creatorId)
            XCTAssertTrue(creator.needsToBeUpdatedFromBackend)
        }
    }

    func testThatItDeletesTheTeamIfNotBoundToAccount() {
        var team: Team!
        let creatorId = UUID.create()

        syncMOC.performGroupedBlock {
            // given
            team = Team.insertNewObject(in: self.syncMOC)
            self.mockApplicationStatus.mockSynchronizationState = .online
            team.remoteIdentifier = .create()

            team.needsToBeUpdatedFromBackend = true
            self.boostrapChangeTrackers(with: team)
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }

            // when
            let payload = self.sampleResponse(team: team, creatorId: creatorId, isBound: false)
            let response = ZMTransportResponse(
                payload: payload as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            // when
            request.complete(with: response)
            self.syncMOC.saveOrRollback()
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertTrue(team == nil || team.isZombieObject)
        }
    }

    func testThatItCreatesNoNewRequestAfterReceivingAResponse() {
        var team: Team!

        syncMOC.performGroupedBlock {
            // given
            team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = .create()
            team.needsToBeUpdatedFromBackend = true
            self.mockApplicationStatus.mockSynchronizationState = .online
            self.boostrapChangeTrackers(with: team)

            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }

            // when
            let payload = self.sampleResponse(team: team, creatorId: UUID(), isBound: false)
            let response = ZMTransportResponse(
                payload: payload as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )
            request.complete(with: response)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedAndWait {
            // then
            self.boostrapChangeTrackers(with: team)
            XCTAssertNil(self.sut.nextRequestIfAllowed(for: .v0))
        }
    }

    func testThatItDeletesALocalTeamWhenReceivingA403() {
        let teamId = UUID.create()
        let conversationId = UUID.create()

        syncMOC.performGroupedBlock {
            // given
            let team = Team.insertNewObject(in: self.syncMOC)
            self.mockApplicationStatus.mockSynchronizationState = .online
            team.remoteIdentifier = teamId
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = conversationId
            conversation.team = team
            conversation.teamRemoteIdentifier = teamId

            team.needsToBeUpdatedFromBackend = true
            self.boostrapChangeTrackers(with: team)
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }

            // when
            let response = ZMTransportResponse(
                payload: ["label": "no-team"] as ZMTransportData,
                httpStatus: 403,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            // when
            request.complete(with: response)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertNil(Team.fetch(with: teamId, in: self.syncMOC))
            XCTAssertNotNil(ZMConversation.fetch(with: conversationId, in: self.syncMOC))
        }
    }

    func testThatItDeletesALocalTeamButNotItsConversationsWhenReceivingA403_Guest() {
        let teamId = UUID.create()
        let conversationId = UUID.create()

        syncMOC.performGroupedBlock {
            // given
            let team = Team.insertNewObject(in: self.syncMOC)
            self.mockApplicationStatus.mockSynchronizationState = .online
            team.remoteIdentifier = teamId
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.remoteIdentifier = conversationId
            conversation.team = team
            conversation.teamRemoteIdentifier = teamId

            team.needsToBeUpdatedFromBackend = true
            self.boostrapChangeTrackers(with: team)
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }

            // when
            let response = ZMTransportResponse(
                payload: ["label": "no-team-member"] as ZMTransportData,
                httpStatus: 403,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )

            // when
            request.complete(with: response)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertNil(Team.fetch(with: teamId, in: self.syncMOC))

            guard let conversation = ZMConversation.fetch(with: conversationId, in: self.syncMOC)
            else { return XCTFail("No conversation") }
            XCTAssertEqual(conversation.teamRemoteIdentifier, teamId)
            XCTAssert(ZMUser.selfUser(in: self.syncMOC).isGuest(in: conversation))
        }
    }

    func testThatItRemovesAMemberThatIsNotSelfUser() async {
        let teamId = UUID.create()
        let userId = UUID.create()

        var event: ZMUpdateEvent?
        var team: Team!

        await syncMOC.performGrouped {
            // given
            team = Team.insertNewObject(in: self.syncMOC)
            self.mockApplicationStatus.mockSynchronizationState = .online
            team.remoteIdentifier = teamId

            let user = ZMUser.insertNewObject(in: self.syncMOC)
            user.remoteIdentifier = userId
            _ = Member.getOrUpdateMember(for: user, in: team, context: self.syncMOC)
            self.syncMOC.saveOrRollback()

            let payload: [String: Any] = [
                "data": ["user": userId.transportString()],
                "time": Date().transportString(),
                "team": teamId.transportString(),
                "type": "team.member-leave",
            ]

            event = ZMUpdateEvent(fromEventStreamPayload: payload as NSDictionary, uuid: nil)!
        }

        guard let event else {
            XCTFail("missing event")
            return
        }

        // when
        await syncMOC.performGrouped {
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)

            self.syncMOC.saveOrRollback()

            // then
            let result = team.members.contains { member in
                member.user?.remoteIdentifier == userId
            }

            XCTAssertFalse(result)
        }
    }

    // MARK: Slow sync

    func test_ItGeneratesRequest_DuringSlowSync_V0() throws {
        // Given
        mockFetchingTeamsSyncPhase()

        // When
        let request = try XCTUnwrap(sutNextRequest(for: .v0))

        // Then
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.path, "/teams")
    }

    func test_ItGeneratesRequest_DuringSlowSync_V1() throws {
        // Given
        mockFetchingTeamsSyncPhase()

        // When
        let request = try XCTUnwrap(sutNextRequest(for: .v1))

        // Then
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.path, "/v1/teams")
    }

    func test_ItGeneratesRequest_DuringSlowSync_V2() throws {
        // Given
        mockFetchingTeamsSyncPhase()

        // When
        let request = try XCTUnwrap(sutNextRequest(for: .v2))

        // Then
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.path, "/v2/teams")
    }

    func test_ItGeneratesRequest_DuringSlowSync_V3() throws {
        // Given
        mockFetchingTeamsSyncPhase()

        // When
        let request = try XCTUnwrap(sutNextRequest(for: .v3))

        // Then
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.path, "/v3/teams")
    }

    func test_ItGeneratesRequest_DuringSlowSync_V4() throws {
        // Given
        mockFetchingTeamsSyncPhase()

        // When
        let request = try XCTUnwrap(sutNextRequest(for: .v4))

        // Then
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.path, "/v4/teams/\(teamID.transportString())")
    }

    func test_ItDoesNotGenerateRequest_DuringSlowSync_NonTeamUser_V4() throws {
        // Given
        mockFetchingTeamsSyncPhase()
        try mockNonTeamUser()

        // When
        XCTAssertNil(sutNextRequest(for: .v4))
        XCTAssertTrue(mockSyncStatus.didCallFinishCurrentSyncPhase)
    }

    func test_ItGeneratesRequest_DuringSlowSync_V5() throws {
        // Given
        mockFetchingTeamsSyncPhase()

        // When
        let request = try XCTUnwrap(sutNextRequest(for: .v5))

        // Then
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.path, "/v5/teams/\(teamID.transportString())")
    }

    func test_ItDoesNotGenerateRequest_DuringSlowSync_NonTeamUser_V5() throws {
        // Given
        mockFetchingTeamsSyncPhase()
        try mockNonTeamUser()

        // When
        XCTAssertNil(sutNextRequest(for: .v5))
        XCTAssertTrue(mockSyncStatus.didCallFinishCurrentSyncPhase)
    }

    func testThatItCreatesLocalTeam_DuringSlowSync() {
        // given
        mockSyncStatus.mockPhase = .fetchingTeams
        mockApplicationStatus.mockSynchronizationState = .slowSyncing
        guard let request = sutNextRequest(for: .v0) else { return XCTFail("No request generated") }
        let teamCreatorID = UUID.create()
        let teamID = UUID.create()

        // when
        let payload: [String: Any] = [
            "has_more": false,
            "teams": [
                sampleResponse(teamID: teamID, creatorId: teamCreatorID),
            ],
        ]

        request.complete(with: .init(
            payload: payload as ZMTransportData,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        ))
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        syncMOC.performAndWait {
            let team = Team.fetch(with: teamID, in: syncMOC)
            XCTAssertNotNil(team)
            XCTAssertEqual(team?.name, "Wire GmbH")
            let creator = ZMUser.fetch(with: teamCreatorID, in: syncMOC)
            XCTAssertNotNil(creator)
            XCTAssertEqual(team!.creator, creator)
        }
    }

    func testThatItFailsTheSyncState_WhenThereIsAPermanentError() {
        // given
        mockSyncStatus.mockPhase = .fetchingTeams
        mockApplicationStatus.mockSynchronizationState = .slowSyncing
        guard let request = sutNextRequest(for: .v0) else { return XCTFail("No request generated") }

        // when
        let response = ZMTransportResponse(
            payload: nil,
            httpStatus: 400,
            transportSessionError: nil,
            apiVersion: APIVersion.v0.rawValue
        )
        request.complete(with: response)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(mockSyncStatus.didCallFailCurrentSyncPhase)
    }

    func testThatItCompletesTheSyncState_WhenTeamHasBeenDownloaded() {
        // given
        mockSyncStatus.mockPhase = .fetchingTeams
        mockApplicationStatus.mockSynchronizationState = .slowSyncing

        // when
        do {
            guard let request = sutNextRequest(for: .v0) else { return XCTFail("No request generated") }
            let payload: [String: Any] = [
                "has_more": false,
                "teams": [sampleResponse(teamID: UUID(), creatorId: UUID())],
            ]
            request.complete(with: .init(
                payload: payload as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            ))
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        }

        // then
        XCTAssertTrue(mockSyncStatus.didCallFinishCurrentSyncPhase)
    }

    func testThatItCompletesTheSyncState_WhenNoTeamExists() {
        // given
        mockSyncStatus.mockPhase = .fetchingTeams
        mockApplicationStatus.mockSynchronizationState = .slowSyncing

        // when
        do {
            guard let request = sutNextRequest(for: .v0) else { return XCTFail("No request generated") }
            let payload: [String: Any] = [
                "has_more": false,
                "teams": [],
            ]
            request.complete(with: .init(
                payload: payload as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            ))
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))
        }

        // then
        XCTAssertTrue(mockSyncStatus.didCallFinishCurrentSyncPhase)
    }

    // MARK: Fileprivate

    // MARK: - Helper

    fileprivate func boostrapChangeTrackers(with objects: ZMManagedObject...) {
        for contextChangeTracker in sut.contextChangeTrackers {
            contextChangeTracker.objectsDidChange(Set(objects))
        }
    }

    // MARK: Private

    private func mockFetchingTeamsSyncPhase() {
        mockSyncStatus.mockPhase = .fetchingTeams
        mockApplicationStatus.mockSynchronizationState = .slowSyncing
    }

    private func mockNonTeamUser() throws {
        syncMOC.performGroupedAndWait {
            let user = ZMUser.selfUser(in: self.syncMOC)
            user.teamIdentifier = nil
        }
        try syncMOC.performAndWait {
            try syncMOC.save()
        }
    }

    private func sutNextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        syncMOC.performAndWait { sut.nextRequest(for: apiVersion) }
    }
}
