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

import XCTest
@testable import WireDataModel

final class DatabaseRemoteIdentifierUniquenessTests: XCTestCase {
    // MARK: Internal

    var helper: DatabaseMigrationHelper!

    override func setUpWithError() throws {
        helper = DatabaseMigrationHelper()
    }

    override func tearDownWithError() throws {
        helper = nil
    }

    func testMigratingDatabase_WithConversationWithNoRemoteIdentifier_ShouldSucceed() throws {
        try internalTestMigratingDatabase_WithEntityWithNoRemoteIdentifier(
            sourceVersion: "2.110.0",
            entity: ZMConversation.self
        )
    }

    func testMigratingDatabase_WithTeamWithNoRemoteIdentifier_ShouldSucceed() throws {
        // it is not problem here, because remoteIdentifier is a String
        try internalTestMigratingDatabase_WithEntityWithNoRemoteIdentifier(
            sourceVersion: "2.110.0",
            entity: Team.self
        )
    }

    func testMigratingDatabase_WithUserWithNoRemoteIdentifier_ShouldSucceed() throws {
        try internalTestMigratingDatabase_WithEntityWithNoRemoteIdentifier(
            sourceVersion: "2.110.0",
            entity: ZMUser.self
        )
    }

    func testMigratingDatabase_WithUserClientWithNoRemoteIdentifier_ShouldSucceed() throws {
        // it is not problem here, because remoteIdentifier is a String
        try internalTestMigratingDatabase_WithEntityWithNoRemoteIdentifier(
            sourceVersion: "2.106.0",
            entity: UserClient.self
        )
    }

    // MARK: Private

    private func internalTestMigratingDatabase_WithEntityWithNoRemoteIdentifier<T: ZMManagedObject>(
        sourceVersion: String,
        entity: T
            .Type
    ) throws {
        let count = 100
        try helper.migrateStoreToCurrentVersion(
            sourceVersion: sourceVersion,
            preMigrationAction: { context in

                for _ in 1 ... count {
                    // object with no remoteIdentifier
                    _ = T.insertNewObject(in: context)
                }
                try context.save()

            },
            postMigrationAction: { context in
                try context.performAndWait {
                    let request = NSFetchRequest<NSManagedObject>(
                        entityName: T
                            .entityName()
                    )
                    let result = try context.fetch(request)
                    XCTAssertNotEqual(result.count, count)
                }
            },
            for: self
        )
    }
}
