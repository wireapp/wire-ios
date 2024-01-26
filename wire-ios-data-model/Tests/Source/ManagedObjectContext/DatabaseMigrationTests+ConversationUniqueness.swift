//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import Foundation
@testable import WireDataModel

final class DatabaseMigrationTests_ConversationUniqueness: XCTestCase {

    private let bundle = Bundle(for: ZMManagedObject.self)
    private let conversationId = UUID()
    private let domain = "example.com"
    private let tmpStoreURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())DatabaseMigrationTests_ConversationUniqueness/")
    private let helper = DatabaseMigrationHelper()

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
        let uniqueConversation2: (UUID?, String?) = (nil, "test.example.com")
        let otherDuplicateConversations = (UUID(), "otherdomain")

        try helper.migrateStoreToCurrentVersion(
            sourceVersion: initialVersion,
            preMigrationAction: { context in
                insertDuplicateConversations(with: conversationId, domain: domain, in: context)
                insertDuplicateConversations(with: otherDuplicateConversations.0, domain: otherDuplicateConversations.1, in: context)
                _ = context.performGroupedAndWait({ context in
                    let user = ZMConversation(context: context)
                    user.remoteIdentifier = uniqueConversation1.0
                    user.domain = uniqueConversation1.1
                    return user
                })

                _ = context.performGroupedAndWait({ context in
                    let user = ZMConversation(context: context)
                    user.remoteIdentifier = uniqueConversation2.0
                    user.domain = uniqueConversation2.1
                    return user
                })

                try context.save()

                let conversations = try fetchConversations(with: conversationId, domain: domain, in: context)
                XCTAssertEqual(conversations.count, 2)
            },
            postMigrationAction: { context in
                // we need to use syncContext here because of `setInternalEstimatedUnreadCount` being tiggered on save
                try context.performGroupedAndWait { context in
                    // verify it deleted duplicates
                    var conversations = try self.fetchConversations(with: self.conversationId, domain: self.domain, in: context)
                    XCTAssertEqual(conversations.count, 1)

                    conversations = try self.fetchConversations(with: uniqueConversation1.0, domain: uniqueConversation1.1, in: context)
                    XCTAssertEqual(conversations.count, 1)

                    conversations = try self.fetchConversations(with: uniqueConversation2.0, domain: uniqueConversation2.1, in: context)
                    XCTAssertEqual(conversations.count, 1)

                    conversations = try self.fetchConversations(with: otherDuplicateConversations.0, domain: otherDuplicateConversations.1, in: context)
                    XCTAssertEqual(conversations.count, 1)

                    // verify we can't insert duplicates
                    context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    self.insertDuplicateConversations(with: self.conversationId, domain: self.domain, in: context)
                    try context.save()

                    conversations = try self.fetchConversations(with: self.conversationId, domain: self.domain, in: context)
                    XCTAssertEqual(conversations.count, 1)
                }
            },
            for: self
        )
    }

    func testThatItPerformsMigrationFrom110Version_ToCurrentModelVersion() throws {
        // With version 107 and later we can not insert duplicated keys anymore!

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
                try context.performGroupedAndWait { [self] context in
                    // verify it deleted duplicates
                    var conversations = try fetchConversations(with: conversationId, domain: domain, in: context)

                    XCTAssertEqual(conversations.count, 1)

                    // verify we can't insert duplicates
                    context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    insertDuplicateConversations(with: conversationId, domain: domain, in: context)
                    try context.save()

                    conversations = try fetchConversations(with: conversationId, domain: domain, in: context)
                    XCTAssertEqual(conversations.count, 1)
                }
            },
            for: self
        )
    }

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
                NSPredicate(format: "%K == %@", ZMConversation.remoteIdentifierDataKey()!, identifier.uuidData as CVarArg)
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

