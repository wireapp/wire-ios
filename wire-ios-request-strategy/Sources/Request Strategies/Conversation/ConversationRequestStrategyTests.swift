//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
    var mockRemoveLocalConversation: MockLocalConversationRemovalUseCase!
    var mockMLSService: MockMLSServiceInterface!

    override func setUp() {
        super.setUp()

        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .online
        mockRemoveLocalConversation = MockLocalConversationRemovalUseCase()
        mockMLSService = MockMLSServiceInterface()
    }

    override func tearDown() {
        sut = nil
        mockApplicationStatus = nil
        mockRemoveLocalConversation = nil

        super.tearDown()
    }

    func createSUT(apiVersion: APIVersion) -> ConversationRequestStrategy {
        ConversationRequestStrategy(
            withManagedObjectContext: syncMOC,
            applicationStatus: mockApplicationStatus,
            mlsService: mockMLSService,
            removeLocalConversation: mockRemoveLocalConversation,
            apiVersion: apiVersion,
            localDomain: "wire.com",
            isFederationEnabled: false
        )
    }

    // MARK: - Request generation

    func testThatRequestToUpdateConversationNameIsGenerated_WhenModifiedKeyIsSet() {
        syncMOC.performGroupedAndWait {
            // given
            let apiVersion = APIVersion.v1
            self.sut = self.createSUT(apiVersion: apiVersion)
            let domain = self.groupConversation.domain!
            let conversationID = self.groupConversation.remoteIdentifier!
            self.groupConversation.userDefinedName = "Hello World"
            let conversationUserDefinedNameKeySet: Set<AnyHashable> = [ZMConversationUserDefinedNameKey]
            self.groupConversation.setLocallyModifiedKeys(conversationUserDefinedNameKeySet)
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([self.groupConversation])) }

            // when
            let request = self.sut.nextRequest(for: apiVersion)!
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
            let apiVersion = APIVersion.v1
            self.sut = self.createSUT(apiVersion: apiVersion)
            let domain = self.groupConversation.domain!
            let conversationID = self.groupConversation.remoteIdentifier!
            self.groupConversation.isArchived = true
            let conversationArchivedChangedTimeStampKeySet: Set<AnyHashable> =
                [ZMConversationArchivedChangedTimeStampKey]
            self.groupConversation.setLocallyModifiedKeys(conversationArchivedChangedTimeStampKeySet)
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([self.groupConversation])) }

            // when
            let request = self.sut.nextRequest(for: apiVersion)!
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
            let apiVersion = APIVersion.v1
            self.sut = self.createSUT(apiVersion: apiVersion)
            let domain = self.groupConversation.domain!
            let conversationID = self.groupConversation.remoteIdentifier!
            self.groupConversation.mutedMessageTypes = .all
            let conversationSilencedChangedTimeStampKeySet: Set<AnyHashable> =
                [ZMConversationSilencedChangedTimeStampKey]
            self.groupConversation.setLocallyModifiedKeys(conversationSilencedChangedTimeStampKeySet)
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([self.groupConversation])) }

            // when
            let request = self.sut.nextRequest(for: apiVersion)!
            let payload = Payload.UpdateConversationStatus(request)

            // then
            XCTAssertEqual(request.path, "/v1/conversations/\(domain)/\(conversationID.transportString())/self")
            XCTAssertEqual(request.method, .put)
            XCTAssertEqual(payload?.mutedStatus, Int(MutedMessageTypes.all.rawValue))
        }
    }

    // MARK: - Response processing

    func testThatConversationResetsNeedsToBeUpdatedFromBackend_OnPermanentErrors() {
        // given
        let apiVersion = APIVersion.v1
        sut = createSUT(apiVersion: apiVersion)
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
        let apiVersion = APIVersion.v1
        sut = createSUT(apiVersion: apiVersion)
        let response = responseFailure(code: 404, label: .notFound, apiVersion: apiVersion)

        // when
        fetchConversation(groupConversation, with: response, apiVersion: apiVersion)

        // then
        syncMOC.performAndWait {
            XCTAssertEqual(
                mockRemoveLocalConversation.invokeCalls,
                [groupConversation]
            )
        }
    }

    func testThatSelfUserIsRemovedFromParticipantsList_WhenResponseIs_403() {
        // given
        let apiVersion = APIVersion.v1
        sut = createSUT(apiVersion: apiVersion)
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

    func fetchConversation(_ conversation: ZMConversation, with response: ZMTransportResponse, apiVersion: APIVersion) {
        syncMOC.performGroupedAndWait {
            // given
            self.sut.fetch([conversation], for: apiVersion)

            // when
            if let request = self.sut.nextRequest(for: apiVersion) {
                request.complete(with: response)
            } else {
                XCTFail("could not produce a request")
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func fetchConversationListDuringSlowSync(apiVersion: APIVersion) {
        syncMOC.performGroupedAndWait {
            let qualifiedConversationID = QualifiedID(
                uuid: self.groupConversation.remoteIdentifier!,
                domain: self.groupConversation.domain!
            )

            let listRequest = self.sut.nextRequest(for: apiVersion)!
            guard let listPayload = Payload.PaginationStatus(listRequest) else {
                return XCTFail("List payload is invalid")
            }

            listRequest.complete(with: self.successfulResponse(
                request: listPayload,
                conversations: [qualifiedConversationID],
                apiVersion: apiVersion
            ))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func fetchConversationListDuringSlowSyncWithEmptyResponse(apiVersion: APIVersion) {
        syncMOC.performGroupedAndWait {
            let request = self.sut.nextRequest(for: apiVersion)!
            guard let listPayload = Payload.PaginationStatus(request) else {
                return XCTFail("List payload is invalid")
            }

            request.complete(with: self.successfulResponse(
                request: listPayload,
                conversations: [],
                apiVersion: apiVersion
            ))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func fetchConversationListDuringSlowSyncWithPermanentError(apiVersion: APIVersion) {
        syncMOC.performGroupedAndWait {
            let request = self.sut.nextRequest(for: apiVersion)!
            request.complete(with: self.responseFailure(code: 404, label: .noEndpoint, apiVersion: .v1))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func fetchConversationsDuringSlowSync(
        notFound: [QualifiedID] = [],
        failed: [QualifiedID] = [],
        apiVersion: APIVersion
    ) {
        syncMOC.performGroupedAndWait {

            // when
            let request = self.sut.nextRequest(for: apiVersion)!

            guard let payload = Payload.QualifiedUserIDList(request) else {
                return XCTFail("Payload is invalid")
            }

            request.complete(with: self.successfulResponse(
                request: payload,
                notFound: notFound,
                failed: failed,
                apiVersion: apiVersion
            ))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func successfulResponse(
        request: Payload.PaginationStatus,
        conversations: [QualifiedID],
        apiVersion: APIVersion
    ) -> ZMTransportResponse {
        let payload = Payload.PaginatedQualifiedConversationIDList(
            conversations: conversations,
            pagingState: "",
            hasMore: false
        )

        let payloadData = payload.payloadData()!
        let payloadString = String(bytes: payloadData, encoding: .utf8)!
        return ZMTransportResponse(
            payload: payloadString as ZMTransportData,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: apiVersion.rawValue
        )
    }

    func successfulResponse(
        request: Payload.QualifiedUserIDList,
        notFound: [QualifiedID],
        failed: [QualifiedID],
        apiVersion: APIVersion
    ) -> ZMTransportResponse {

        let found = request.qualifiedIDs.map { conversation(uuid: $0.uuid, domain: $0.domain) }
        let payload = Payload.QualifiedConversationList(found: found, notFound: notFound, failed: failed)
        let payloadData = payload.payloadData(apiVersion: apiVersion)!
        let payloadString = String(bytes: payloadData, encoding: .utf8)!
        return ZMTransportResponse(
            payload: payloadString as ZMTransportData,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: apiVersion.rawValue
        )
    }

    func conversation(uuid: UUID, domain: String?, type: BackendConversationType = .group) -> Payload.Conversation {
        Payload.Conversation.stub(
            id: uuid,
            type: type
        )
    }
}
