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

final class MessageSyncTests: MessagingTestBase {

    var sut: MessageSync<MockOTREntity>!
    var mockAppStatus: MockApplicationStatus!
    var conversationID: UUID!

    override func setUp() {
        super.setUp()
        mockAppStatus = MockApplicationStatus()
        sut = MessageSync(context: syncMOC, appStatus: mockAppStatus)
        conversationID = .create()

        syncMOC.performGroupedBlockAndWait {
            self.groupConversation.domain = "example.com"
            self.groupConversation.remoteIdentifier = self.conversationID
        }
    }

    override func tearDown() {
        mockAppStatus = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Syncing message

    func test_SyncingMessage_Proteus() async {
        syncMOC.performGroupedBlockAndWait {
            // Given
            self.groupConversation.messageProtocol = .proteus

            let message = MockOTREntity(
                conversation: self.groupConversation,
                context: self.syncMOC
            )

            // When
            self.sut.sync(message) { _, _ in }
        }
            // Then
            guard let request = await self.sut.nextRequest(for: .v1) else {
                XCTFail("no request generated")
                return
            }

            XCTAssertEqual(request.path, "/v1/conversations/example.com/\(self.conversationID.transportString())/proteus/messages")
            XCTAssertEqual(request.method, .methodPOST)
            XCTAssertEqual(request.binaryDataType, "application/x-protobuf")
    }

    func test_SyncingMessage_MLS() async {
        let awaitExpectation = self.expectation(description: "wait for next request")
        syncMOC.performGroupedBlockAndWait {
            // Given
            self.groupConversation.messageProtocol = .mls
            self.groupConversation.mlsGroupID = MLSGroupID([1, 2, 3])
            self.syncMOC.mlsService = MockMLSService()

            let message = MockOTREntity(
                conversation: self.groupConversation,
                context: self.syncMOC
            )
            // When
            self.sut.sync(message) { _, _ in
                // Then
                Task {
                    guard let request = await self.sut.nextRequest(for: .v5) else {
                        XCTFail("no request generated")
                        awaitExpectation.fulfill()
                        return
                    }

                    XCTAssertEqual(request.path, "/v5/mls/messages")
                    XCTAssertEqual(request.method, .methodPOST)
                    XCTAssertEqual(request.binaryDataType, "message/mls")
                    awaitExpectation.fulfill()
                }
            }
        }

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        await fulfillment(of: [awaitExpectation], timeout: 1.0)
    }

    func test_ItDoesntGenerate_SyncingMessage_MLS_Request() async {
        let apiVersions: [APIVersion] = [.v0, .v1, .v2, .v3, .v4]
        for version in apiVersions {
            await internalTest_ItDoesntGenerateARequest(apiVersion: version)
        }
    }

    private func internalTest_ItDoesntGenerateARequest(apiVersion: APIVersion) async {
        let awaitExpectation = self.expectation(description: "wait for next request")

        syncMOC.performGroupedBlockAndWait {
            // Given
            self.groupConversation.messageProtocol = .mls
            self.groupConversation.mlsGroupID = MLSGroupID([1, 2, 3])
            self.syncMOC.mlsService = MockMLSService()

            let message = MockOTREntity(
                conversation: self.groupConversation,
                context: self.syncMOC
            )

            // When
            self.sut.sync(message) { _, _ in
                // Then
                Task {
                    let request = await self.sut.nextRequest(for: apiVersion)
                    XCTAssertNil(request)
                    awaitExpectation.fulfill()
                }
            }
        }

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        await fulfillment(of: [awaitExpectation], timeout: 1.0)
    }

    func test_SyncingMessage_Failed_MessageProtocolMissing() {
        syncMOC.performGroupedBlockAndWait {
            // Given an entity with no conversation.
            let message = MockOTREntity(
                conversation: nil,
                context: self.syncMOC
            )

            // Expectation
            let didFail = self.expectation(description: "did fail")

            // When
            self.sut.sync(message) { result, _ in
                // Then
                guard case .failure(EntitySyncError.messageProtocolMissing) = result else {
                    XCTFail("unexpected error")
                    return
                }

                didFail.fulfill()
            }

            XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        }
    }

}
