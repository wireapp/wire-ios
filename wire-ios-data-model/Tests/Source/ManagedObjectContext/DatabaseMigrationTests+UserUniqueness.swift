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

final class DatabaseMigrationTests_UserUniqueness: XCTestCase {

    typealias MigrationAction = (NSManagedObjectContext) throws -> Void

    private let bundle = Bundle(for: ZMManagedObject.self)
    private let userId = UUID()
    private let domain = "example.com"
    private let tmpStoreURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())databasetest/")
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
        // With version 107 and later we can not insert duplicated keys anymore!

        let initialVersion = "2.110.0"

        try migrateStoreToCurrentVersion(
            sourceVersion: initialVersion,
            preMigrationAction: { context in
                insertDuplicateUsers(with: userId, domain: domain, in: context)
                try context.save()

                let clients = try fetchUsers(with: userId, domain: domain, in: context)
                XCTAssertEqual(clients.count, 2)
            },
            postMigrationAction: { context in
                // verify it deleted duplicates
                var clients = try fetchUsers(with: userId, domain: domain, in: context)

                XCTAssertEqual(clients.count, 1)

                // verify we can't insert duplicates
                context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                insertDuplicateUsers(with: userId, domain: domain, in: context)
                try context.save()

                clients = try fetchUsers(with: userId, domain: domain, in: context)
                XCTAssertEqual(clients.count, 1)
            }
        )

        // clean after each test
        try? FileManager.default.removeItem(at: tmpStoreURL)

    }

    // MARK: - Migration Helpers

    private func migrateStoreToCurrentVersion(
        sourceVersion: String,
        preMigrationAction: MigrationAction,
        postMigrationAction: MigrationAction
    ) throws {
        // GIVEN
        let accountIdentifier = UUID()
        let applicationContainer = DatabaseBaseTest.applicationContainer

        // copy given database as source
        let storeFile = CoreDataStack.accountDataFolder(
            accountIdentifier: accountIdentifier,
            applicationContainer: applicationContainer
        ).appendingPersistentStoreLocation()

        try helper.createFixtureDatabase(
            storeFile: storeFile,
            versionName: sourceVersion
        )

        let sourceModel = try helper.createObjectModel(version: sourceVersion)
        var sourceContainer: NSPersistentContainer? = try helper.createStore(model: sourceModel, at: storeFile)

        // perform pre-migration action
        if let sourceContainer {
            try preMigrationAction(sourceContainer.viewContext)
        }

        // release store before actual test
        guard let store = sourceContainer?.persistentStoreCoordinator.persistentStores.first else {
            XCTFail("missing expected store")
            return
        }
        try sourceContainer?.persistentStoreCoordinator.remove(store)
        sourceContainer = nil

        // WHEN
        let stack = createStorageStackAndWaitForCompletion(
            userID: accountIdentifier,
            applicationContainer: applicationContainer
        )

        // THEN
        // perform post migration action
        try postMigrationAction(stack.viewContext)

        try? FileManager.default.removeItem(at: applicationContainer)
    }

    func createStorageStackAndWaitForCompletion(
        userID: UUID = UUID(),
        applicationContainer: URL,
        file: StaticString = #file,
        line: UInt = #line
    ) -> CoreDataStack {

        // we use backgroundActivity suring the setup so we need to mock for tests
        let manager = MockBackgroundActivityManager()
        BackgroundActivityFactory.shared.activityManager = manager

        let account = Account(
            userName: "",
            userIdentifier: userID
        )
        let stack = CoreDataStack(
            account: account,
            applicationContainer: applicationContainer,
            inMemoryStore: false
        )

        let exp = self.expectation(description: "should wait for loadStores to finish")
        stack.setup(onStartMigration: {
            // do nothing
        }, onFailure: { error in
            XCTAssertNil(error, file: file, line: line)
            exp.fulfill()
        }, onCompletion: { _ in
            exp.fulfill()
        })
        waitForExpectations(timeout: 5.0)

        BackgroundActivityFactory.shared.activityManager = nil
        XCTAssertFalse(BackgroundActivityFactory.shared.isActive, file: file, line: line)

        return stack
    }

    // MARK: - URL Helpers

    private func storeURL(version: String) -> URL {
        return tmpStoreURL.appendingPathComponent("\(version).sqlite")
    }

    // MARK: - Fetch / Insert Helpers

    private func fetchUsers(
        with identifier: UUID,
        domain: String,
        in context: NSManagedObjectContext
    ) throws -> [ZMUser] {
        let fetchRequest = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@ && %K == %@",
                                             ZMUser.remoteIdentifierDataKey()!, identifier.uuidData as CVarArg,
                                             #keyPath(ZMUser.domain), domain)
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
