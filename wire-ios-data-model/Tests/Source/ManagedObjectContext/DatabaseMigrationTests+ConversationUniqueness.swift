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
import XCTest
@testable import WireDataModel

@available(iOS 15.0, *)
final class DatabaseMigrationTests_ConversationUniqueness: XCTestCase {
    // MARK: Internal

    override func setUpWithError() throws {
        try super.setUpWithError()
        try FileManager.default.createDirectory(at: tmpStoreURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpStoreURL)
        try super.tearDownWithError()
    }

    func testThatItDoesNotRemoveConversationsWithDifferentIds() throws {
        let initialVersion = "2.110.0"

        let uniqueConversation1: (UUID?, String?) = (UUID(), nil)
        let uniqueConversation2: (UUID?, String?) = (UUID(), "test.example.com")
        let otherDuplicateConversations = (UUID(), "otherdomain")

        try helper.migrateStoreToCurrentVersion(
            sourceVersion: initialVersion,
            preMigrationAction: { context in
                insertDuplicateConversations(with: conversationId, domain: domain, in: context)
                insertDuplicateConversations(
                    with: otherDuplicateConversations.0,
                    domain: otherDuplicateConversations.1,
                    in: context
                )
                _ = context.performGroupedAndWait {
                    let conversation = ZMConversation(context: context)
                    conversation.remoteIdentifier = uniqueConversation1.0
                    conversation.domain = uniqueConversation1.1
                    return conversation
                }

                _ = context.performGroupedAndWait {
                    let conversation = ZMConversation(context: context)
                    conversation.remoteIdentifier = uniqueConversation2.0
                    conversation.domain = uniqueConversation2.1
                    return conversation
                }

                try context.save()

                let conversations = try fetchConversations(with: conversationId, domain: domain, in: context)
                XCTAssertEqual(conversations.count, 2)
            },
            postMigrationAction: { context in
                // we need to use syncContext here because of `setInternalEstimatedUnreadCount` being tiggered on save
                try context.performGroupedAndWait {
                    // verify it deleted duplicates
                    var conversations = try self.fetchConversations(
                        with: self.conversationId,
                        domain: self.domain,
                        in: context
                    )
                    XCTAssertEqual(conversations.count, 1)

                    conversations = try self.fetchConversations(
                        with: uniqueConversation1.0,
                        domain: uniqueConversation1.1,
                        in: context
                    )
                    XCTAssertEqual(conversations.count, 1)

                    conversations = try self.fetchConversations(
                        with: uniqueConversation2.0,
                        domain: uniqueConversation2.1,
                        in: context
                    )
                    XCTAssertEqual(conversations.count, 1)

                    conversations = try self.fetchConversations(
                        with: otherDuplicateConversations.0,
                        domain: otherDuplicateConversations.1,
                        in: context
                    )
                    XCTAssertEqual(conversations.count, 1)

                    // verify we can't insert duplicates
                    context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    self.insertDuplicateConversations(with: self.conversationId, domain: self.domain, in: context)
                    try context.save()

                    conversations = try self.fetchConversations(
                        with: self.conversationId,
                        domain: self.domain,
                        in: context
                    )
                    XCTAssertEqual(conversations.count, 1)
                }
            },
            for: self
        )
    }

    func testThatItPerformsMigrationFrom110Version_ToCurrentModelVersion() throws {
        let initialVersion = "2.110.0"

        try helper.migrateStoreToCurrentVersion(
            sourceVersion: initialVersion,
            preMigrationAction: { context in
                insertDuplicateConversations(with: conversationId, domain: domain, in: context)
                try context.save()

                let conversations = try fetchConversations(with: conversationId, domain: domain, in: context)
                XCTAssertEqual(conversations.count, 2)
            },
            postMigrationAction: { context in
                // we need to use syncContext here because of `setInternalEstimatedUnreadCount` being tiggered on save
                try context.performAndWait { [self] in
                    // verify it deleted duplicates
                    var conversations = try fetchConversations(with: conversationId, domain: domain, in: context)

                    XCTAssertEqual(conversations.count, 1)

                    // verify we can't insert duplicates
                    context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    insertDuplicateConversations(with: conversationId, domain: domain, in: context)
                    try context.save()

                    conversations = try fetchConversations(with: conversationId, domain: domain, in: context)
                    XCTAssertEqual(conversations.count, 1)

                    XCTAssertTrue(context.readAndResetSlowSyncFlag())
                    // the flag has been consumed
                    XCTAssertFalse(context.readAndResetSlowSyncFlag())
                }
            },
            for: self
        )
    }

    // MARK: Private

    private let bundle = Bundle(for: ZMManagedObject.self)
    private let conversationId = UUID()
    private let domain = "example.com"
    private let tmpStoreURL =
        URL(fileURLWithPath: "\(NSTemporaryDirectory())DatabaseMigrationTests_ConversationUniqueness/")
    private let helper = DatabaseMigrationHelper()

    // MARK: - Fetch / Insert Helpers

    private func fetchConversations(
        with identifier: UUID?,
        domain: String?,
        in context: NSManagedObjectContext
    ) throws -> [ZMConversation] {
        let fetchRequest = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
        var predicates = [NSPredicate]()
        if let domain {
            predicates.append(
                NSPredicate(format: "%K == %@", #keyPath(ZMConversation.domain), domain)
            )
        }

        if let identifier {
            predicates.append(
                NSPredicate(
                    format: "%K == %@",
                    ZMConversation.remoteIdentifierDataKey(),
                    identifier.uuidData as CVarArg
                )
            )
        }

        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return try context.fetch(fetchRequest)
    }

    private func insertDuplicateConversations(
        with identifier: UUID,
        domain: String,
        in context: NSManagedObjectContext
    ) {
        let duplicate1 = ZMConversation.insertNewObject(in: context)
        duplicate1.remoteIdentifier = identifier
        duplicate1.domain = domain

        let duplicate2 = ZMConversation.insertNewObject(in: context)
        duplicate2.remoteIdentifier = identifier
        duplicate2.domain = domain
    }
}
