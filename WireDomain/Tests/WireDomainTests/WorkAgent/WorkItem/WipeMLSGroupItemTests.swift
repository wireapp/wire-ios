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

    init() async throws {
        self.conversationLocalStore = MockConversationLocalStoreProtocol()
        self.mlsService = MockMLSServiceInterface()
        self.groupID = .random()
        self.coreDataStack = try await coreDataStackHelper.createStack()
        mlsService.wipeGroup_MockMethod = { _ in }
        conversationLocalStore.clearMLSGroupIDObjectID_MockMethod = { _ in }
    }

    private func makeItem(objectID: NSManagedObjectID) -> WipeMLSGroupItem {
        WipeMLSGroupItem(
            groupID: groupID,
            conversationObjectID: objectID,
            mlsService: mlsService,
            conversationLocalStore: conversationLocalStore
        )
    }

    @Test("It wipes the MLS group")
    func startWipesMLSGroup() async throws {
        // Given
        let objectID = await coreDataStack.syncContext.perform { [self] in
            modelHelper.createMLSConversation(
                mlsGroupID: groupID,
                mlsStatus: .invalid,
                in: coreDataStack.syncContext
            ).objectID
        }
        let sut = makeItem(objectID: objectID)

        // When
        try await sut.start()

        // Then
        #expect(mlsService.wipeGroup_Invocations == [groupID])
    }

    @Test("It clears the MLS group ID after wiping")
    func startClearsMLSGroupID() async throws {
        // Given
        let objectID = await coreDataStack.syncContext.perform { [self] in
            modelHelper.createMLSConversation(
                mlsGroupID: groupID,
                mlsStatus: .invalid,
                in: coreDataStack.syncContext
            ).objectID
        }
        let sut = makeItem(objectID: objectID)

        // When
        try await sut.start()

        // Then
        #expect(conversationLocalStore.clearMLSGroupIDObjectID_Invocations == [objectID])
    }

    @Test("It clears the MLS group ID even when wiping fails")
    func startClearsGroupIDWhenWipeFails() async throws {
        // Given
        struct WipeError: Error {}
        mlsService.wipeGroup_MockError = WipeError()

        let objectID = await coreDataStack.syncContext.perform { [self] in
            modelHelper.createMLSConversation(
                mlsGroupID: groupID,
                mlsStatus: .invalid,
                in: coreDataStack.syncContext
            ).objectID
        }
        let sut = makeItem(objectID: objectID)

        // When
        try await sut.start()

        // Then
        #expect(conversationLocalStore.clearMLSGroupIDObjectID_Invocations == [objectID])
    }
}
