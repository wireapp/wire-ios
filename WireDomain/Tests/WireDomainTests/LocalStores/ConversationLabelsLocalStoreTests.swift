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

import WireDataModelSupport
import WireTestingPackage
import XCTest
@testable import WireDataModel
@testable import WireDomain

final class ConversationLabelsLocalStoreTests: XCTestCase {

    private var sut: ConversationLabelsLocalStore!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var conversation1: ZMConversation!
    private var conversation2: ZMConversation!
    private var conversation3: ZMConversation!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        /// Batch requests don't work with in-memory store
        /// so we need to use a persistent store.
        stack = try await coreDataStackHelper.createStack(inMemoryStore: false)
        await cleanUpEntity()
        await setupConversations()

        sut = ConversationLabelsLocalStore(
            context: context
        )
    }

    override func tearDown() async throws {
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        sut = nil
        modelHelper = nil
    }

    // MARK: - Tests

    func testSetLabels_Given_Local_Store_Empty_It_Creates_Label_Locally() async throws {
        // Mock

        let conversationLabel = Scaffolding.conversationLabel1

        // When

        try await sut.setLabels([conversationLabel])

        // Then

        try await context.perform { [context] in
            let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
            let results = try context.fetch(fetchRequest)
            let remoteIdentifiers = results.map(\.remoteIdentifier)
            XCTAssert(remoteIdentifiers.contains(Scaffolding.conversationLabel1.id))
        }
    }

    func testSetLabels_Given_Label_Exist_Locally_It_Updates_Label_Name() async throws {
        // Mock

        let label = await context.perform { [context] in
            var created = false
            let label = Label.fetchOrCreate(
                remoteIdentifier: Scaffolding.conversationLabel1.id,
                create: true,
                in: context,
                created: &created
            )

            label?.name = Scaffolding.conversationLabel1.name // existing name
            context.saveOrRollback()

            return label
        }

        // When

        try await sut.setLabels([Scaffolding.updatedConversationLabel1])

        // Then

        await context.perform {
            XCTAssertEqual(label?.name, Scaffolding.updatedConversationLabel1.name) // updated name
        }
    }

    func testSetLabels_Given_Label_Exist_Locally_It_Updates_Label_Conversations() async throws {
        // Mock

        _ = await context.perform { [self] in
            var created = false
            let label = Label.fetchOrCreate(
                remoteIdentifier: Scaffolding.conversationLabel1.id,
                create: true,
                in: context,
                created: &created
            )

            label?.conversations = Set([conversation1, conversation2])
            context.saveOrRollback()
        }

        try await context.perform { [self] in
            let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
            let results = try context.fetch(fetchRequest)
            let label = try XCTUnwrap(results.first)
            let labelConversations = label.conversations
            XCTAssertEqual(labelConversations.count, 2)
        }

        // When

        try await sut.setLabels([Scaffolding.conversationLabel1])

        // Then

        try await context.perform { [self] in
            let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
            let results = try context.fetch(fetchRequest)
            let label = try XCTUnwrap(results.first)
            let labelConversations = label.conversations.compactMap(\.remoteIdentifier)

            let expected = Scaffolding.updatedConversationLabel1.conversationIDs

            for labelConversation in labelConversations {
                XCTAssert(expected.contains(labelConversation))
            }
        }
    }

    func testSetLabels_Given_Old_Folder_Label_Exist_Locally_It_Removes_Old_Folder() async throws {
        // Mock

        _ = await context.perform { [context] in
            var created = false
            _ = Label.fetchOrCreate(
                remoteIdentifier: Scaffolding.conversationLabel1.id,
                create: true, in: context,
                created: &created
            )
            context.saveOrRollback()
        }

        try await context.perform { [self] in
            let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
            let results = try context.fetch(fetchRequest)
            XCTAssertEqual(results.first?.remoteIdentifier, Scaffolding.conversationLabel1.id)
        }

        // When

        try await sut.setLabels([Scaffolding.conversationLabel2, Scaffolding.conversationLabel3])

        // Then

        try await context.perform { [context] in
            let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
            let results = try context.fetch(fetchRequest)
            let storedIDs = results.map(\.remoteIdentifier)

            // Old folder was removed locally
            XCTAssertEqual(storedIDs, [
                Scaffolding.conversationLabel2.id,
                Scaffolding.conversationLabel3.id
            ])
        }
    }

    func testSetLabels_Given_Favorite_Label_Exists_Locally_It_Doesnt_Remove_Favorite_Label() async throws {
        // Mock

        let existingFavoriteLabel = await context.perform { [context] in
            let label = Label.fetchOrCreateFavoriteLabel(
                in: context,
                create: true
            )

            label.kind = .favorite
            label.remoteIdentifier = Scaffolding.favoriteConversationLabel1.id
            label.name = Scaffolding.favoriteConversationLabel1.name
            context.saveOrRollback()

            return label
        }

        try await context.perform { [self] in
            let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
            let results = try context.fetch(fetchRequest)
            let label = try XCTUnwrap(results.first)
            XCTAssertEqual(label.remoteIdentifier, Scaffolding.favoriteConversationLabel1.id)
        }

        // When

        try await sut.setLabels([Scaffolding.conversationLabel2, Scaffolding.conversationLabel3])

        // Then

        try await context.perform { [context] in
            let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
            let results = try context.fetch(fetchRequest)
            let favoriteLabel = try XCTUnwrap(results.first)

            XCTAssertEqual(existingFavoriteLabel, favoriteLabel) // favorite label was not removed
        }
    }

}

private extension ConversationLabelsLocalStoreTests {
    func cleanUpEntity() async {
        await context.perform { [self] in
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Label.fetchRequest()
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            _ = try? context.execute(batchDeleteRequest)
        }
    }

    func setupConversations() async {
        await context.perform { [self] in
            conversation1 = ZMConversation.insertNewObject(in: context)
            conversation1.remoteIdentifier = Scaffolding.conversationLabel1.conversationIDs[0]

            conversation2 = ZMConversation.insertNewObject(in: context)
            conversation2.remoteIdentifier = Scaffolding.conversationLabel1.conversationIDs[1]

            conversation3 = ZMConversation.insertNewObject(in: context)
            conversation3.remoteIdentifier = Scaffolding.updatedConversationLabel1.conversationIDs[2]
        }
    }

    private enum Scaffolding {
        static let conversationLabel1 = ConversationLabelInfo(
            id: .mockID1,
            name: "ConversationLabel1",
            type: 0,
            conversationIDs: [
                .mockID2,
                .mockID3
            ]
        )

        static let updatedConversationLabel1 = ConversationLabelInfo(
            id: .mockID1,
            name: "UpdatedConversationLabel1", /// Updated name
            type: 0,
            conversationIDs: [
                .mockID2,
                .mockID3,
                .mockID4 /// new conversation added
            ]
        )

        static let favoriteConversationLabel1 = ConversationLabelInfo(
            id: .mockID3,
            name: "FavoriteConversationLabel1",
            type: 1, /// this label is favorite
            conversationIDs: [
                .mockID1,
                .mockID2
            ]
        )

        static let conversationLabel2 = ConversationLabelInfo(
            id: .mockID4,
            name: "ConversationLabel2",
            type: 0,
            conversationIDs: [
                .mockID1,
                .mockID2
            ]
        )

        static let conversationLabel3 = ConversationLabelInfo(
            id: .mockID5,
            name: "ConversationLabel3",
            type: 0,
            conversationIDs: [
                .mockID1,
                .mockID2
            ]
        )

    }

}
