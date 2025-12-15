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

import Testing
import WireDataModel
import WireDataModelSupport
import WireDomainSupport
@testable import WireDomain

class ConversationUpdatesGeneratorTests {

    var sut: ConversationUpdatesGenerator!
    let repository: MockConversationRepositoryProtocol
    let modelHelper = ModelHelper()
    let coreDataStackHelper = CoreDataStackHelper()
    let coreDataStack: CoreDataStack
    var updateConversationItemClosure: ((UpdateConversationItem) -> Void)?

    init() async throws {
        self.repository = MockConversationRepositoryProtocol()

        self.coreDataStack = try await coreDataStackHelper.createStack()

        self.sut = ConversationUpdatesGenerator(
            repository: repository,
            context: coreDataStack.syncContext,
            onConversationUpdated: { item in
                self.updateConversationItemClosure?(item)
            }
        )
    }

    @Test("It generates an item when a conversation needsToBeUpdatedFromBackend is found")
    func startGeneratesItem() async throws {
        // GIVEN
        let conversationID = QualifiedID.random()
        await coreDataStack.syncContext.perform { [modelHelper, context = coreDataStack.syncContext] in
            let conversation = modelHelper.createGroupConversation(
                id: conversationID.uuid,
                domain: conversationID.domain,
                in: context
            )
            conversation.needsToBeUpdatedFromBackend = true
        }
        var updateConversationItems = [UpdateConversationItem]()
        updateConversationItemClosure = { item in
            updateConversationItems.append(item)
        }
        // WHEN
        await sut.start()

        // THEN
        #expect(updateConversationItems.count == 1)
        #expect(updateConversationItems.first?.conversationID == conversationID.toAPIModel())

        // WHEN
        let newConversationID = QualifiedID.random()
        try await confirmation("generator delivers an update for a new conversation") { confirm in
            self.updateConversationItemClosure = {  item in
                updateConversationItems.append(item)
                confirm()
            }

            await coreDataStack.syncContext.perform { [modelHelper, context = coreDataStack.syncContext] in
                let conversation = modelHelper.createGroupConversation(
                    id: newConversationID.uuid,
                    domain: newConversationID.domain,
                    in: context
                )
                conversation.needsToBeUpdatedFromBackend = true
            }
            try await Task.sleep(for: .seconds(0.1))
        }

        // THEN
        #expect(updateConversationItems.count == 2)
        #expect(updateConversationItems.last?.conversationID == newConversationID.toAPIModel())
    }

    @Test("It does not generate an item on conversation insertion")
    func startDoesNotGenerateItem() async throws {
        // GIVEN
        var updateConversationItems = [UpdateConversationItem]()
        updateConversationItemClosure = { item in
            updateConversationItems.append(item)
        }
        let conversationID = QualifiedID.random()
        _ = await coreDataStack.syncContext.perform { [modelHelper, context = coreDataStack.syncContext] in
            modelHelper.createGroupConversation(
                id: conversationID.uuid,
                domain: conversationID.domain,
                in: context
            )
        }

        // WHEN
        await sut.start()

        // THEN
        #expect(updateConversationItems.isEmpty)
    }

    @Test("It does not generate an item when stopped")
    func stopDoesGenerateItems() async throws {
        // GIVEN
        await sut.start()

        // WHEN
        sut.stop()

        // THEN
        var updateConversationItems = [UpdateConversationItem]()
        let newConversationID = QualifiedID.random()
        try await confirmation("generator delivers an update for a new conversation") { confirm in
            self.updateConversationItemClosure = {  item in
                updateConversationItems.append(item)
            }

            await coreDataStack.syncContext.perform { [modelHelper, context = coreDataStack.syncContext] in
                let conversation = modelHelper.createGroupConversation(
                    id: newConversationID.uuid,
                    domain: newConversationID.domain,
                    in: context
                )
                conversation.needsToBeUpdatedFromBackend = true
            }
            try await Task.sleep(for: .seconds(0.1))
            confirm()
        }

        #expect(updateConversationItems.isEmpty)
    }

    @Test("It does not generate an item when a conversation is deleted")
    func deletedConversation() async throws {
        // GIVEN
        let conversationID = QualifiedID.random()
        await coreDataStack.syncContext.perform { [modelHelper, context = coreDataStack.syncContext] in
            let conversation = modelHelper.createGroupConversation(
                id: conversationID.uuid,
                domain: conversationID.domain,
                in: context
            )
            conversation.needsToBeUpdatedFromBackend = true
            conversation.isDeletedRemotely = true
        }
        var updateConversationItems = [UpdateConversationItem]()
        updateConversationItemClosure = { item in
            updateConversationItems.append(item)
        }
        // WHEN
        await sut.start()

        // THEN
        #expect(updateConversationItems.isEmpty)
    }
}
