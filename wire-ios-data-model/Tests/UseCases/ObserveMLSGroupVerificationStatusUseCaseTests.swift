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

    func testExample() async throws {
        // Given
        let mlsGroupID = try await context.perform { try XCTUnwrap(self.conversation.mlsGroupID) }

        mockMLSService.epochChanges_MockValue = .init { continuation in

//            continuation.onTermination = { termination in
//                            switch termination {
//                            case .finished:
//                                // continuation.finish() was called
//                                print("Stream finished.")
//                            case .cancelled:
//                                // Task was cancelled
//                                print("Stream cancelled.")
//                            }
//                        }

            continuation.yield(conversation.mlsGroupID!)
            continuation.finish()
        }

        // When
        sut.invoke()

        if #available(iOS 16.0, *) {
            try await Task.sleep(for: .seconds(1000))
        }
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
