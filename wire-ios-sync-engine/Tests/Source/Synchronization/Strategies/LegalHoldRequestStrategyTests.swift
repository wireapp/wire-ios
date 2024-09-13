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

class LegalHoldRequestStrategyTests: MessagingTest {
    var sut: LegalHoldRequestStrategy!
    var mockSyncStatus: MockSyncStatus!
    var mockApplicationStatus: MockApplicationStatus!

    override func setUp() {
        super.setUp()
        mockSyncStatus = MockSyncStatus(
            managedObjectContext: syncMOC,
            lastEventIDRepository: lastEventIDRepository
        )
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .slowSyncing
        sut = LegalHoldRequestStrategy(
            withManagedObjectContext: syncMOC,
            applicationStatus: mockApplicationStatus,
            syncStatus: mockSyncStatus
        )

        syncMOC.performGroupedAndWait {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            selfUser.remoteIdentifier = UUID()
        }
    }

    override func tearDown() {
        sut = nil
        mockSyncStatus = nil
        mockApplicationStatus = nil
        super.tearDown()
    }

    static func legalHoldRequest(for user: ZMUser) -> LegalHoldRequest {
        LegalHoldRequest(
            target: user.remoteIdentifier!,
            requester: UUID(),
            clientIdentifier: "eca3c87cfe28be49",
            lastPrekey: LegalHoldRequest.Prekey(
                id: 65535,
                key: Data(
                    base64Encoded: "pQABAQoCoQBYIPEFMBhOtG0dl6gZrh3kgopEK4i62t9sqyqCBckq3IJgA6EAoQBYIC9gPmCdKyqwj9RiAaeSsUI7zPKDZS+CjoN+sfihk/5VBPY="
                )!
            )
        )
    }

    static func payloadForReceivingLegalHoldRequestStatus(request: LegalHoldRequest) -> ZMTransportData {
        var payload: [String: Any] = [
            "status": "pending",
            "client": ["id": request.clientIdentifier],
            "last_prekey": [
                "id": request.lastPrekey.id,
                "key": request.lastPrekey.key.base64EncodedString(),
            ],
        ]

        if let target = request.target {
            payload["id"] = target.transportString()
        }

        if let requester = request.requester {
            payload["requester"] = requester.transportString()
        }

        return payload as ZMTransportData
    }

    static func payloadForReceivingLegalHoldRequestEvent(request: LegalHoldRequest) -> ZMTransportData {
        var payload: [String: Any] = [
            "type": "user.legalhold-request",
            "client": ["id": request.clientIdentifier],
            "last_prekey": [
                "id": request.lastPrekey.id,
                "key": request.lastPrekey.key.base64EncodedString(),
            ],
        ]

        if let target = request.target {
            payload["id"] = target.transportString()
        }

        if let requester = request.requester {
            payload["requester"] = requester.transportString()
        }

        return payload as ZMTransportData
    }

    // MARK: - Slow Sync

    func testThatItRequestsLegalHoldStatus_DuringSlowSync() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            self.mockSyncStatus.mockPhase = .fetchingLegalHoldStatus

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = .create()
            _ = Member.getOrUpdateMember(for: selfUser, in: team, context: self.syncMOC)

