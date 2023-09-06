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

final class MLSMessageSyncTests: MessagingTestBase {

    var sut: MLSMessageSync<MockOTREntity>!
    var mockMLSService: MockMLSService!
    var mockMessage: MockOTREntity!

    override func setUp() {
        super.setUp()
        sut = MLSMessageSync(context: syncMOC)
        mockMLSService = MockMLSService()
        mockMessage = MockOTREntity(
            messageData: Data([1, 2, 3]),
            conversation: groupConversation,
            context: syncMOC
        )

        syncMOC.performGroupedBlockAndWait {
            self.groupConversation.mlsGroupID = MLSGroupID([1, 2, 3])
            self.groupConversation.messageProtocol = .mls
            self.syncMOC.mlsService = self.mockMLSService
        }
    }

    override func tearDown() {
        sut = nil
        mockMLSService = nil
        mockMessage = nil
        super.tearDown()
    }

    // MARK: - Message syncing

    func test_SyncMessage() {
        syncMOC.performGroupedBlockAndWait {
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
        XCTAssertEqual(self.mockMLSService.calls.commitPendingProposalsInGroup, [MLSGroupID([1, 2, 3])])
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
            XCTAssertEqual(request.method, .methodPOST)
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
