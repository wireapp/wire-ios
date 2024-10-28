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
@testable import WireDataModel
import XCTest

final class DatabaseMigrationTests_TeamUniqueness: XCTestCase {

    private let bundle = Bundle(for: ZMManagedObject.self)
    private let teamId = UUID()
    private let tmpStoreURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())DatabaseMigrationTests_TeamUniqueness/")
    private let helper = DatabaseMigrationHelper()

    override func setUpWithError() throws {
        try super.setUpWithError()
        try FileManager.default.createDirectory(at: tmpStoreURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tmpStoreURL)
        try super.tearDownWithError()
    }

    func testThatItPerformsMigrationFrom110Version_ToCurrentModelVersion() throws {
        let initialVersion = "2.110.0"

        try helper.migrateStoreToCurrentVersion(
            sourceVersion: initialVersion,
            preMigrationAction: { context in
                insertDuplicateTeams(with: teamId, in: context)
                try context.save()

                let teams = try fetchTeams(with: teamId, in: context)
                XCTAssertEqual(teams.count, 2)
            },
            postMigrationAction: { context in
                try context.performAndWait { [self] in
                    // verify it deleted duplicates
                    var teams = try fetchTeams(with: teamId, in: context)

                    XCTAssertEqual(teams.count, 1)

                    // verify we can't insert duplicates
                    context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    insertDuplicateTeams(with: teamId, in: context)
                    try context.save()

                    teams = try fetchTeams(with: teamId, in: context)
                    XCTAssertEqual(teams.count, 1)

                    XCTAssertTrue(context.readAndResetSlowSyncFlag())
                    // the flag has been consumed
                    XCTAssertFalse(context.readAndResetSlowSyncFlag())

                }
            },
            for: self
        )
    }

    // MARK: - Fetch / Insert Helpers

    private func fetchTeams(
        with identifier: UUID,
        in context: NSManagedObjectContext
    ) throws -> [Team] {
        let fetchRequest = NSFetchRequest<Team>(entityName: Team.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Team.remoteIdentifierDataKey(), identifier.uuidData as CVarArg)
        return try context.fetch(fetchRequest)
    }

    private func insertDuplicateTeams(
        with identifier: UUID,

        in context: NSManagedObjectContext
    ) {
        let duplicate1 = Team.insertNewObject(in: context)
        duplicate1.remoteIdentifier = identifier

        let duplicate2 = Team.insertNewObject(in: context)
        duplicate2.remoteIdentifier = identifier
    }

}
