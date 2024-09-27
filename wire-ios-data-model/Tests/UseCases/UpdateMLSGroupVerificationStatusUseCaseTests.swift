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
@testable import WireDataModel
@testable import WireDataModelSupport

class UpdateMLSGroupVerificationStatusUseCaseTests: ZMConversationTestsBase {
    var sut: UpdateMLSGroupVerificationStatusUseCaseProtocol!
    var e2eIVerificationStatusService: MockE2EIVerificationStatusServiceInterface!
    var mockFeatureRepository: MockFeatureRepositoryInterface!

    override func setUp() {
        super.setUp()

        mockFeatureRepository = MockFeatureRepositoryInterface()
        mockFeatureRepository.fetchE2EI_MockValue = Feature.E2EI(status: .enabled)
        e2eIVerificationStatusService = MockE2EIVerificationStatusServiceInterface()
        sut = UpdateMLSGroupVerificationStatusUseCase(
            e2eIVerificationStatusService: e2eIVerificationStatusService,
            syncContext: syncMOC,
            featureRepository: mockFeatureRepository
        )
    }

    override func tearDown() {
        mockFeatureRepository = nil
        e2eIVerificationStatusService = nil
        sut = nil

        super.tearDown()
    }

    func test_itUpdatesConversation_toVerifiedStatus() async throws {
        // Mock
        e2eIVerificationStatusService.getConversationStatusGroupID_MockMethod = { _ in
            .verified
        }

        // Given
        let groupID = MLSGroupID.random()
        let mockConversation = await syncMOC.perform { [syncMOC] in
            let conversation = ZMConversation.insertNewObject(in: syncMOC)
            conversation.mlsGroupID = groupID
            conversation.mlsVerificationStatus = .notVerified
            return conversation
        }

        // When
        try await sut.invoke(for: mockConversation, groupID: groupID)

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
        e2eIVerificationStatusService.getConversationStatusGroupID_MockMethod = { _ in
            .notVerified
        }

        // Given
        let groupID = MLSGroupID.random()
        let mockConversation = await syncMOC.perform { [syncMOC] in
            let conversation = ZMConversation.insertNewObject(in: syncMOC)
            conversation.mlsGroupID = groupID
            conversation.mlsVerificationStatus = .verified
            return conversation
        }

        // When
        try await sut.invoke(for: mockConversation, groupID: groupID)

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
        e2eIVerificationStatusService.getConversationStatusGroupID_MockMethod = { _ in
            .notVerified
        }

        // Given
        let groupID = MLSGroupID.random()
        let mockConversation = await syncMOC.perform { [syncMOC] in
            let conversation = ZMConversation.insertNewObject(in: syncMOC)
            conversation.mlsGroupID = groupID
            conversation.mlsVerificationStatus = .notVerified
            return conversation
        }

        // When
        try await sut.invoke(for: mockConversation, groupID: groupID)

        // Then
        await syncMOC.perform {
            XCTAssertEqual(mockConversation.mlsVerificationStatus, .notVerified)
        }
    }

    func test_itDoesNotUpdateConversation_failedToFetchVerificationStatus() async throws {
        // Mock
        let error = E2EIVerificationStatusService.E2EIVerificationStatusError.failedToFetchVerificationStatus
        e2eIVerificationStatusService.getConversationStatusGroupID_MockError = error

        // Given
        let groupID = MLSGroupID.random()
        let mockConversation = await syncMOC.perform { [syncMOC] in
            let conversation = ZMConversation.insertNewObject(in: syncMOC)
            conversation.mlsGroupID = groupID
            conversation.mlsVerificationStatus = nil
            return conversation
        }

        // Then
        await assertItThrows(error: error) {
            // When
            try await sut.invoke(for: mockConversation, groupID: groupID)
        }
    }
}