            // WHEN
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }

            // THEN
            XCTAssertEqual(
                request.path,
                "/teams/\(team.remoteIdentifier!.transportString())/legalhold/\(selfUser.remoteIdentifier.transportString())"
            )
        }
    }

    func testThatItSkipsLegalHoldSyncPhase_IfUserDoesNotBelongToAteam() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            self.mockSyncStatus.mockPhase = .fetchingLegalHoldStatus

            // WHEN
            _ = self.sut.nextRequest(for: .v0)

            // THEN
            XCTAssertTrue(self.mockSyncStatus.didCallFinishCurrentSyncPhase)
        }
    }

    func testThatISkipsLegalHoldSyncPhase_OnPermanentErrors() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            self.mockSyncStatus.mockPhase = .fetchingLegalHoldStatus

            // WHEN
            let request = self.sut.nextRequest(for: .v0)
            request?.complete(with: ZMTransportResponse(
                payload: nil,
                httpStatus: 500,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            ))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            XCTAssertTrue(self.mockSyncStatus.didCallFinishCurrentSyncPhase)
        }
    }

    func testThatItCreatesALegalHoldRequest_WhenLegalHoldStatusIsPending() {
        var expectedLegalHoldRequest: LegalHoldRequest!

        syncMOC.performGroupedAndWait {
            // GIVEN
            self.mockSyncStatus.mockPhase = .fetchingLegalHoldStatus

            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = .create()
            _ = Member.getOrUpdateMember(for: selfUser, in: team, context: self.syncMOC)
            expectedLegalHoldRequest = type(of: self).legalHoldRequest(for: selfUser)

            let payload = type(of: self).payloadForReceivingLegalHoldRequestStatus(request: expectedLegalHoldRequest)
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }
            request.complete(with: ZMTransportResponse(
                payload: payload,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            ))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            guard case let .pending(legalHoldRequest) = selfUser.legalHoldStatus else { return XCTFail() }
            XCTAssertEqual(legalHoldRequest.clientIdentifier, expectedLegalHoldRequest.clientIdentifier)
        }
    }

    func testThatItCancelsALegalHoldRequest_WhenLegalHoldStatusIsDisabled() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            self.mockSyncStatus.mockPhase = .fetchingLegalHoldStatus

            let selfUser = ZMUser.selfUser(in: self.syncMOC)

            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = .create()
            _ = Member.getOrUpdateMember(for: selfUser, in: team, context: self.syncMOC)

            let legalHoldRequest = type(of: self).legalHoldRequest(for: selfUser)
            selfUser.userDidReceiveLegalHoldRequest(legalHoldRequest)

            let payload: [AnyHashable: Any] = [
                "status": "disabled",
            ]
            guard let request = self.sut.nextRequest(for: .v0) else { return XCTFail() }
            request.complete(with: ZMTransportResponse(
                payload: payload as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: APIVersion.v0.rawValue
            ))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            XCTAssertEqual(selfUser.legalHoldStatus, .disabled)
        }
    }

    // MARK: - Event Processing

    func testThatItProcessesLegalHoldRequestEvent() async {
        // GIVEN
        var selfUser: ZMUser! = nil

        syncMOC.performGroupedBlock {
            selfUser = ZMUser.selfUser(in: self.syncMOC)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performAndWait {
            let legalHoldRequest = type(of: self).legalHoldRequest(for: selfUser)
            let payload = type(of: self).payloadForReceivingLegalHoldRequestEvent(request: legalHoldRequest)
            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: UUID())!

            // WHEN
            self.sut.processEvents([event], liveEvents: true, prefetchResult: .none)

            // THEN
            XCTAssertEqual(selfUser.legalHoldStatus, .pending(legalHoldRequest))
        }
    }

    func testThatItProcessesLegalHoldDisabledEvent() {
        // GIVEN
        syncMOC.performGroupedAndWait {
            self.mockSyncStatus.mockPhase = .fetchingLegalHoldStatus

            let selfUser = ZMUser.selfUser(in: self.syncMOC)

            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = .create()
            _ = Member.getOrUpdateMember(for: selfUser, in: team, context: self.syncMOC)

            let legalHoldRequest = type(of: self).legalHoldRequest(for: selfUser)
            selfUser.userDidReceiveLegalHoldRequest(legalHoldRequest)
            XCTAssertEqual(selfUser.legalHoldStatus, .pending(legalHoldRequest))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // WHEN
        let payload: [String: Any] = [
            "type": "user.legalhold-disable",
        ]
        let event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID())!
        syncMOC.performAndWait {
            self.sut.processEvents([event], liveEvents: true, prefetchResult: .none)
        }

        // THEN
        syncMOC.performGroupedAndWait {
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            XCTAssertEqual(selfUser.legalHoldStatus, .disabled)
        }
    }
}
