//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
@testable import WireRequestStrategy

private typealias MockMLSMessageSync = MLSMessageSync<MockOTREntity>
private typealias MockMLSMessageTranscoder = MockMLSMessageSync.Transcoder<MockOTREntity>

private class MockDependencyEntitySync: DependencyEntitySync<MockMLSMessageTranscoder> {

    typealias SynchronizeMock = (MockOTREntity, EntitySyncHandler?) -> Void

    var synchronizeMocks = [SynchronizeMock]()

    override func synchronize(entity: MockOTREntity, completion: EntitySyncHandler? = nil) {
        guard !synchronizeMocks.isEmpty else { return }
        let mock = synchronizeMocks.removeFirst()
        mock(entity, completion)
    }
}

final class MLSMessageSyncTests: MessagingTestBase {

    private var sut: MLSMessageSync<MockOTREntity>!
    private var mockMLSService: MockMLSService!
    private var mockMessage: MockOTREntity!
    private var mockDependencySync: MockDependencyEntitySync!
    private let groupID = MLSGroupID([1, 2, 3])

    override func setUp() {
        super.setUp()
        mockDependencySync = MockDependencyEntitySync(
            transcoder: MockMLSMessageTranscoder(context: syncMOC),
            context: syncMOC
        )
        sut = MLSMessageSync(
            context: syncMOC,
            dependencySync: mockDependencySync
        )
        mockMLSService = MockMLSService()
        mockMessage = MockOTREntity(
            messageData: Data([1, 2, 3]),
            conversation: groupConversation,
            context: syncMOC
        )

        syncMOC.performAndWait {
            self.groupConversation.mlsGroupID = groupID
            self.groupConversation.messageProtocol = .mls
            self.syncMOC.mlsService = self.mockMLSService
        }
    }

    override func tearDown() {
        sut = nil
        mockMLSService = nil
        mockMessage = nil
        mockDependencySync = nil
        super.tearDown()
    }

    // MARK: - Message syncing

    func test_SyncMessage() {
        syncMOC.performAndWait {
            // Expect
            self.expectation(
                forNotification: Notification.Name("RequestAvailableNotification"),
                object: nil,
                handler: nil
            )

            // When
            self.sut.sync(self.mockMessage) { _, _ in
                // No op
            }
        }

        // Then
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))

        // Then it preemptively commits pending proposals.
        XCTAssertEqual(self.mockMLSService.calls.commitPendingProposalsInGroup, [groupID])
    }

    func test_SyncMessage_RepairsGroupAndRetriesToSync_OnMLSStaleMessage() {
        // Given

        // Mock stale message response on first synchronization
        mockDependencySync.synchronizeMocks.append({ _, completion in
            let response = self.responseFailure(
                code: 409,
                label: .mlsStaleMessage,
                apiVersion: .v5
            )
            completion?(.failure(.gaveUpRetrying), response)
        })

        // Mock group repair and set expectation
        let repairExpectation = XCTestExpectation(description: "fetched and repaired group")
        mockMLSService.fetchAndRepairGroupMock = { groupID in
            XCTAssertEqual(self.groupID, groupID)
            repairExpectation.fulfill()
        }

        // Mock success response
        let successResponse = ZMTransportResponse(
            payload: nil,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: 5
        )

        // Mock success on the second synchronization and set expectation
        let retryExpectation = XCTestExpectation(description: "retried synchronization")
        mockDependencySync.synchronizeMocks.append({ _, completion in
            completion?(.success(()), successResponse)
            retryExpectation.fulfill()
        })

        // When
        syncMOC.performAndWait {
            self.sut.sync(mockMessage) { _, _ in }
        }

        // Then
        wait(for: [repairExpectation, retryExpectation], timeout: 0.5)
    }

    // MARK: - Request generation

    func test_ItGeneratesRequests_APIV5() throws {
        test_RequestGeneration_Success(apiVersion: .v5)
    }

    func test_ItDoesNotGenerateRequests_APIBelowV5() throws {
        [.v0, .v1, .v2, .v3, .v4].forEach {
            internalTest_RequestGeneration_Failure(apiVersion: $0)
        }
    }

    func test_RequestGeneration_Success(apiVersion: APIVersion) {
        syncMOC.performGroupedBlockAndWait {
            // When
            let result = self.sut.transcoder.request(forEntity: self.mockMessage, apiVersion: apiVersion)

            // Then
            guard let request = result else {
                XCTFail("no request generated")
                return
            }

            XCTAssertEqual(request.path, "/v\(apiVersion.rawValue)/mls/messages")
            XCTAssertEqual(request.method, .post)
            XCTAssertEqual(request.binaryDataType, "message/mls")
            XCTAssertEqual(request.apiVersion, apiVersion.rawValue)

            let expectedEncryptedMessage = self.mockMessage.messageData + [000]
            XCTAssertEqual(request.binaryData, expectedEncryptedMessage)
        }
    }

    func internalTest_RequestGeneration_Failure(apiVersion: APIVersion) {
        syncMOC.performGroupedBlockAndWait {
            // Then
            XCTAssertNil(self.sut.transcoder.request(
                forEntity: self.mockMessage,
                apiVersion: apiVersion
            ))
        }
    }

    func test_RequestGeneration_Failure_ProteusProtocol() {
        syncMOC.performGroupedBlockAndWait {
            // Given
            self.groupConversation.messageProtocol = .proteus

            // Then
            XCTAssertNil(self.sut.transcoder.request(
                forEntity: self.mockMessage,
                apiVersion: .v5
            ))
        }
    }

    func test_RequestGeneration_Failure_NoMLSGroupID() {
        syncMOC.performGroupedBlockAndWait {
            // Given
            self.groupConversation.mlsGroupID = nil

            // Then
            XCTAssertNil(self.sut.transcoder.request(
                forEntity: self.mockMessage,
                apiVersion: .v5
            ))
        }
    }

    // MARK: - Response handling

    func test_ResponseHandling_Success() {
        // Given
        let response = ZMTransportResponse(
            payload: nil,
            httpStatus: 201,
            transportSessionError: nil,
            apiVersion: 5
        )

        // When
        sut.transcoder.request(
            forEntity: mockMessage,
            didCompleteWithResponse: response
        )

        // Then
        XCTAssertTrue(mockMessage.isDelivered)
    }

    func test_ResponseHandling_Failure() {
        // Given
        let response = ZMTransportResponse(
            payload: nil,
            httpStatus: 409,
            transportSessionError: nil,
            apiVersion: 5
        )

        // When
        sut.transcoder.request(
            forEntity: mockMessage,
            didCompleteWithResponse: response
        )

        // Then
        XCTAssertFalse(mockMessage.isDelivered)
    }

}

extension MockOTREntity: MLSMessage {

    func encryptForTransport(using encrypt: (Data) throws -> Data) throws -> Data {
        return try encrypt(messageData)
    }

}
