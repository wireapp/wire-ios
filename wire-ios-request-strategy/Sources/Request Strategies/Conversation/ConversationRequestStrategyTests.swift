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
import WireDataModel
import WireDataModelSupport
import WireRequestStrategySupport
import WireTransport
import XCTest
@testable import WireRequestStrategy

class ConversationRequestStrategyTests: MessagingTestBase {
    var sut: ConversationRequestStrategy!
    var mockApplicationStatus: MockApplicationStatus!
    var mockSyncProgress: MockSyncProgress!
    var mockRemoveLocalConversation: MockLocalConversationRemovalUseCase!
    var mockMLSService: MockMLSServiceInterface!

    var apiVersion: APIVersion! {
        didSet {
            BackendInfo.apiVersion = apiVersion
        }
    }

    override func setUp() {
        super.setUp()

        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online
        mockRemoveLocalConversation = MockLocalConversationRemovalUseCase()
        mockMLSService = MockMLSServiceInterface()

        mockSyncProgress = MockSyncProgress()
        mockSyncProgress.currentSyncPhase = .done
        mockSyncProgress.finishCurrentSyncPhasePhase_MockMethod = { _ in }
        mockSyncProgress.failCurrentSyncPhasePhase_MockMethod = { _ in }

        sut = ConversationRequestStrategy(
            withManagedObjectContext: syncMOC,
            applicationStatus: mockApplicationStatus,
            syncProgress: mockSyncProgress,
            mlsService: mockMLSService,
            removeLocalConversation: mockRemoveLocalConversation
        )
        apiVersion = .v0
    }

    override func tearDown() {
        sut = nil
        mockSyncProgress = nil
        mockApplicationStatus = nil
        mockRemoveLocalConversation = nil

        super.tearDown()
    }

    // MARK: - Request generation

