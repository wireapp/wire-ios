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
import WireDataModelSupport
import XCTest
@testable import WireDataModel

class RemoveLocalConversationUseCaseTests: ZMBaseManagedObjectTest {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        sut = RemoveLocalConversationUseCase()
        mockMLSService = .init()
        syncMOC.performAndWait {
            syncMOC.mlsService = mockMLSService
        }
    }

    override func tearDown() {
        sut = nil
        mockMLSService = nil
        super.tearDown()
    }

    func test_itMarksConversationAsDeleted_AndWipesMLSGroup() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let conversation = await syncMOC.perform { [syncMOC] in
            let conversation = ZMConversation.insertNewObject(in: syncMOC)
            conversation.messageProtocol = .mls
            conversation.mlsGroupID = groupID
            return conversation
        }
        mockMLSService.wipeGroup_MockMethod = { _ in }

        // When
        try await sut.invoke(with: conversation, syncContext: syncMOC)

        // Then
        await syncMOC.perform {
            XCTAssertTrue(conversation.isDeletedRemotely)
        }
        XCTAssertEqual(mockMLSService.wipeGroup_Invocations, [groupID])
    }

    // MARK: Private

    private var sut: RemoveLocalConversationUseCase!
    private var mockMLSService: MockMLSServiceInterface!
}
