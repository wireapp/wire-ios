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

@testable import WireAPI
import WireAPISupport
@testable import WireDataModel
import WireDataModelSupport
@testable import WireDomain
import XCTest

final class ConversationLabelsRepositoryTests: XCTestCase {

    var sut: ConversationLabelsRepository!
    var userPropertiesAPI: MockUserPropertiesAPI!

    var stack: CoreDataStack!
    var coreDataStackHelper: CoreDataStackHelper!
    let modelHelper = ModelHelper()

    private var conversation1: ZMConversation!
    private var conversation2: ZMConversation!
    private var conversation3: ZMConversation!

    var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        coreDataStackHelper = CoreDataStackHelper()
        /// Batch requests don't work with in-memory store
        /// so we need to use a persistent store.
        stack = try await coreDataStackHelper.createStack(inMemoryStore: false)
        cleanUpEntity()
        setupConversations()
        userPropertiesAPI = MockUserPropertiesAPI()
        sut = ConversationLabelsRepository(
            userPropertiesAPI: userPropertiesAPI,
            context: context
        )
    }

    override func tearDown() async throws {
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        userPropertiesAPI = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Tests

    func testPullConversation_Given_Local_Store_Empty_Labels_Are_Created() async throws {
        // Mock

        userPropertiesAPI.getLabels_MockValue = [
            Scaffolding.conversationLabel1,
            Scaffolding.conversationLabel2
        ]

        // When

        try await sut.pullConversationLabels()

        // Then

        try await context.perform { [context] in
            let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
            let a = try context.fetch(fetchRequest)
            let remoteIdentifiers = a.map(\.remoteIdentifier)
            XCTAssert(remoteIdentifiers.contains(Scaffolding.conversationLabel1.id))
            XCTAssert(remoteIdentifiers.contains(Scaffolding.conversationLabel2.id))
        }
    }

    func testPullConversationLabels_Given_Label_Exist_Locally_Label_Name_Is_Updated() async throws {
        // Given

        _ = await context.perform { [context] in
            var created = false
            let label = Label.fetchOrCreate(remoteIdentifier: Scaffolding.conversationLabel1.id, create: true, in: context, created: &created)
            label?.name = Scaffolding.conversationLabel1.name
            context.saveOrRollback()
        }

        try await context.perform { [self] in
            let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
            let a = try context.fetch(fetchRequest)
            try XCTAssertCount(a, count: 1)
            XCTAssertEqual(a.first!.name, Scaffolding.conversationLabel1.name)
        }

        userPropertiesAPI.getLabels_MockValue = [
            Scaffolding.updatedConversationLabel1
        ]

        // When

        try await sut.pullConversationLabels()

        // Then

        try await context.perform { [self] in
            let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
            let a = try context.fetch(fetchRequest)
            try XCTAssertCount(a, count: 1)
            XCTAssertEqual(a.first!.remoteIdentifier, Scaffolding.conversationLabel1.id)
            XCTAssertEqual(a.first!.name, Scaffolding.updatedConversationLabel1.name)
        }
    }

    func testPullConversationLabels_Given_Label_Exist_Locally_Label_Conversations_Are_Updated() async throws {
        // Given

        _ = await context.perform { [self] in
            var created = false
            let label = Label.fetchOrCreate(remoteIdentifier: Scaffolding.conversationLabel1.id, create: true, in: context, created: &created)
            label?.conversations = Set([conversation1, conversation2])
            context.saveOrRollback()
        }

        try await context.perform { [self] in
            let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
            let a = try context.fetch(fetchRequest)
            try XCTAssertCount(a, count: 1)
            let labelConversations = a.first!.conversations
            XCTAssertEqual(labelConversations.count, 2)
        }

        userPropertiesAPI.getLabels_MockValue = [
            Scaffolding.updatedConversationLabel1
        ]

        // When

        try await sut.pullConversationLabels()

        // Then

        try await context.perform { [self] in
            let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
            let a = try context.fetch(fetchRequest)
            try XCTAssertCount(a, count: 1)
            let labelConversations = a.first!.conversations.compactMap(\.remoteIdentifier)
            let expected = Scaffolding.updatedConversationLabel1.conversationIDs
            for labelConversation in labelConversations {
                XCTAssert(expected.contains(labelConversation))
            }
        }
    }

    func testPullConversationLabels_Given_Old_Folder_Label_Exist_Locally_Old_Folder_Is_Removed() async throws {
        // Given

        _ = await context.perform { [context] in
            var created = false
            _ = Label.fetchOrCreate(remoteIdentifier: Scaffolding.conversationLabel1.id, create: true, in: context, created: &created)
            context.saveOrRollback()
        }

        try await context.perform { [self] in
            let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
            let a = try context.fetch(fetchRequest)
            try XCTAssertCount(a, count: 1)
            XCTAssertEqual(a.first!.remoteIdentifier, Scaffolding.conversationLabel1.id)
        }

        // Mock

        userPropertiesAPI.getLabels_MockValue = [
            Scaffolding.conversationLabel2,
            Scaffolding.conversationLabel3
        ]

        // When

        try await sut.pullConversationLabels()

        // Then

        try await context.perform { [context] in
            let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
            let a = try context.fetch(fetchRequest)
            let labelNames = a.compactMap(\.name)
            XCTAssert(!labelNames.contains(Scaffolding.conversationLabel1.name!)) /// should be removed locally
            XCTAssert(labelNames.contains(Scaffolding.conversationLabel2.name!))
            XCTAssert(labelNames.contains(Scaffolding.conversationLabel3.name!))
        }
    }

    func testPullConversationLabels_Given_Favorite_Label_Exists_Locally_Favorite_Label_Should_Not_Be_Removed() async throws {
        // Given

        _ = await context.perform { [context] in
            var created = false
            let label = Label.fetchOrCreateFavoriteLabel(in: context, create: true)
            label.kind = .favorite
            label.remoteIdentifier = Scaffolding.favoriteConversationLabel1.id
            label.name = Scaffolding.favoriteConversationLabel1.name
            context.saveOrRollback()
        }

        try await context.perform { [self] in
            let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
            let a = try context.fetch(fetchRequest)
            try XCTAssertCount(a, count: 1)
            XCTAssertEqual(a.first!.remoteIdentifier, Scaffolding.favoriteConversationLabel1.id)
        }

        // Mock

        userPropertiesAPI.getLabels_MockValue = [
            Scaffolding.conversationLabel2,
            Scaffolding.conversationLabel3
        ]

        // When

        try await sut.pullConversationLabels()

        // Then

        try await context.perform { [context] in
            let fetchRequest = NSFetchRequest<Label>(entityName: Label.entityName())
            let a = try context.fetch(fetchRequest)
            let labelNames = a.compactMap(\.name)
            let expected = [
                Scaffolding.favoriteConversationLabel1.name!, /// Since this is a favorite label, it was not removed locally
                Scaffolding.conversationLabel2.name!,
                Scaffolding.conversationLabel3.name!
            ]

            expected.forEach { XCTAssert(labelNames.contains($0)) }
        }
    }

}

