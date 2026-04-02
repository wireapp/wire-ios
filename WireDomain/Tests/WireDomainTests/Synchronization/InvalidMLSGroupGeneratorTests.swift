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

import Testing
import WireDataModel
import WireDataModelSupport
import WireDomainSupport
@testable import WireDomain

@Suite("InvalidMLSGroupGenerator Tests", .timeLimit(.minutes(1)))
final class InvalidMLSGroupGeneratorTests {

    var sut: InvalidMLSGroupGenerator!
    let conversationLocalStore: MockConversationLocalStoreProtocol
    let mlsService: MockMLSServiceInterface
    let modelHelper = ModelHelper()
    let coreDataStackHelper = CoreDataStackHelper()
    let coreDataStack: CoreDataStack
    var receivedItems: [WipeMLSGroupItem] = []

    init() async throws {
        self.conversationLocalStore = MockConversationLocalStoreProtocol()
        self.mlsService = MockMLSServiceInterface()
        self.coreDataStack = try await coreDataStackHelper.createStack()

        self.sut = InvalidMLSGroupGenerator(
            context: coreDataStack.syncContext,
            mlsService: mlsService,
            conversationLocalStore: conversationLocalStore,
            onInvalidMLSGroup: { [weak self] item in
                self?.receivedItems.append(item)
            }
        )
    }

    @Test("It generates an item for an existing invalid MLS conversation on start")
    func startGeneratesItemForExistingConversation() async throws {
        // Given
        let groupID = MLSGroupID.random()
        await coreDataStack.syncContext.perform { [self] in
            _ = modelHelper.createMLSConversation(
                mlsGroupID: groupID,
                mlsStatus: .invalid,
                in: coreDataStack.syncContext
            )
        }

        // When
        await sut.start()

        // Then
        #expect(receivedItems.count == 1)
        #expect(receivedItems.first?.groupID == groupID)
    }

    @Test("It does not generate an item for a ready MLS conversation")
    func startDoesNotGenerateItemForReadyConversation() async throws {
        // Given
        await coreDataStack.syncContext.perform { [self] in
            _ = modelHelper.createMLSConversation(
                mlsGroupID: .random(),
                mlsStatus: .ready,
                in: coreDataStack.syncContext
            )
        }

        // When
        await sut.start()

        // Then
        #expect(receivedItems.isEmpty)
    }

    @Test("It does not generate an item for an invalid conversation without a group ID")
    func startDoesNotGenerateItemWithoutGroupID() async throws {
        // Given
        await coreDataStack.syncContext.perform { [self] in
            _ = modelHelper.createMLSConversation(
                mlsGroupID: nil,
                mlsStatus: .invalid,
                in: coreDataStack.syncContext
            )
        }

        // When
        await sut.start()

        // Then
        #expect(receivedItems.isEmpty)
    }

    @Test("It generates an item when a conversation transitions to invalid")
    func generatesItemOnTransitionToInvalid() async throws {
        // Given
        await sut.start()

        let groupID = MLSGroupID.random()
        try await confirmation("generator delivers item for newly invalid conversation") { confirm in
            sut = InvalidMLSGroupGenerator(
                context: coreDataStack.syncContext,
                mlsService: mlsService,
                conversationLocalStore: conversationLocalStore,
                onInvalidMLSGroup: { [weak self] item in
                    self?.receivedItems.append(item)
                    confirm()
                }
            )
            await sut.start()

            await coreDataStack.syncContext.perform { [self] in
                _ = modelHelper.createMLSConversation(
                    mlsGroupID: groupID,
                    mlsStatus: .invalid,
                    in: coreDataStack.syncContext
                )
            }
            try await Task.sleep(for: .seconds(0.1))
        }

        // Then
        #expect(receivedItems.count == 1)
        #expect(receivedItems.first?.groupID == groupID)
    }

    @Test("It does not generate items after stop")
    func stopPreventsItemGeneration() async throws {
        // Given
        await sut.start()
        await sut.stop()

        // When
        await coreDataStack.syncContext.perform { [self] in
            _ = modelHelper.createMLSConversation(
                mlsGroupID: .random(),
                mlsStatus: .invalid,
                in: coreDataStack.syncContext
            )
        }
        try await Task.sleep(for: .seconds(0.1))

        // Then
        #expect(receivedItems.isEmpty)
    }
}