    func testThatRequestToFetchConversationIsGenerated_WhenNeedsToBeUpdatedFromBackendIsTrue() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v1
            let domain = "example.com"
            let conversationID = self.groupConversation.remoteIdentifier!
            self.groupConversation.domain = domain
            self.groupConversation.needsToBeUpdatedFromBackend = true
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([self.groupConversation])) }

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/v1/conversations/\(domain)/\(conversationID.transportString())")
            XCTAssertEqual(request.method, .get)
        }
    }

    func testThatLegacyRequestToFetchConversationIsGenerated_WhenDomainIsNotSet() {
        syncMOC.performGroupedAndWait {
            // given
            ZMUser.selfUser(in: self.syncMOC).domain = nil
            let conversationID = self.groupConversation.remoteIdentifier!
            self.groupConversation.domain = nil
            self.groupConversation.needsToBeUpdatedFromBackend = true
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([self.groupConversation])) }

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/conversations/\(conversationID.transportString())")
            XCTAssertEqual(request.method, .get)
        }
    }

    func testThatRequestToUpdateConversationNameIsGenerated_WhenModifiedKeyIsSet() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v1
            let domain = self.groupConversation.domain!
            let conversationID = self.groupConversation.remoteIdentifier!
            self.groupConversation.userDefinedName = "Hello World"
            let conversationUserDefinedNameKeySet: Set<AnyHashable> = [ZMConversationUserDefinedNameKey]
            self.groupConversation.setLocallyModifiedKeys(conversationUserDefinedNameKeySet)
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([self.groupConversation])) }

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!
            let payload = Payload.UpdateConversationName(request)

            // then
            XCTAssertEqual(request.path, "/v1/conversations/\(domain)/\(conversationID.transportString())/name")
            XCTAssertEqual(request.method, .put)
            XCTAssertEqual(payload?.name, self.groupConversation.userDefinedName)
        }
    }

    func testThatRequestToUpdateArchiveStatusIsGenerated_WhenModifiedKeyIsSet() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v1
            let domain = self.groupConversation.domain!
            let conversationID = self.groupConversation.remoteIdentifier!
            self.groupConversation.isArchived = true
            let conversationArchivedChangedTimeStampKeySet: Set<AnyHashable> =
                [ZMConversationArchivedChangedTimeStampKey]
            self.groupConversation.setLocallyModifiedKeys(conversationArchivedChangedTimeStampKeySet)
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([self.groupConversation])) }

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!
            let payload = Payload.UpdateConversationStatus(request)

            // then
            XCTAssertEqual(request.path, "/v1/conversations/\(domain)/\(conversationID.transportString())/self")
            XCTAssertEqual(request.method, .put)
            XCTAssertEqual(payload?.archived, true)
        }
    }

    func testThatRequestToUpdateMutedStatusIsGenerated_WhenModifiedKeyIsSet() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v1
            let domain = self.groupConversation.domain!
            let conversationID = self.groupConversation.remoteIdentifier!
            self.groupConversation.mutedMessageTypes = .all
            let conversationSilencedChangedTimeStampKeySet: Set<AnyHashable> =
                [ZMConversationSilencedChangedTimeStampKey]
            self.groupConversation.setLocallyModifiedKeys(conversationSilencedChangedTimeStampKeySet)
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([self.groupConversation])) }

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!
            let payload = Payload.UpdateConversationStatus(request)

            // then
            XCTAssertEqual(request.path, "/v1/conversations/\(domain)/\(conversationID.transportString())/self")
            XCTAssertEqual(request.method, .put)
            XCTAssertEqual(payload?.mutedStatus, Int(MutedMessageTypes.all.rawValue))
        }
    }

    // MARK: - Slow Sync

    func testThatRequestToListConversationsIsGenerated_DuringFetchingConversationsSyncPhase() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v1
            self.mockSyncProgress.currentSyncPhase = .fetchingConversations

            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            // then
            XCTAssertEqual(request.path, "/v1/conversations/list-ids")
        }
    }

    func testThatRequestToListConversationsIsNotGenerated_WhenFetchIsAlreadyInProgress() {
        syncMOC.performGroupedAndWait {
            // given
            self.apiVersion = .v1
            self.mockSyncProgress.currentSyncPhase = .fetchingConversations
            _ = self.sut.nextRequest(for: self.apiVersion)!

            // when
            XCTAssertNil(self.sut.nextRequest(for: self.apiVersion))
        }
    }

    func testThatRequestToFetchConversationsIsGenerated_DuringFetchingConversationsSyncPhase() {
        // given
        apiVersion = .v1
        startSlowSync()
        fetchConversationListDuringSlowSync()

        syncMOC.performGroupedAndWait {
            // when
            let fetchRequest = self.sut.nextRequest(for: self.apiVersion)!

            // then
            guard let fetchPayload = Payload.QualifiedUserIDList(fetchRequest) else {
                return XCTFail("Fetch payload is invalid")
            }

            let qualifiedConversationID = QualifiedID(
                uuid: self.groupConversation.remoteIdentifier!,
                domain: self.groupConversation.domain!
            )
            XCTAssertEqual(fetchPayload.qualifiedIDs.count, 1)
            XCTAssertEqual(fetchPayload.qualifiedIDs, [qualifiedConversationID])
        }
    }

    func testThatFetchingConversationsSyncPhaseIsFinished_WhenFetchIsCompleted() {
        // given
        apiVersion = .v1
        startSlowSync()
        fetchConversationListDuringSlowSync()

        // when
        fetchConversationsDuringSlowSync()

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertEqual(self.mockSyncProgress.finishCurrentSyncPhasePhase_Invocations, [.fetchingConversations])
        }
    }

    func testThatFetchingConversationsSyncPhaseIsFinished_WhenThereIsNoConversationsToFetch() {
        // given
        apiVersion = .v1
        startSlowSync()

        // when
        fetchConversationListDuringSlowSyncWithEmptyResponse()

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertEqual(self.mockSyncProgress.finishCurrentSyncPhasePhase_Invocations, [.fetchingConversations])
        }
    }

    func testThatFetchingConversationsSyncPhaseIsFailed_WhenReceivingAPermanentError() {
        // given
        apiVersion = .v1
        startSlowSync()

        // when
        fetchConversationListDuringSlowSyncWithPermanentError()

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertEqual(self.mockSyncProgress.failCurrentSyncPhasePhase_Invocations, [.fetchingConversations])
        }
    }

    func testThatConversationMembershipStatusIsQueried_WhenNotFoundDuringSlowSyncPhase() {
        // given
        apiVersion = .v1
        startSlowSync()
        fetchConversationListDuringSlowSync()

        // when
        fetchConversationsDuringSlowSync(notFound: [qualifiedID(for: oneToOneConversation)])

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertTrue(self.oneToOneConversation.needsToBeUpdatedFromBackend)
        }
    }

    func testThatConversationIsPendingMetadataRefresh_WhenFailedDuringSlowSyncPhase() {
        // given
        apiVersion = .v4
        startSlowSync()
        fetchConversationListDuringSlowSync()

        // when
        fetchConversationsDuringSlowSync(failed: [qualifiedID(for: groupConversation)])

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertTrue(self.groupConversation.isPendingMetadataRefresh)
        }
    }

    func testThatConversationIsCreatedAndMarkedToFetched_WhenFailingDuringSlowSyncPhase() throws {
        // given
        apiVersion = .v1
        let conversationID = QualifiedID(uuid: UUID(), domain: owningDomain)
        startSlowSync()
        fetchConversationListDuringSlowSync()

        // when
        fetchConversationsDuringSlowSync(failed: [conversationID])

        // then
        try syncMOC.performGroupedAndWait {
            let conversation = try XCTUnwrap(ZMConversation.fetch(
                with: conversationID.uuid,
                domain: conversationID.domain,
                in: syncMOC
            ))
            XCTAssertTrue(conversation.needsToBeUpdatedFromBackend)
        }
    }

    // MARK: - Response processing

    func testThatConversationResetsNeedsToBeUpdatedFromBackend_OnPermanentErrors() {
        // given
        let response = responseFailure(code: 403, label: .unknown, apiVersion: apiVersion)

        // when
        fetchConversation(groupConversation, with: response, apiVersion: apiVersion)
        fetchConversation(oneToOneConversation, with: response, apiVersion: apiVersion)

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertFalse(self.groupConversation.needsToBeUpdatedFromBackend)
            XCTAssertFalse(self.oneToOneConversation.needsToBeUpdatedFromBackend)
        }
    }

    func testThatLocalConversationRemovalUseCaseIsExecuted_WhenResponseIs_404() {
        // given
        let response = responseFailure(code: 404, label: .notFound, apiVersion: apiVersion)

        // when
        fetchConversation(groupConversation, with: response, apiVersion: apiVersion)

        // then
        XCTAssertEqual(
            mockRemoveLocalConversation.invokeCalls,
            [groupConversation]
        )
    }

    func testThatSelfUserIsRemovedFromParticipantsList_WhenResponseIs_403() {
        // given
        let response = responseFailure(code: 403, label: .unknown, apiVersion: apiVersion)

        // when
        fetchConversation(groupConversation, with: response, apiVersion: apiVersion)

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertFalse(self.groupConversation.isSelfAnActiveMember)
        }
    }

    // MARK: - Helpers

    func qualifiedID(for conversation: ZMConversation) -> QualifiedID {
        var qualifiedID: QualifiedID!
        syncMOC.performGroupedAndWait {
            qualifiedID = QualifiedID(
                uuid: conversation.remoteIdentifier!,
                domain: conversation.domain!
            )
        }
        return qualifiedID
    }

    func startSlowSync() {
        syncMOC.performGroupedAndWait {
            self.mockSyncProgress.currentSyncPhase = .fetchingConversations
        }
    }

    func fetchConversation(_ conversation: ZMConversation, with response: ZMTransportResponse, apiVersion: APIVersion) {
        syncMOC.performGroupedAndWait {
            // given
            conversation.needsToBeUpdatedFromBackend = true
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([conversation])) }

            // when
            let request = self.sut.nextRequest(for: apiVersion)!
            request.complete(with: response)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func fetchConversationListDuringSlowSync() {
        syncMOC.performGroupedAndWait {
            let qualifiedConversationID = QualifiedID(
                uuid: self.groupConversation.remoteIdentifier!,
                domain: self.groupConversation.domain!
            )

            let listRequest = self.sut.nextRequest(for: self.apiVersion)!
            guard let listPayload = Payload.PaginationStatus(listRequest) else {
                return XCTFail("List payload is invalid")
            }

            listRequest.complete(with: self.successfulResponse(
                request: listPayload,
                conversations: [qualifiedConversationID]
            ))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func fetchConversationListDuringSlowSyncWithEmptyResponse() {
        syncMOC.performGroupedAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)!
            guard let listPayload = Payload.PaginationStatus(request) else {
                return XCTFail("List payload is invalid")
            }

            request.complete(with: self.successfulResponse(request: listPayload, conversations: []))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func fetchConversationListDuringSlowSyncWithPermanentError() {
        syncMOC.performGroupedAndWait {
            let request = self.sut.nextRequest(for: self.apiVersion)!
            request.complete(with: self.responseFailure(code: 404, label: .noEndpoint, apiVersion: .v1))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func fetchConversationsDuringSlowSync(
        notFound: [QualifiedID] = [],
        failed: [QualifiedID] = []
    ) {
        syncMOC.performGroupedAndWait {
            // when
            let request = self.sut.nextRequest(for: self.apiVersion)!

            guard let payload = Payload.QualifiedUserIDList(request) else {
                return XCTFail("Payload is invalid")
            }

            request.complete(with: self.successfulResponse(request: payload, notFound: notFound, failed: failed))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func successfulResponse(
        request: Payload.PaginationStatus,
        conversations: [QualifiedID]
    ) -> ZMTransportResponse {
        let payload = Payload.PaginatedQualifiedConversationIDList(
            conversations: conversations,
            pagingState: "",
            hasMore: false
        )

        let payloadData = payload.payloadData()!
        let payloadString = String(bytes: payloadData, encoding: .utf8)!
        let response = ZMTransportResponse(
            payload: payloadString as ZMTransportData,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: apiVersion.rawValue
        )

        return response
    }

    func successfulResponse(
        request: Payload.QualifiedUserIDList,
        notFound: [QualifiedID],
        failed: [QualifiedID]
    ) -> ZMTransportResponse {
        let found = request.qualifiedIDs.map { conversation(uuid: $0.uuid, domain: $0.domain) }
        let payload = Payload.QualifiedConversationList(found: found, notFound: notFound, failed: failed)
        let payloadData = payload.payloadData()!
        let payloadString = String(bytes: payloadData, encoding: .utf8)!
        let response = ZMTransportResponse(
            payload: payloadString as ZMTransportData,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: apiVersion.rawValue
        )

        return response
    }

    func conversation(uuid: UUID, domain: String?, type: BackendConversationType = .group) -> Payload.Conversation {
        Payload.Conversation.stub(
            id: uuid,
            type: type
        )
    }
}
