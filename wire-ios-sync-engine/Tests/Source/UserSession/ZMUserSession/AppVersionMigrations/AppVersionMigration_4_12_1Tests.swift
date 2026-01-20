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
import WireDataModelSupport
import WireDomainSupport
import WireNetwork
import WireNetworkSupport
@testable import WireSyncEngine

struct AppVersionMigration_4_12_1Tests {

    let coreDataHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()

    let mockConversationsAPI = MockConversationsAPI()
    let mockConversationLocalStore = MockConversationLocalStoreProtocol()

    let stack: CoreDataStack
    let sut: AppVersionMigration_4_12_1

    init() async throws {
        self.stack = try await coreDataHelper.createStack()
        self.sut = AppVersionMigration_4_12_1(
            coreDataStack: stack,
            api: mockConversationsAPI,
            store: mockConversationLocalStore
        )

    }

    @Test("Restores deleted conversations that are still in backend ")
    func testMigration() async throws {
        let conversationID = QualifiedID.random()
        let qualifiedId = WireNetwork.QualifiedID(id: conversationID.uuid, domain: conversationID.domain)

        mockConversationsAPI.getConversationsFor_MockValue = .init(
            found: [.init(qualifiedID: qualifiedId)],
            notFound: [],
            failed: []
        )

        let context = stack.syncContext

        var conversationA: ZMConversation?
        var conversationB: ZMConversation?
        try await context.perform {
            conversationA = modelHelper.createGroupConversation(
                id: qualifiedId.id,
                domain: qualifiedId.domain,
                in: context
            )
            conversationA?.isDeletedRemotely = true

            conversationB = modelHelper.createGroupConversation(in: context)
            try context.save()
        }

        // WHEN
        try await sut.perform()

        // THEN
        try await context.perform {
            let updatedConversation = try XCTUnwrap(conversationA)
            XCTAssertFalse(updatedConversation.isDeletedRemotely)
            XCTAssertTrue(conversationB?.isDeletedRemotely == false)
        }
    }

    @Test("Don't restore deleted conversations not found in backend")
    func testDoesNotRestore() async throws {
        let conversationID = QualifiedID.random()
        let qualifiedId = WireNetwork.QualifiedID(id: conversationID.uuid, domain: conversationID.domain)

        mockConversationsAPI.getConversationsFor_MockValue = .init(
            found: [],
            notFound: [qualifiedId],
            failed: []
        )

        let context = stack.syncContext

        var conversationA: ZMConversation?
        var conversationB: ZMConversation?
        try await context.perform {
            conversationA = modelHelper.createGroupConversation(
                id: qualifiedId.id,
                domain: qualifiedId.domain,
                in: context
            )
            conversationA?.isDeletedRemotely = true

            conversationB = modelHelper.createGroupConversation(in: context)
            try context.save()
        }

        // WHEN
        try await sut.perform()

        // THEN
        try await context.perform {
            let updatedConversation = try XCTUnwrap(conversationA)
            XCTAssertTrue(updatedConversation.isDeletedRemotely)
            XCTAssertFalse(conversationB?.isDeletedRemotely == false)
        }
    }

    @Test("Don't fail if no deleted conversations")
    func testNoDeletedConversations() async throws {
        let conversationID = QualifiedID.random()
        let qualifiedId = WireNetwork.QualifiedID(id: conversationID.uuid, domain: conversationID.domain)

        mockConversationsAPI.getConversationsFor_MockError = ConversationsAPIError
            .illegalArgument(message: "identifiers between 0 and 1000")

        let context = stack.syncContext

        try await context.perform {
            modelHelper.createGroupConversation(in: context)
            try context.save()
        }

        // WHEN / THEN
        try await sut.perform() // should not throw
    }

    @Test("Restores deleted conversations that were missing from backend")
    func testFailedMigration() async throws {
        let conversationID = QualifiedID.random()
        let qualifiedId = WireNetwork.QualifiedID(id: conversationID.uuid, domain: conversationID.domain)

        mockConversationsAPI.getConversationsFor_MockValue = .init(
            found: [],
            notFound: [],
            failed: [qualifiedId]
        )

        let context = stack.syncContext

        var conversationA: ZMConversation?
        var conversationB: ZMConversation?
        try await context.perform {
            conversationA = modelHelper.createGroupConversation(
                id: qualifiedId.id,
                domain: qualifiedId.domain,
                in: context
            )
            conversationA?.isDeletedRemotely = true

            conversationB = modelHelper.createGroupConversation(in: context)
            try context.save()
        }

        // WHEN
        try await sut.perform()

        // THEN
        try await context.perform {
            let updatedConversation = try XCTUnwrap(conversationA)
            XCTAssertFalse(updatedConversation.isDeletedRemotely)
            XCTAssertTrue(conversationB?.isDeletedRemotely == false)
        }
    }
}
