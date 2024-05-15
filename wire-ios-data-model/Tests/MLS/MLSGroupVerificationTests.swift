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

import Combine
import WireDataModelSupport
import XCTest

@testable import WireDataModel

final class MLSGroupVerificationTests: XCTestCase {

    private let coreDataStackHelper = CoreDataStackHelper()
    private let modelHelper = ModelHelper()

    private var mockCoreDataStack: CoreDataStack!
    private var mockMLService: MockMLSServiceInterface!
    private var mockUpdateUseCase: MockUpdateMLSGroupVerificationStatusUseCaseProtocol!

    private var syncContext: NSManagedObjectContext { mockCoreDataStack.syncContext }

    override func setUp() async throws {
        try await super.setUp()

        mockCoreDataStack = try await coreDataStackHelper.createStack()
        mockMLService = MockMLSServiceInterface()
        mockUpdateUseCase = MockUpdateMLSGroupVerificationStatusUseCaseProtocol()
    }

    override func tearDown() async throws {
        mockUpdateUseCase = nil
        mockMLService = nil
        mockCoreDataStack = nil

        try coreDataStackHelper.cleanupDirectory()

        try await super.tearDown()
    }

    // MARK: Tests

    func testStartObserving_givenEpochChange_thenInvokeUseCase() async {
        // given
        let expectation = self.expectation(description: "")

        let mlsGroupID: MLSGroupID = .random()
        await syncContext.perform { [self] in
            _ = modelHelper.createMLSConversation(mlsGroupID: mlsGroupID, in: syncContext)
        }

        var streamContinuation: AsyncStream<MLSGroupID>.Continuation!
        mockMLService.epochChanges_MockValue = AsyncStream {
            streamContinuation = $0
        }
        mockUpdateUseCase.invokeForGroupID_MockMethod = { _, _ in
            expectation.fulfill()
        }

        let mlsGroupVerification = makeMLSGroupVerification()

        // when
        mlsGroupVerification.startObserving()
        streamContinuation.yield(mlsGroupID)

        await fulfillment(of: [expectation], timeout: 0.5)

        // then
        let groupIDs = mockUpdateUseCase.invokeForGroupID_Invocations.map(\.groupID)
        XCTAssertEqual(groupIDs, [mlsGroupID])
    }

    func testUpdateConversationByGroupID_givenMLSGroupID() async {
        // given
        mockUpdateUseCase.invokeForGroupID_MockMethod = { _, _ in }

        let mlsGroupID: MLSGroupID = .random()
        await syncContext.perform { [self] in
            _ = modelHelper.createMLSConversation(mlsGroupID: mlsGroupID, in: syncContext)
        }

        let mlsGroupVerification = makeMLSGroupVerification()

        // when
        await mlsGroupVerification.updateConversation(by: mlsGroupID)

        // then
        let mlsGroupIDs = mockUpdateUseCase.invokeForGroupID_Invocations.map(\.groupID)
        XCTAssertEqual(mlsGroupIDs, [mlsGroupID])
    }

    func testUpdateConversation_givenMLSGroupID() async {
        // given
        mockUpdateUseCase.invokeForGroupID_MockMethod = { _, _ in }

        let mlsGroupID: MLSGroupID = .random()
        let conversation = await syncContext.perform { [self] in
            modelHelper.createMLSConversation(mlsGroupID: mlsGroupID, in: syncContext)
        }

        let mlsGroupVerification = makeMLSGroupVerification()

        // when
        await mlsGroupVerification.updateConversation(conversation, with: mlsGroupID)

        // then
        let mlsGroupIDs = mockUpdateUseCase.invokeForGroupID_Invocations.map(\.groupID)
        XCTAssertEqual(mlsGroupIDs, [mlsGroupID])
    }

    func testUpdateAllConversations_givenMLSGroupID() async throws {
        // given
        mockUpdateUseCase.invokeForGroupID_MockMethod = { _, _ in }

        let mlsGroupID: MLSGroupID = .random()
        await syncContext.perform { [self] in
            _ = modelHelper.createMLSConversation(mlsGroupID: mlsGroupID, in: syncContext)
        }

        let mlsGroupVerification = makeMLSGroupVerification()

        // when
        await mlsGroupVerification.updateAllConversations()

        // then
        let mlsGroupIDs = mockUpdateUseCase.invokeForGroupID_Invocations.map(\.groupID)
        XCTAssertEqual(mlsGroupIDs, [mlsGroupID])
    }

    // MARK: Helpers

    private func makeMLSGroupVerification() -> MLSGroupVerification {
        MLSGroupVerification(
            updateUseCase: mockUpdateUseCase,
            mlsService: mockMLService,
            syncContext: mockCoreDataStack.syncContext
        )
    }

}
