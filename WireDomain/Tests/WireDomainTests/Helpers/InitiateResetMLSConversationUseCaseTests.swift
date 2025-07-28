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

import WireDataModel
import WireDomain
import XCTest
@testable import WireDataModelSupport
@testable import WireDomainPackage
@testable import WireDomainSupport
@testable import WireNetworkSupport

final class InitiateResetMLSConversationUseCaseTests: XCTestCase {

    private lazy var mockAPI = MockMLSAPI()
    private lazy var mockMLSService = MockMLSServiceInterface()
    private lazy var mockConversationLocalStore = MockConversationLocalStoreProtocol()
    private lazy var modelHelper = ModelHelper()
    private lazy var coreDataStackHelper = CoreDataStackHelper()
    private var coreDataStack: CoreDataStack!

    override func setUp() async throws {

        mockAPI.resetMLSConversationEpochGroupID_MockMethod = { _, _ in }
        mockMLSService.wipeGroup_MockMethod = { _ in }
        mockMLSService.establishGroupForWithRemovalKeys_MockMethod = { _, _, _ in
            MLSCipherSuite.MLS_256_DHKEMP521_AES256GCM_SHA512_P521
        }

        coreDataStack = try await coreDataStackHelper.createStack()
        let conversation = await coreDataStack.syncContext.perform { [self] in
            modelHelper.createMLSConversation(
                mlsGroupID: MLSGroupID.random(),
                mlsStatus: .pendingJoin,
                conversationType: .group,
                epoch: 99,
                in: coreDataStack.syncContext
            )
        }

        mockConversationLocalStore.fetchMLSConversationGroupID_MockValue = conversation
        mockConversationLocalStore.qualifiedIDFor_MockValue = await coreDataStack.syncContext.perform {
            conversation.qualifiedID
        }
        mockConversationLocalStore
            .localParticipantsExcludingSelfAsMLSUsersIn_MockValue = [MLSUser(WireDataModel.QualifiedID.random())]
    }

    func testInvoke() async {

        let sut = InitiateResetMLSConversationUseCase(
            api: mockAPI,
            mlsService: mockMLSService,
            conversationLocalStore: mockConversationLocalStore
        )

        let groupID = MLSGroupID.random()
        // When
        await sut.invoke(groupID: groupID, epoch: 99)

        // Then
        XCTAssertEqual(mockConversationLocalStore.fetchMLSConversationGroupID_Invocations.count, 1)
        XCTAssertEqual(mockAPI.resetMLSConversationEpochGroupID_Invocations.count, 1)
        XCTAssertEqual(mockMLSService.wipeGroup_Invocations.first, groupID)
        XCTAssertEqual(mockMLSService.establishGroupForWithRemovalKeys_Invocations.first?.groupID, groupID)
    }

    func testInvoke_DoNothingWhen_WhenConversationNotFound() async {

        mockConversationLocalStore.fetchMLSConversationGroupID_MockValue = .some(nil)

        let sut = InitiateResetMLSConversationUseCase(
            api: mockAPI,
            mlsService: mockMLSService,
            conversationLocalStore: mockConversationLocalStore
        )

        let groupID = MLSGroupID.random()
        // When
        await sut.invoke(groupID: groupID, epoch: 99)

        // Then
        XCTAssertEqual(mockConversationLocalStore.fetchMLSConversationGroupID_Invocations.count, 1)
        XCTAssertEqual(mockAPI.resetMLSConversationEpochGroupID_Invocations.count, 0)
        XCTAssertEqual(mockMLSService.wipeGroup_Invocations.count, 0)
        XCTAssertEqual(mockMLSService.establishGroupForWithRemovalKeys_Invocations.count, 0)
    }

}
