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
    var mockMLSController: MockMLSController!
    var mockMessage: MockOTREntity!

    override func setUp() {
        super.setUp()
        sut = MLSMessageSync(context: syncMOC)
        mockMLSController = MockMLSController()
        mockMessage = MockOTREntity(
            messageData: Data([1, 2, 3]),
            conversation: groupConversation,
            context: syncMOC
        )

        syncMOC.performGroupedBlockAndWait {
            self.groupConversation.mlsGroupID = MLSGroupID([1, 2, 3])
            self.groupConversation.messageProtocol = .mls
            self.syncMOC.test_setMockMLSController(self.mockMLSController)
        }
    }

    override func tearDown() {
        sut = nil
        mockMLSController = nil
        mockMessage = nil
        super.tearDown()
    }

    // MARK: - Requests available

    func test_ItNotifiesNewRequestAvailable_WhenSyncingMessage() {
        // Expect
        expectation(
            forNotification: Notification.Name("RequestAvailableNotification"),
            object: nil,
            handler: nil
        )

        // When
        sut.sync(mockMessage) { _, _ in
            // No op
        }

        // Then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: - Request generation

    func test_RequestGeneration_Success() throws {
        syncMOC.performGroupedBlockAndWait {
            // When
            let result = self.sut.transcoder.request(forEntity: self.mockMessage, apiVersion: .v2)

            // Then
            guard let request = result else {
                XCTFail("no request generated")
                return
            }

            XCTAssertEqual(request.path, "/v2/mls/messages")
            XCTAssertEqual(request.method, .methodPOST)
            XCTAssertEqual(request.binaryDataType, "message/mls")
            XCTAssertEqual(request.apiVersion, 2)

            let expectedEncryptedMessage = self.mockMessage.messageData + [000]
            XCTAssertEqual(request.binaryData, expectedEncryptedMessage)
        }
    }

    func test_RequestGeneration_Failure_OldAPIVersion() {
        syncMOC.performGroupedBlockAndWait {
            // Then
            XCTAssertNil(self.sut.transcoder.request(
                forEntity: self.mockMessage,
                apiVersion: .v0
            ))

            XCTAssertNil(self.sut.transcoder.request(
                forEntity: self.mockMessage,
                apiVersion: .v1
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
                apiVersion: .v2
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
                apiVersion: .v2
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
            apiVersion: 2
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
            apiVersion: 2
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
