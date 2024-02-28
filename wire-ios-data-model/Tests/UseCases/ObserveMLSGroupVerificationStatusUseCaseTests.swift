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

import XCTest

@testable import WireDataModel
@testable import WireDataModelSupport

final class ObserveMLSGroupVerificationStatusUseCaseTests: ZMBaseManagedObjectTest {

    private var conversation: ZMConversation!
    private var mockMLSService: MockMLSServiceInterface!
    private var mockUpdateMLSGroupVerificationStatusUseCase: MockUpdateMLSGroupVerificationStatusUseCaseProtocol!
    private var sut: ObserveMLSGroupVerificationStatusUseCase!

    private var context: NSManagedObjectContext { syncMOC }

    override func setUp() {
        super.setUp()

        setupConversation()
        mockMLSService = .init()
        mockUpdateMLSGroupVerificationStatusUseCase = .init()
        mockUpdateMLSGroupVerificationStatusUseCase.invokeForGroupID_MockMethod = { _, _ in }
        sut = .init(
            mlsService: mockMLSService,
            updateMLSGroupVerificationStatusUseCase: mockUpdateMLSGroupVerificationStatusUseCase,
            syncContext: syncMOC
        )
    }

    override func tearDown() {
        sut = nil
        mockUpdateMLSGroupVerificationStatusUseCase = nil
        mockMLSService = nil
        conversation = nil

        super.tearDown()
    }

    func testUpdateGroupVerificationStatusUseCaseIsCalled() throws {
        // Given
        let mlsGroupID = try context.performAndWait { try XCTUnwrap(self.conversation.mlsGroupID) }
        mockMLSService.epochChanges_MockValue = .init { continuation in
            continuation.yield(mlsGroupID)
            continuation.finish()
        }

        // When
        sut.invoke()

        // Then
        let useCase = try XCTUnwrap(mockUpdateMLSGroupVerificationStatusUseCase)
        let predicate = NSPredicate { _, _ in useCase.invokeForGroupID_Invocations.count == 1 }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        wait(for: [expectation], timeout: 5)

        let invocation = try XCTUnwrap(useCase.invokeForGroupID_Invocations.first)
        XCTAssert(invocation.conversation === conversation)
        XCTAssertEqual(invocation.groupID, mlsGroupID)
    }

    private func setupConversation() {
        context.performAndWait {
            let helper = ModelHelper()
            helper.createSelfUser(in: context)
            let otherUser = helper.createUser(in: context)
            conversation = helper.createOneOnOne(with: otherUser, in: context)
            conversation.mlsGroupID = .random()
         }
    }
}
