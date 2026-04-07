//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import Testing
import WireDataModel
import WireDataModelSupport
import WireDomainSupport
@testable import WireDomain

final class WipeMLSGroupItemTests {

    let conversationLocalStore: MockConversationLocalStoreProtocol
    let mlsService: MockMLSServiceInterface
    let groupID: MLSGroupID
    let coreDataStackHelper = CoreDataStackHelper()
    let coreDataStack: CoreDataStack
    let modelHelper = ModelHelper()
    let sut: WipeMLSGroupItem

    init() async throws {
        self.conversationLocalStore = MockConversationLocalStoreProtocol()
        self.mlsService = MockMLSServiceInterface()
        self.groupID = .random()
        self.coreDataStack = try await coreDataStackHelper.createStack()
        self.sut = WipeMLSGroupItem(
            groupID: groupID,
            mlsService: mlsService,
            conversationLocalStore: conversationLocalStore
        )

        mlsService.wipeGroup_MockMethod = { _ in }
        conversationLocalStore.clearMLSGroupIDMlsGroupID_MockMethod = { _ in }
        // Given
        _ = await coreDataStack.syncContext.perform { [modelHelper, groupID, context] in
            modelHelper.createMLSConversation(
                mlsGroupID: groupID,
                mlsStatus: .invalid,
                in: context
            )
        }
    }

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    @Test("It wipes the MLS group")
    func startWipesMLSGroup() async throws {
        // When
        try await sut.start()

        // Then
        #expect(mlsService.wipeGroup_Invocations == [groupID])
    }

    @Test("It clears the MLS group ID after wiping")
    func startClearsMLSGroupID() async throws {
        // When
        try await sut.start()

        // Then
        #expect(conversationLocalStore.clearMLSGroupIDMlsGroupID_Invocations == [groupID])
    }

    @Test("It clears the MLS group ID even when wiping fails")
    func startClearsGroupIDWhenWipeFails() async throws {
        // Given
        struct WipeError: Error {}
        mlsService.wipeGroup_MockError = WipeError()

        // When
        try await sut.start()

        // Then
        #expect(conversationLocalStore.clearMLSGroupIDMlsGroupID_Invocations == [groupID])
    }
}
