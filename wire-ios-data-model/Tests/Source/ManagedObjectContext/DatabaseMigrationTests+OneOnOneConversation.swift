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
import Foundation
@testable import WireDataModel

// TODO: deduplicate
class DatabaseMigrationTests_OneOnOneConversation: XCTestCase {

    typealias MigrationAction = (NSManagedObjectContext) throws -> Void

    private let bundle = Bundle(for: ZMManagedObject.self)
    private let clientID = "abc123"
    private let tmpStoreURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())databasetest/")
    private let helper = DatabaseMigrationHelper()

    override func setUpWithError() throws {
        try super.setUpWithError()
        try FileManager.default.createDirectory(at: tmpStoreURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: tmpStoreURL)
        try super.tearDownWithError()
    }

    func testMigratingToMessagingStore_2_113_UpdatesRelationships() throws {
        let mappingModelURL = bundle.url(
            forResource: "MappingModel_2.112-2.113",
            withExtension: "cdm"
        )

        let mappingModel = try XCTUnwrap(NSMappingModel(contentsOf: mappingModelURL))

        let userID = UUID.create()
        let conversationID = UUID.create()

        try migrateStore(
            sourceVersion: "2.112.0",
            destinationVersion: "2.113.0",
            mappingModel: mappingModel,
            preMigrationAction: { context in
                let user = ZMUser.insertNewObject(in: context)
                user.remoteIdentifier = userID

                let conversation = ZMConversation.insertNewObject(in: context)
                conversation.remoteIdentifier = conversationID
                conversation.conversationType = .oneOnOne

                let connection = ZMConnection.insertNewObject(in: context)
                connection.status = .accepted
                connection.to = user
                connection.conversation = conversation

                try context.save()

                XCTAssertEqual(conversation.connection, connection)
                XCTAssertEqual(user.connection, connection)
            },
            postMigrationAction: { context in
                let user = try XCTUnwrap(ZMUser.fetch(with: userID, in: context))
                let conversation = try XCTUnwrap(ZMConversation.fetch(with: conversationID, in: context))
                XCTAssertEqual(user.oneOnOneConversation, conversation)
                XCTAssertEqual(conversation.oneOnOneUser, user)
            }
        )
    }

    // MARK: - Migration Helpers

    private func migrateStore(
        sourceVersion: String,
        destinationVersion: String,
        mappingModel: NSMappingModel,
        preMigrationAction: MigrationAction,
        postMigrationAction: MigrationAction
    ) throws {
        // GIVEN

        // create versions models
        let sourceModel = try helper.createObjectModel(version: sourceVersion)
        let destinationModel = try helper.createObjectModel(version: destinationVersion)

        let sourceStoreURL = storeURL(version: sourceVersion)
        let destinationStoreURL = storeURL(version: destinationVersion)

        // create container for initial version
        let container = try helper.createStore(model: sourceModel, at: sourceStoreURL)

        // perform pre-migration action
        try preMigrationAction(container.viewContext)

        // create migration manager and mapping model
        let migrationManager = NSMigrationManager(
            sourceModel: sourceModel,
            destinationModel: destinationModel
        )

        // WHEN

        // perform migration
        do {
            try migrationManager.migrateStore(
                from: sourceStoreURL,
                sourceType: NSSQLiteStoreType,
                options: nil,
                with: mappingModel,
                toDestinationURL: destinationStoreURL,
                destinationType: NSSQLiteStoreType,
                destinationOptions: nil
            )
        } catch {
            XCTFail("Migration failed: \(error)")
        }

        // THEN

        // create store
        let migratedContainer = try helper.createStore(model: destinationModel, at: destinationStoreURL)

        // perform post migration action
        try postMigrationAction(migratedContainer.viewContext)
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
