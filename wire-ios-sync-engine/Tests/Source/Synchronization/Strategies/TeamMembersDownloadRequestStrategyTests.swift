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

import XCTest
@testable import WireSyncEngine

final class TeamMembersDownloadRequestStrategyTests: MessagingTest {
    var sut: TeamMembersDownloadRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!
    var mockSyncStatus: MockSyncStatus!

    let sampleResponseForSmallTeam: [String: Any] = [
        "hasMore": false,
        "members": [
            [
                "user": UUID().transportString(),
                "permissions": [
                    "copy": 1587,
                    "self": 1587,
                ],
            ],
        ],
    ]

    let sampleResponseForLargeTeam: [String: Any] = [
        "hasMore": true,
        "members": [
            [
                "user": UUID().transportString(),
                "permissions": [
                    "copy": 1587,
                    "self": 1587,
                ],
            ],
        ],
    ]

    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockSyncStatus = MockSyncStatus(
            managedObjectContext: syncMOC,
            lastEventIDRepository: lastEventIDRepository
        )
        sut = TeamMembersDownloadRequestStrategy(
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

    func createTeam() -> Team {
        let selfUser = ZMUser.selfUser(in: syncMOC)
        let teamID = UUID()
        selfUser.teamIdentifier = teamID
        let team = Team.insertNewObject(in: syncMOC)
        team.remoteIdentifier = teamID
        _ = Member.getOrUpdateMember(for: selfUser, in: team, context: syncMOC)

        return team
    }

    func testThatItDoesNotGenerateARequestInitially() {
        XCTAssertNil(sut.nextRequest(for: .v0))
    }

    func testThatItCreatesRequestToFetchTeamMembers() {
        syncMOC.performGroupedAndWait {
            // given
            self.mockApplicationStatus.mockSynchronizationState = .slowSyncing
            self.mockSyncStatus.mockPhase = .fetchingTeamMembers
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let teamID = UUID()
            selfUser.teamIdentifier = teamID

            // when
            let request = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNotNil(request)
            XCTAssertEqual(request?.path, "/teams/\(teamID.transportString())/members?maxResults=2000")
        }
    }

    func testThatItFinishSyncStep_IfSelfUserDoesntBelongToTeam() {
        syncMOC.performGroupedAndWait {
            // given
            self.mockApplicationStatus.mockSynchronizationState = .slowSyncing
            self.mockSyncStatus.mockPhase = .fetchingTeamMembers

            // when
            let request = self.sut.nextRequest(for: .v0)

            // then
            XCTAssertNil(request)
            XCTAssertTrue(self.mockSyncStatus.didCallFinishCurrentSyncPhase)
        }
    }

    func testThatItFinishSyncStep_OnSuccessfulResponse() {
        syncMOC.performGroupedAndWait {
            // given
            self.mockApplicationStatus.mockSynchronizationState = .slowSyncing
            self.mockSyncStatus.mockPhase = .fetchingTeamMembers
            _ = self.createTeam()

            guard let request = self.sut.nextRequest(for: .v0) else {
                return XCTFail("No request generated")
            }

            // when
            let response = ZMTransportResponse(
                payload: self.sampleResponseForSmallTeam as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )
            request.complete(with: response)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertNil(self.sut.nextRequest(for: .v0))
            XCTAssertTrue(self.mockSyncStatus.didCallFinishCurrentSyncPhase)
        }
    }

    func testThatItCreatesTeamMembers_WhenHasMoreIsFalse() {
        var team: Team!

        syncMOC.performGroupedAndWait {
            // given
            self.mockApplicationStatus.mockSynchronizationState = .slowSyncing
            self.mockSyncStatus.mockPhase = .fetchingTeamMembers
            team = self.createTeam()

            guard let request = self.sut.nextRequest(for: .v0) else {
                return XCTFail("No request generated")
            }

            // when
            let response = ZMTransportResponse(
                payload: self.sampleResponseForSmallTeam as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )
            request.complete(with: response)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertEqual(team.members.count, 2)
        }
    }

    func testThatItCreatesTeamMembers_WhenHasMoreIsTrue() {
        var team: Team!
        var initialTeamMembersCount = 0
        syncMOC.performGroupedAndWait {
            // given
            self.mockApplicationStatus.mockSynchronizationState = .slowSyncing
            self.mockSyncStatus.mockPhase = .fetchingTeamMembers
            team = self.createTeam()
            initialTeamMembersCount = team.members.count

            guard let request = self.sut.nextRequest(for: .v0) else {
                return XCTFail("No request generated")
            }

            // when
            let response = ZMTransportResponse(
                payload: self.sampleResponseForLargeTeam as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            )
            request.complete(with: response)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertEqual(team.members.count, initialTeamMembersCount + 1)
        }
    }
}
