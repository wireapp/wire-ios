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

import Foundation
import WireRequestStrategySupport
import WireTransport
import XCTest
@testable import WireRequestStrategy

class UserProfileRequestStrategyTests: MessagingTestBase {
    var sut: UserProfileRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!
    var mockSyncProgress: MockSyncProgress!

    var apiVersion: APIVersion! {
        didSet {
            BackendInfo.apiVersion = apiVersion
        }
    }

    override func setUp() {
        super.setUp()

        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online

        mockSyncProgress = MockSyncProgress()
        mockSyncProgress.currentSyncPhase = .done
        mockSyncProgress.finishCurrentSyncPhasePhase_MockMethod = { _ in }

        sut = UserProfileRequestStrategy(
            managedObjectContext: syncMOC,
            applicationStatus: mockApplicationStatus,
            syncProgress: mockSyncProgress
        )
        apiVersion = .v0
    }

    override func tearDown() {
        sut = nil
        mockSyncProgress = nil
        mockApplicationStatus = nil

        super.tearDown()
    }

    // MARK: - Request generation

    func testThatRequestToFetchUserIsGenerated_WhenNeedsToBeUpdatedFromBackendIsTrue() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v1
            self.otherUser.domain = "example.com"
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/v1/list-users")
            guard let payloadData = (request.payload as? String)?.data(using: .utf8) else {
                return XCTFail("Payload data is invalid")
            }
            guard let payload = Payload.QualifiedUserIDList(payloadData) else {
                return XCTFail("Payload is invalid")
            }

