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

final class DatabaseMigrationTests_UserClientUniqueness: DatabaseMigrationTestBase {

    private let clientID = "abc123"

    func testThatItPerformsMigrationFromOldVersionsBefore107_ToCurrentModelVersion() throws {
        // With version 107 and later we can not insert duplicated keys anymore!

        let versions = [(84...96), (98...106)].joined().map {
            "2.\($0).0"
        }

        try versions.forEach { initialVersion in
            try migrateStoreToCurrentVersion(
                sourceVersion: initialVersion,
                preMigrationAction: { context in
                    insertDuplicateClients(with: clientID, in: context)
                    try context.save()

                    let clients = try fetchClients(with: clientID, in: context)
                    XCTAssertEqual(clients.count, 2)
                },
                postMigrationAction: { context in
                    // verify it deleted duplicates
                    var clients = try fetchClients(with: clientID, in: context)
                    XCTAssertEqual(clients.count, 1)

                    // verify we can't insert duplicates
                    context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    insertDuplicateClients(with: clientID, in: context)
                    try context.save()

                    clients = try fetchClients(with: clientID, in: context)
                    XCTAssertEqual(clients.count, 1)
                }
            )

            // clean after each test
            try? FileManager.default.removeItem(at: tmpStoreURL)
        }
    }

    func testMigratingToMessagingStore_2_107_DoNotPreventDuplicateNilUserClients() throws {
        let mappingModelURL = bundle.url(forResource: "MappingModel_2.106-2.107", withExtension: "cdm")
        let mappingModel = try XCTUnwrap(NSMappingModel(contentsOf: mappingModelURL))

        try migrateStore(
            sourceVersion: "2.106.0",
            destinationVersion: "2.107.0",
            mappingModel: mappingModel,
            preMigrationAction: { context in
                // given
                let duplicate1 = UserClient.insertNewObject(in: context)
                duplicate1.remoteIdentifier = nil

                let duplicate2 = UserClient.insertNewObject(in: context)
                duplicate2.remoteIdentifier = nil

                try context.save()
            },
            postMigrationAction: { context in
                // when
                let fetchRequest = NSFetchRequest<UserClient>(entityName: UserClient.entityName())
                fetchRequest.predicate = NSPredicate(format: "%K == nil", ZMUserClientRemoteIdentifierKey)
                let clients = try context.fetch(fetchRequest)

                // then
                XCTAssertEqual(clients.count, 2)
            }
        )
    }

    func testMigratingToMessagingStore_2_107_PreventsDuplicateUserClients() throws {
        let mappingModelURL = bundle.url(forResource: "MappingModel_2.106-2.107", withExtension: "cdm")
        let mappingModel = try XCTUnwrap(NSMappingModel(contentsOf: mappingModelURL))

        try migrateStore(
            sourceVersion: "2.106.0",
            destinationVersion: "2.107.0",
            mappingModel: mappingModel,
            preMigrationAction: { context in
                insertDuplicateClients(with: clientID, in: context)
                try context.save()

                let clients = try fetchClients(with: clientID, in: context)
                XCTAssertEqual(clients.count, 2)
            },
            postMigrationAction: { context in
                // verify it deleted duplicates
                var clients = try fetchClients(with: clientID, in: context)
                XCTAssertEqual(clients.count, 1)

                // verify we can't insert duplicates
                context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                insertDuplicateClients(with: clientID, in: context)
                try context.save()

                clients = try fetchClients(with: clientID, in: context)
                XCTAssertEqual(clients.count, 1)
            }
        )
    }

    // MARK: - Fetch / Insert Helpers

    private func fetchClients(
        with identifier: String,
        in context: NSManagedObjectContext
    ) throws -> [UserClient] {

        let fetchRequest = NSFetchRequest<UserClient>(entityName: UserClient.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@", ZMUserClientRemoteIdentifierKey, identifier)
        fetchRequest.fetchLimit = 2

        return try context.fetch(fetchRequest)
    }

    private func insertDuplicateClients(
        with identifier: String,
        in context: NSManagedObjectContext
    ) {
        let duplicate1 = UserClient.insertNewObject(in: context)
        duplicate1.remoteIdentifier = identifier

        let duplicate2 = UserClient.insertNewObject(in: context)
        duplicate2.remoteIdentifier = identifier
    }

}
