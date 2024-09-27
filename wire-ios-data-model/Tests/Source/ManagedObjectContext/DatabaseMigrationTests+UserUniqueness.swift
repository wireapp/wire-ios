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

final class DatabaseMigrationTests_UserUniqueness: XCTestCase {
    // MARK: Internal

    override func setUpWithError() throws {
        try super.setUpWithError()
        try FileManager.default.createDirectory(at: tmpStoreURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpStoreURL)
        try super.tearDownWithError()
    }

    func testThatItDoesNotRemoveUsersWithDifferentIds() throws {
        let initialVersion = "2.110.0"

        let uniqueUser1: (UUID?, String?) = (UUID(), nil)
        let uniqueUser2: (UUID?, String?) = (UUID(), "test.example.com")
        let otherDuplicateUsers = (UUID(), "otherdomain")

        try helper.migrateStoreToCurrentVersion(
            sourceVersion: initialVersion,
            preMigrationAction: { context in
                insertDuplicateUsers(with: userId, domain: domain, in: context)
                insertDuplicateUsers(with: otherDuplicateUsers.0, domain: otherDuplicateUsers.1, in: context)
                _ = context.performGroupedAndWait {
                    let user = ZMUser(context: context)
                    user.remoteIdentifier = uniqueUser1.0
                    user.domain = uniqueUser1.1
                    return user
                }

                _ = context.performGroupedAndWait {
                    let user = ZMUser(context: context)
                    user.remoteIdentifier = uniqueUser2.0
                    user.domain = uniqueUser2.1
                    return user
                }

                try context.save()

                let clients = try fetchUsers(with: userId, domain: domain, in: context)
                XCTAssertEqual(clients.count, 2)
            },
            postMigrationAction: { context in
                try context.performGroupedAndWait {
                    // verify it deleted duplicates
                    var clients = try fetchUsers(with: userId, domain: domain, in: context)
                    XCTAssertEqual(clients.count, 1)

                    clients = try fetchUsers(with: uniqueUser1.0, domain: uniqueUser1.1, in: context)
                    XCTAssertEqual(clients.count, 1)

                    clients = try fetchUsers(with: uniqueUser2.0, domain: uniqueUser2.1, in: context)
                    XCTAssertEqual(clients.count, 1)

                    clients = try fetchUsers(with: otherDuplicateUsers.0, domain: otherDuplicateUsers.1, in: context)
                    XCTAssertEqual(clients.count, 1)

                    // verify we can't insert duplicates
                    context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    insertDuplicateUsers(with: userId, domain: domain, in: context)
                    try context.save()

                    clients = try fetchUsers(with: userId, domain: domain, in: context)
                    XCTAssertEqual(clients.count, 1)
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
                insertDuplicateUsers(with: userId, domain: domain, in: context)
                try context.save()

                let clients = try fetchUsers(with: userId, domain: domain, in: context)
                XCTAssertEqual(clients.count, 2)
            },
            postMigrationAction: { context in
                try context.performGroupedAndWait {
                    // verify it deleted duplicates
                    var clients = try fetchUsers(with: userId, domain: domain, in: context)

                    XCTAssertEqual(clients.count, 1)

                    // verify we can't insert duplicates
                    context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    insertDuplicateUsers(with: userId, domain: domain, in: context)
                    try context.save()

                    clients = try fetchUsers(with: userId, domain: domain, in: context)
                    XCTAssertEqual(clients.count, 1)

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
    private let userId = UUID()
    private let domain = "example.com"
    private let tmpStoreURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())DatabaseMigrationTests_UserUniqueness/")
    private let helper = DatabaseMigrationHelper()

    // MARK: - Fetch / Insert Helpers

    private func fetchUsers(
        with identifier: UUID?,
        domain: String?,
        in context: NSManagedObjectContext
    ) throws -> [ZMUser] {
        let fetchRequest = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
        var predicates = [NSPredicate]()
        if let domain {
            predicates.append(
                NSPredicate(format: "%K == %@", #keyPath(ZMUser.domain), domain)
            )
        }

        if let identifier {
            predicates.append(
                NSPredicate(format: "%K == %@", ZMUser.remoteIdentifierDataKey(), identifier.uuidData as CVarArg)
            )
        }

        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return try context.fetch(fetchRequest)
    }

    private func insertDuplicateUsers(
        with identifier: UUID,
        domain: String,
        in context: NSManagedObjectContext
    ) {
        let duplicate1 = ZMUser.insertNewObject(in: context)
        duplicate1.remoteIdentifier = identifier
        duplicate1.domain = domain

        let duplicate2 = ZMUser.insertNewObject(in: context)
        duplicate2.remoteIdentifier = identifier
        duplicate2.domain = domain
    }
}
