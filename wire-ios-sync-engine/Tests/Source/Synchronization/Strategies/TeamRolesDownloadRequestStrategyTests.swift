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

class TeamRolesDownloadRequestStrategyTests: MessagingTest {
    var sut: TeamRolesDownloadRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!
    var mockSyncStatus: MockSyncStatus!

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockSyncStatus = MockSyncStatus(
            managedObjectContext: syncMOC,
            lastEventIDRepository: lastEventIDRepository
        )
        sut = TeamRolesDownloadRequestStrategy(
            withManagedObjectContext: syncMOC,
            applicationStatus: mockApplicationStatus,
            syncStatus: mockSyncStatus
        )

        syncMOC.performGroupedAndWait {
            let user = ZMUser.selfUser(in: self.syncMOC)
            user.remoteIdentifier = UUID()
        }
    }

    override func tearDown() {
        mockApplicationStatus = nil
        mockSyncStatus = nil
        sut = nil
        super.tearDown()
    }

    let sampleResponse: [String: Any] = [
        "conversation_roles": [
            [
                "actions": [
                    "leave_conversation",
                    "delete_conversation",
                ],
                "conversation_role": "superuser",
            ],
            [
                "actions": [
                    "leave_conversation",
                ],
                "conversation_role": "weakling",
            ],
        ],
    ]

    // MARK: - Helper

    fileprivate func boostrapChangeTrackers(with objects: ZMManagedObject...) {
        for contextChangeTracker in sut.contextChangeTrackers {
            contextChangeTracker.objectsDidChange(Set(objects))
        }
    }

    func testThatPredicateIsCorrect() {
        // given
        syncMOC.performAndWait {
            let team1 = Team.insertNewObject(in: self.syncMOC)
            team1.remoteIdentifier = .create()
            team1.needsToDownloadRoles = true

            let team2 = Team.insertNewObject(in: self.syncMOC)
            team2.remoteIdentifier = .create()
            team2.needsToDownloadRoles = false

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
            team.needsToDownloadRoles = false
            self.boostrapChangeTrackers(with: team)

            // then
            XCTAssertNil(self.sut.nextRequest(for: .v0))
        }
    }

    func testThatItCreatesARequestForATeamThatNeedsToBeUpdatedFromTheBackend() {
        syncMOC.performGroupedAndWait {
            // given
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = .create()
            self.mockApplicationStatus.mockSynchronizationState = .online

            // when
            team.needsToDownloadRoles = true
            self.boostrapChangeTrackers(with: team)

            // then
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }
            XCTAssertEqual(request.method, .get)
            XCTAssertEqual(request.path, "/teams/\(team.remoteIdentifier!.transportString())/conversations/roles")
        }
    }

    func testThatItUpdatesTheTeamWithTheResponse() {
        var team: Team!

        syncMOC.performGroupedAndWait {
            // given
            team = Team.insertNewObject(in: self.syncMOC)
            self.mockApplicationStatus.mockSynchronizationState = .online
            team.remoteIdentifier = .create()
            team.needsToDownloadRoles = true
            self.boostrapChangeTrackers(with: team)
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }

            // when
            let response = ZMTransportResponse(
                payload: self.sampleResponse as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )
            request.complete(with: response)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertEqual(team.roles.count, 2)
            guard let adminRole = team.roles.first(where: { $0.name == "superuser" }),
                  let memberRole = team.roles.first(where: { $0.name == "weakling" }) else {
                return XCTFail()
            }
            XCTAssertEqual(
                Set(adminRole.actions.compactMap(\.name)),
                Set(["leave_conversation", "delete_conversation"])
            )
            XCTAssertEqual(
                Set(memberRole.actions.compactMap(\.name)),
                Set(["leave_conversation"])
            )
            XCTAssertFalse(team.needsToDownloadRoles)
        }
    }

    func testThatItUpdatesSyncStepDuringSync() {
        mockSyncStatus.mockPhase = .fetchingTeamRoles

        syncMOC.performGroupedAndWait {
            // given
            let team = Team.insertNewObject(in: self.syncMOC)
            self.mockApplicationStatus.mockSynchronizationState = .online
            team.remoteIdentifier = .create()
            team.needsToDownloadRoles = true
            self.boostrapChangeTrackers(with: team)
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }

            // when
            let response = ZMTransportResponse(
                payload: self.sampleResponse as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )
            request.complete(with: response)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // then
        XCTAssertTrue(mockSyncStatus.didCallFinishCurrentSyncPhase)
    }

    func testThatItDoesNotUpdatesSyncStepOutsideOfSync() {
        syncMOC.performGroupedAndWait {
            // given
            let team = Team.insertNewObject(in: self.syncMOC)
            self.mockApplicationStatus.mockSynchronizationState = .online
            team.remoteIdentifier = .create()
            team.needsToDownloadRoles = true
            self.boostrapChangeTrackers(with: team)
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }

            // when
            let response = ZMTransportResponse(
                payload: self.sampleResponse as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )
            request.complete(with: response)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // then
        XCTAssertFalse(mockSyncStatus.didCallFinishCurrentSyncPhase)
    }

    func testThatItFinishedSyncStepIfNoTeam() {
        syncMOC.performGroupedAndWait {
            // given
            self.mockSyncStatus.mockPhase = .fetchingTeamRoles

            // when
            let request = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNil(request)
            XCTAssertTrue(self.mockSyncStatus.didCallFinishCurrentSyncPhase)
        }
    }

    func testThatItCreatesNoNewRequestAfterReceivingAResponse() {
        var team: Team!

        syncMOC.performGroupedAndWait {
            // given
            team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = .create()
            team.needsToDownloadRoles = true
            self.mockApplicationStatus.mockSynchronizationState = .online
            self.boostrapChangeTrackers(with: team)

            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail("No request generated") }

            // when
            let response = ZMTransportResponse(
                payload: self.sampleResponse as ZMTransportData,
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
            XCTAssertNil(self.sut.nextRequest(for: .v0))
        }
    }

    func testThatItDoesNotRemoveATeamWhenReceiving403() {
        let teamId = UUID.create()

        syncMOC.performGroupedAndWait {
            // given
            let team = Team.insertNewObject(in: self.syncMOC)
            self.mockApplicationStatus.mockSynchronizationState = .online
            team.remoteIdentifier = teamId
            team.needsToDownloadRoles = true
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
            XCTAssertNotNil(Team.fetch(with: teamId, in: self.syncMOC))
        }
    }
}