private extension ConversationLabelsRepositoryTests {
    func cleanUpEntity() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Label.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        _ = try? context.execute(batchDeleteRequest)
    }

    func setupConversations() {
        conversation1 = ZMConversation.insertNewObject(in: context)
        conversation1.remoteIdentifier = Scaffolding.conversationLabel1.conversationIDs[0]

        conversation2 = ZMConversation.insertNewObject(in: context)
        conversation2.remoteIdentifier = Scaffolding.conversationLabel1.conversationIDs[1]

        conversation3 = ZMConversation.insertNewObject(in: context)
        conversation3.remoteIdentifier = Scaffolding.updatedConversationLabel1.conversationIDs[2]
    }
}

private enum Scaffolding {
    static let conversationLabel1 = ConversationLabel(
        id: UUID(uuidString: "f3d302fb-3fd5-43b2-927b-6336f9e787b0")!,
        name: "ConversationLabel1",
        type: 0,
        conversationIDs: [
            UUID(uuidString: "ffd0a9af-c0d0-4748-be9b-ab309c640dde")!,
            UUID(uuidString: "03fe0d05-f0d5-4ee4-a8ff-8d4b4dcf89d8")!
        ]
    )

    static let updatedConversationLabel1 = ConversationLabel(
        id: UUID(uuidString: "f3d302fb-3fd5-43b2-927b-6336f9e787b0")!,
        name: "UpdatedConversationLabel1", /// Updated name
        type: 0,
        conversationIDs: [
            UUID(uuidString: "ffd0a9af-c0d0-4748-be9b-ab309c640dde")!,
            UUID(uuidString: "03fe0d05-f0d5-4ee4-a8ff-8d4b4dcf89d8")!,
            UUID(uuidString: "03fe0d05-f0d5-4ee4-a8ff-8d4b4dcf89d2")! /// new conversation added
        ]
    )

    static let favoriteConversationLabel1 = ConversationLabel(
        id: UUID(uuidString: "f3d302fb-3fd5-43b2-927b-6336f9e787b9")!,
        name: "FavoriteConversationLabel1",
        type: 1, /// this label is favorite
        conversationIDs: [
            UUID(uuidString: "ffd0a9af-c0d0-4748-be9b-ab309c640dde")!,
            UUID(uuidString: "03fe0d05-f0d5-4ee4-a8ff-8d4b4dcf89d8")!
        ]
    )

    static let conversationLabel2 = ConversationLabel(
        id: UUID(uuidString: "2AA27182-AA54-4D79-973E-8974A3BBE375")!,
        name: "ConversationLabel2",
        type: 0,
        conversationIDs: [
            UUID(uuidString: "ceb3f577-3b22-4fe9-8ffd-757f29c47ffc")!,
            UUID(uuidString: "eca55fdb-8f81-4112-9175-4ffca7691bf8")!
        ]
    )

    static let conversationLabel3 = ConversationLabel(
        id: UUID(uuidString: "2AA27182-AA54-4D79-973E-8974A3BBE390")!,
        name: "ConversationLabel3",
        type: 0,
        conversationIDs: [
            UUID(uuidString: "ceb3f577-3b22-4fe9-8ffd-757f29c47ff3")!,
            UUID(uuidString: "eca55fdb-8f81-4112-9175-4ffca7691bf9")!
        ]
    )

    static let conversationLabel4 = ConversationLabel(
        id: UUID(uuidString: "2AA27182-AA54-4D79-973E-8974A3BBE372")!,
        name: "ConversationLabel4",
        type: 0,
        conversationIDs: [
            UUID(uuidString: "ceb3f577-3b22-4fe9-8ffd-757f29c47ff0")!,
            UUID(uuidString: "eca55fdb-8f81-4112-9175-4ffca7691bf2")!
        ]
    )

}