            XCTAssertEqual(payload.qualifiedIDs.count, 1)
            XCTAssertEqual(payload.qualifiedIDs.first?.uuid, self.otherUser.remoteIdentifier)
            XCTAssertEqual(payload.qualifiedIDs.first?.domain, self.otherUser.domain)
        }
    }

    func testThatRequestInV4_DoesNotUseLegacyEndpointWhenNoRequestFromCurrentEndpoint() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v0
            self.otherUser.domain = "example.com"
            self.otherUser.needsToBeUpdatedFromBackend = true
            // By reporting the otherUser did change while on v0, sut will case the legacy transcoder to get in a state
            // where it would produce a next request
            self.sut.objectsDidChange(Set([self.otherUser]))

            // when
            // By switching to v4 and asking for a next request, we get nil because we would only ask the non legacy
            // transcoder for a request, but it's not in a state to do that
            self.apiVersion = .v4
            let request = self.sut.nextRequest(for: self.apiVersion)

            // then
            // non legacy transcoder's endpoint should not be used
            XCTAssertNil(request)
        }
    }

    // MARK: - Slow Sync

    func testThatRequestToFetchConnectedUsersIsGenerated_DuringFetchingUsersSyncPhase() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v1
            self.mockSyncProgress.currentSyncPhase = .fetchingUsers
            self.otherUser.domain = "example.com"

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/v1/list-users")
            guard let payload = Payload.QualifiedUserIDList(request) else {
                return XCTFail("Payload is invalid")
            }

            XCTAssertEqual(payload.qualifiedIDs.count, 1)
            XCTAssertEqual(payload.qualifiedIDs.first?.uuid, self.otherUser.remoteIdentifier)
            XCTAssertEqual(payload.qualifiedIDs.first?.domain, self.otherUser.domain)
        }
    }

    func testThatRequestToFetchConnectedUsersIsGenerated_WhenSlowSyncIsRestarted() {
        // given
        apiVersion = .v1

        syncMOC.performGroupedAndWait {
            self.mockSyncProgress.currentSyncPhase = .fetchingUsers
            self.otherUser.domain = "example.com"
            let request = self.sut.nextRequest(for: self.apiVersion)!

            guard let payload = Payload.QualifiedUserIDList(request) else {
                return XCTFail("Payload is invalid")
            }

            guard let response = self.successfulResponse(for: payload, apiVersion: self.apiVersion) else {
                return XCTFail("Response is invalid")
            }
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/v1/list-users")
            guard let payload = Payload.QualifiedUserIDList(request) else {
                return XCTFail("Payload is invalid")
            }

            XCTAssertEqual(payload.qualifiedIDs.count, 1)
            XCTAssertEqual(payload.qualifiedIDs.first?.uuid, self.otherUser.remoteIdentifier)
            XCTAssertEqual(payload.qualifiedIDs.first?.domain, self.otherUser.domain)
        }
    }

    func testThatRequestToFetchConnectedUsersIsNotGenerated_WhenFetchIsAlreadyInProgress() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v1
            self.mockSyncProgress.currentSyncPhase = .fetchingUsers
            self.otherUser.domain = "example.com"
            _ = self.sut.nextRequest(for: self.apiVersion)!

            // when
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    func testThatFetchingUsersSyncPhaseIsFinished_WhenFetchIsCompleted() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v1
            self.mockSyncProgress.currentSyncPhase = .fetchingUsers
            self.otherUser.domain = "example.com"
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // when
            guard let payload = Payload.QualifiedUserIDList(request) else {
                return XCTFail("Payload is invalid")
            }

            guard let response = self.successfulResponse(for: payload, apiVersion: self.apiVersion) else {
                return XCTFail("Response is invalid")
            }
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertEqual(self.mockSyncProgress.finishCurrentSyncPhasePhase_Invocations, [.fetchingUsers])
            XCTAssertFalse(self.sut.isFetchingAllConnectedUsers)
        }
    }

    func testThatFetchingUsersSyncPhaseIsFinished_WhenThereIsNoUsersToFetch() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v1
            self.mockSyncProgress.currentSyncPhase = .fetchingUsers
            self.otherUser.domain = "example.com"
            self.syncMOC.delete(self.otherUser.connection!)

            // when
            _ = self.sut.nextRequest(for: self.apiVersion)

            // then
            XCTAssertEqual(self.mockSyncProgress.finishCurrentSyncPhasePhase_Invocations, [.fetchingUsers])
            XCTAssertFalse(self.sut.isFetchingAllConnectedUsers)
        }
    }

    // MARK: - Response processing

    func testThatUsesLegacyEndpointOnV0_WhenFederatedEndpointIsDisabled() {
        syncMOC.performGroupedAndWait {
            // given
            self.otherUser.domain = "example.com"
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/users?ids=\(self.otherUser.remoteIdentifier.transportString())")
        }
    }

    func testThatNeedsToUpdatedFromBackendIsReset_WhenSuccessfullyProcessingResponse() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v1
            self.otherUser.domain = "example.com"
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // when
            guard let payload = Payload.QualifiedUserIDList(request) else {
                return XCTFail("Payload is invalid")
            }

            guard let response = self.successfulResponse(for: payload, apiVersion: self.apiVersion) else {
                return XCTFail("Response is invalid")
            }
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertFalse(self.otherUser.needsToBeUpdatedFromBackend)
        }
    }

    func testThatNeedsToUpdatedFromBackendIsReset_WhenSuccessfullyProcessingResponse_V4() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v4
            self.otherUser.domain = "example.com"
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))
            guard let request = self.sut.nextRequest(for: self.apiVersion) else {
                return XCTFail("No request generated")
            }

            // when
            guard let payload = Payload.QualifiedUserIDList(request) else {
                return XCTFail("Payload is invalid")
            }

            guard let response = self.successfulResponse(for: payload, apiVersion: self.apiVersion) else {
                return XCTFail("Response is invalid")
            }
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertFalse(self.otherUser.needsToBeUpdatedFromBackend)
        }
    }

    func testThatItIsPendingMetadataRefresh_WhenSuccessfullyProcessingResponseWithFailedUsers_V4() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v4
            self.otherUser.domain = "example.com"
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))
            let failedUser = QualifiedID(uuid: self.otherUser.remoteIdentifier, domain: self.otherUser.domain ?? "")
            guard let request = self.sut.nextRequest(for: self.apiVersion) else {
                return XCTFail("No request generated")
            }

            // when
            guard let payload = Payload.QualifiedUserIDList(request) else {
                return XCTFail("Payload is invalid")
            }

            guard let response = self
                .successfulResponse(for: payload, failed: [failedUser], apiVersion: self.apiVersion) else {
                return XCTFail("Response is invalid")
            }
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertTrue(self.otherUser.isPendingMetadataRefresh)
        }
    }

    func testThatNeedsToUpdatedFromBackendIsReset_WhenSuccessfullyProcessingResponseFromLegacyEndpoint() {
        syncMOC.performGroupedAndWait {
            // given
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // when
            let qualifiedID = QualifiedID(uuid: self.otherUser.remoteIdentifier, domain: "example.com")
            let qualifiedIDs = Payload.QualifiedUserIDList(qualifiedIDs: [qualifiedID])
            guard let response = self.successfulResponse(for: qualifiedIDs, apiVersion: self.apiVersion) else {
                return XCTFail("Response is invalid")
            }
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertFalse(self.otherUser.needsToBeUpdatedFromBackend)
        }
    }

    func testThatNeedsToUpdatedFromBackendIsReset_WhenUserProfileIsNotIncludedInResponse() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v1
            self.otherUser.domain = "example.com"
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // when
            let qualifiedIDs = Payload.QualifiedUserIDList(qualifiedIDs: [])
            guard let response = self.successfulResponse(for: qualifiedIDs, apiVersion: self.apiVersion) else {
                return XCTFail("Response is invalid")
            }
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertFalse(self.otherUser.needsToBeUpdatedFromBackend)
        }
    }

    func testThatNeedsToUpdatedFromBackendIsReset_WhenUserProfileIsNotIncludedInResponseFromLegacyEndpoint() {
        syncMOC.performGroupedAndWait {
            // given
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // when
            let qualifiedIDs = Payload.QualifiedUserIDList(qualifiedIDs: [])
            guard let response = self.successfulResponse(for: qualifiedIDs, apiVersion: self.apiVersion) else {
                return XCTFail("Response is invalid")
            }
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertFalse(self.otherUser.needsToBeUpdatedFromBackend)
        }
    }

    func testThatNeedsToUpdatedFromBackendIsReset_WhenResponseIndicateAPermanentError() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v1
            self.otherUser.domain = "example.com"
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // when
            request.complete(with: self.responseFailure(code: 404, label: .notFound, apiVersion: self.apiVersion))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertFalse(self.otherUser.needsToBeUpdatedFromBackend)
        }
    }

    func testThatNeedsToUpdatedFromBackendIsReset_WhenResponseIndicateAPermanentErrorFromLegacyEndpoint() {
        syncMOC.performGroupedAndWait {
            // given
            self.otherUser.needsToBeUpdatedFromBackend = true
            self.sut.objectsDidChange(Set([self.otherUser]))
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // when
            request.complete(with: self.responseFailure(code: 404, label: .notFound, apiVersion: self.apiVersion))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performGroupedAndWait {
            // then
            XCTAssertFalse(self.otherUser.needsToBeUpdatedFromBackend)
        }
    }

    // MARK: - Event processing

    func testThatUserUpdateEventsAreProcessed() {
        syncMOC.performGroupedAndWait {
            // given
            let updatedName = "123"
            let event = self.userUpdateEvent(userProfile: Payload.UserProfile(
                id: self.otherUser.remoteIdentifier,
                qualifiedID: nil,
                teamID: nil,
                serviceID: nil,
                SSOID: nil,
                name: updatedName,
                handle: nil,
                phone: nil, email: nil,
                assets: [],
                managedBy: nil, accentColor: nil,
                isDeleted: nil,
                expiresAt: nil,
                legalholdStatus: nil
            ))

            // when
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)

            // then
            XCTAssertEqual(self.otherUser.name, updatedName)
        }
    }

    func testThatUserDeleteEventsAreProcessed_WhenOtherUserIsDeleted() {
        syncMOC.performGroupedAndWait {
            // given
            let event = self.userDeleteEvent(userID: self.otherUser.remoteIdentifier)

            // when
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)

            // then
            XCTAssertTrue(self.otherUser.isAccountDeleted)
        }
    }

    func testThatUserDeleteEventsAreProcessed_WhenSelfUserIsDeleted() {
        syncMOC.performGroupedAndWait {
            // given
            let event = self.userDeleteEvent(userID: ZMUser.selfUser(in: self.syncMOC).remoteIdentifier)

            // expect
            self.customExpectation(
                forNotification: AccountDeletedNotification.notificationName,
                object: nil,
                handler: nil
            )

            // when
            self.sut.processEvents([event], liveEvents: true, prefetchResult: nil)
            XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        }
    }

    // MARK: - Helpers

    func userDeleteEvent(userID: UUID) -> ZMUpdateEvent {
        let payload: [String: Any] = [
            "type": "user.delete",
            "id": userID.transportString(),
            "time": Date(),
        ]

        return ZMUpdateEvent(
            uuid: UUID(),
            payload: payload,
            transient: false,
            decrypted: true,
            source: .webSocket
        )!
    }

    func userUpdateEvent(userProfile: Payload.UserProfile) -> ZMUpdateEvent {
        let payload: [String: Any] = [
            "type": "user.update",
            "user": try! JSONSerialization.jsonObject(with: userProfile.payloadData()!, options: []),
        ]

        return ZMUpdateEvent(
            uuid: UUID(),
            payload: payload,
            transient: false,
            decrypted: true,
            source: .webSocket
        )!
    }

    func successfulResponse(
        for request: Payload.QualifiedUserIDList,
        failed: [QualifiedID]? = nil,
        apiVersion: APIVersion
    ) -> ZMTransportResponse? {
        let userProfiles = request.qualifiedIDs.map {
            userProfile(for: $0.uuid, domain: $0.domain)
        }

        var payloadData: Data?
        switch apiVersion {
        case .v0, .v1, .v2, .v3:
            payloadData = userProfiles.payloadData()
        case .v4, .v5, .v6:
            let userProfiles = Payload.UserProfilesV4(found: userProfiles, failed: failed)
            payloadData = userProfiles.payloadData()
        }

        guard let payloadData,
              let payloadString = String(bytes: payloadData, encoding: .utf8)
        else {
            return nil
        }

        let response = ZMTransportResponse(
            payload: payloadString as ZMTransportData,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: apiVersion.rawValue
        )

        return response
    }

    func userProfile(for uuid: UUID, domain: String?) -> Payload.UserProfile {
        Payload.UserProfile(
            id: uuid,
            qualifiedID: nil,
            teamID: nil,
            serviceID: nil,
            SSOID: nil,
            name: "John Doe",
            handle: nil,
            phone: nil,
            email: nil,
            assets: [],
            managedBy: nil,
            accentColor: nil,
            isDeleted: nil,
            expiresAt: nil,
            legalholdStatus: nil
        )
    }
}

extension Decodable {
    init?(_ request: ZMTransportRequest) {
        guard let payloadData = (request.payload as? String)?.data(using: .utf8) else {
            return nil
        }

        self.init(payloadData)
    }
}
