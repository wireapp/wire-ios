//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

@testable import WireDataModel
@testable import WireDataModelSupport

class MLSConversationVerificationStatusProviderTests: ZMConversationTestsBase {

    var sut: MLSConversationVerificationStatusProvider!
    var e2eIVerificationStatusService: MockE2eIVerificationStatusServiceInterface!

    override func setUp() {
        super.setUp()

        e2eIVerificationStatusService = MockE2eIVerificationStatusServiceInterface()
        sut = MLSConversationVerificationStatusProvider(e2eIVerificationStatusService: e2eIVerificationStatusService,
                                                        syncContext: syncMOC)
    }

    override func tearDown() {
        e2eIVerificationStatusService = nil
        sut = nil

        super.tearDown()
    }

    func test_itUpdatesConversation_toVerifiedStatus() async throws {
        // Mock
        e2eIVerificationStatusService.getConversationStatusGroupID_MockMethod = {_ in
            return .verified
        }

        // Given
        let groupID = MLSGroupID.random()
        let mockConversation = await syncMOC.perform { [syncMOC] in
            let conversation =  ZMConversation.insertNewObject(in: syncMOC)
            conversation.mlsGroupID = groupID
            conversation.mlsVerificationStatus = .notVerified
            return conversation
        }

        // When
        try await sut.updateStatus(groupID)

        // Then
        await syncMOC.perform {
            XCTAssertEqual(mockConversation.mlsVerificationStatus, .verified)
            guard let lastMessage = mockConversation.lastMessage as? ZMSystemMessage else {
                return XCTFail()
            }
            XCTAssertEqual(lastMessage.systemMessageType, .conversationIsVerified)
        }
    }

    func test_itUpdatesConversation_fromVerifiedToDegraded() async throws {
        // Mock
        e2eIVerificationStatusService.getConversationStatusGroupID_MockMethod = {_ in
            return .notVerified
        }

        // Given
        let groupID = MLSGroupID.random()
        let mockConversation = await syncMOC.perform { [syncMOC] in
            let conversation =  ZMConversation.insertNewObject(in: syncMOC)
            conversation.mlsGroupID = groupID
            conversation.mlsVerificationStatus = .verified
            return conversation
        }

        // When
        try await sut.updateStatus(groupID)

        // Then
        await syncMOC.perform {
            XCTAssertEqual(mockConversation.mlsVerificationStatus, .degraded)
            guard let lastMessage = mockConversation.lastMessage as? ZMSystemMessage else {
                return XCTFail()
            }
            XCTAssertEqual(lastMessage.systemMessageType, .conversationIsDegraded)
        }
    }

    func test_itDoesNotUpdateConversation_newStatusIsSame() async throws {
        // Mock
        e2eIVerificationStatusService.getConversationStatusGroupID_MockMethod = {_ in
            return .notVerified
        }

        // Given
        let groupID = MLSGroupID.random()
        let mockConversation = await syncMOC.perform { [syncMOC] in
            let conversation =  ZMConversation.insertNewObject(in: syncMOC)
            conversation.mlsGroupID = groupID
            conversation.mlsVerificationStatus = .notVerified
            return conversation
        }

        // When
        try await sut.updateStatus(groupID)

        // Then
        await syncMOC.perform {
            XCTAssertEqual(mockConversation.mlsVerificationStatus, .notVerified)
        }
    }

    func test_itDoesNotUpdateConversation_wrongMLSGroupId() async throws {
        // Mock
        e2eIVerificationStatusService.getConversationStatusGroupID_MockMethod = {_ in
            return .notVerified
        }

        // Given
        let expectedError = E2eIVerificationStatusService.E2eIVerificationStatusError.missingConversation
        let groupID = MLSGroupID(Data([1, 2, 3]))
        let mockConversation = await syncMOC.perform { [syncMOC] in
            let conversation =  ZMConversation.insertNewObject(in: syncMOC)
            conversation.mlsGroupID = MLSGroupID.random()
            conversation.mlsVerificationStatus = nil
            return conversation
        }

        // Then
        await assertItThrows(error: expectedError) {
            // When
            try await sut.updateStatus(groupID)
        }
    }

    func test_itDoesNotUpdateConversation_failedToFetchVerificationStatus() async throws {
        // Mock
        let error = E2eIVerificationStatusService.E2eIVerificationStatusError.failedToFetchVerificationStatus
        e2eIVerificationStatusService.getConversationStatusGroupID_MockError = error

        // Given
        let groupID = MLSGroupID.random()
        let mockConversation = await syncMOC.perform { [syncMOC] in
            let conversation =  ZMConversation.insertNewObject(in: syncMOC)
            conversation.mlsGroupID = groupID
            conversation.mlsVerificationStatus = nil
            return conversation
        }

        // Then
        await assertItThrows(error: error) {
            // When
            try await sut.updateStatus(groupID)
        }
    }

}
