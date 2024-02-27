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

    private var epochChanges: AsyncStream<MLSGroupID>.Continuation!
    private var conversation: ZMConversation!
    private var mockMLSService: MockMLSServiceInterface!
    private var mockUpdateMLSGroupVerificationStatusUseCase: MockUpdateMLSGroupVerificationStatusUseCaseProtocol!
    private var sut: ObserveMLSGroupVerificationStatusUseCase!

    private var context: NSManagedObjectContext { syncMOC }

    override func setUp() {
        mockMLSService = .init()
        mockMLSService.epochChanges_MockValue = .init {
            epochChanges = $0
        }
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
        epochChanges = nil
    }

    func testExample() async throws {
        // Given
        setupConversation()
        sut.invoke()

        // When
        epochChanges.yield(conversation.mlsGroupID!)

        if #available(iOS 16.0, *) {
            try await Task.sleep(for: .seconds(1000))
        }
    }

    private func setupConversation() {
        context.performAndWait {
            let helper = ModelHelper()
            helper.createSelfUser(in: context)
            let otherUser = helper.createUser(in: context)
            helper.createOneOnOne(with: otherUser, in: context)
        }
    }
}
