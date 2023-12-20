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

final class DatabaseMigrationTests_UserClientUniqueness: DatabaseBaseTest {

    typealias MigrationAction = (NSManagedObjectContext) throws -> Void

    private let bundle = Bundle(for: ZMManagedObject.self)
    private let clientID = "abc123"
    private let tmpStoreURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())databasetest/")
    private let dataModelName = "zmessaging"

    func testThatItPerformsMigrationFromOldVersionsBefore107_ToCurrentModelVersion() throws {
        // With version 107 and later we can not insert duplicated keys anymore!

        let versions = [(84...96), (98...106)].joined().map {
            "2.\($0).0"
        }

        try versions.forEach { initialVersion in
            try migrateStoreToCurrentVersion(
                sourceVersion: initialVersion,
                preMigrationAction: insertDuplicates,
                postMigrationAction: assertDuplicatesResolved
            )
            // clean after each test
            self.clearStorageFolder()
        }
    }

    func testMigratingToMessagingStore_2_107_PreventsDuplicateUserClients() throws {
        let mappingModelURL = bundle.url(forResource: "MappingModel_2.106-2.107", withExtension: "cdm")
        let mappingModel = try XCTUnwrap(NSMappingModel(contentsOf: mappingModelURL))

        try migrateStore(
            sourceVersion: "2.106.0",
            destinationVersion: "2.107.0",
            mappingModel: mappingModel,
            preMigrationAction: insertDuplicates,
            postMigrationAction: assertDuplicatesResolved
        )
    }

    private func insertDuplicates(in context: NSManagedObjectContext) throws {
        // insert some duplicates
        try insertDuplicateClients(with: clientID, in: context)
        let clients = try fetchClients(with: clientID, in: context)
        XCTAssertEqual(clients.count, 2)
    }

    private func assertDuplicatesResolved(in context: NSManagedObjectContext) throws {
        var clients: [UserClient]

        // verify it deleted duplicates
        clients = try fetchClients(with: clientID, in: context)
        XCTAssertEqual(clients.count, 1)

        // verify we can't insert duplicates
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        try insertDuplicateClients(with: clientID, in: context)
        clients = try fetchClients(with: clientID, in: context)
        XCTAssertEqual(clients.count, 1)
    }

    // MARK: - Migration Helpers

    private func migrateStoreToCurrentVersion(
        sourceVersion: String,
        preMigrationAction: MigrationAction,
        postMigrationAction: MigrationAction
    ) throws {
        // GIVEN
        let userId = DatabaseMigrationTests.testUUID
        let fixedVersion = sourceVersion.replacingOccurrences(of: ".", with: "-")

        // copy given database as source
        try createDatabaseWithOlderModelVersion(versionName: fixedVersion)

        let storeFile = CoreDataStack.accountDataFolder(accountIdentifier: userId,
                                                        applicationContainer: self.applicationContainer).appendingPersistentStoreLocation()
        let sourceModel = try createObjectModel(version: sourceVersion)
        var sourceContainer: NSPersistentContainer? = try createStore(model: sourceModel, at: storeFile)

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
        let stack = createStorageStackAndWaitForCompletion(userID: userId)

        // THEN
        // perform post migration action
        try postMigrationAction(stack.viewContext)

        // cleanup
        cleanupStoreDirectory()
    }

    private func migrateStore(
        sourceVersion: String,
        destinationVersion: String,
        mappingModel: NSMappingModel,
        preMigrationAction: MigrationAction,
        postMigrationAction: MigrationAction
    ) throws {
        // GIVEN

        // set up temporary directory
        try setupStoreDirectory()

        // create versions models
        let sourceModel = try createObjectModel(version: sourceVersion)
        let destinationModel = try createObjectModel(version: destinationVersion)

        // create container for initial version
        let container = try createStore(version: sourceVersion, model: sourceModel)

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
                from: container.persistentStoreCoordinator.persistentStores.first!.url!,
                sourceType: NSSQLiteStoreType,
                options: nil,
                with: mappingModel,
                toDestinationURL: storeURL(version: destinationVersion),
                destinationType: NSSQLiteStoreType,
                destinationOptions: nil
            )
        } catch {
            XCTFail("Migration failed: \(error)")
        }

        // THEN

        // create store
        let migratedContainer = try createStore(version: destinationVersion, model: destinationModel)

        // perform post migration action
        try postMigrationAction(migratedContainer.viewContext)

        // cleanup
        cleanupStoreDirectory()
    }

    private func createObjectModel(version: String) throws -> NSManagedObjectModel {
        let modelVersion = "\(dataModelName)\(version)"

        // Get the compiled datamodel file bundle
        let modelURL = try XCTUnwrap(bundle.url(
            forResource: dataModelName,
            withExtension: "momd"
        ))
        let modelBundle = try XCTUnwrap(Bundle(url: modelURL))

        // Create the url for the given datamodel version
        let modelVersionURL = try XCTUnwrap(modelBundle.url(
            forResource: modelVersion,
            withExtension: "mom"
        ), "\(modelVersion).mom not found in Bundle \(modelBundle)")

        // Create the versioned model from the url
        return try XCTUnwrap(NSManagedObjectModel(contentsOf: modelVersionURL))
    }

    private func createStore(version: String, model: NSManagedObjectModel) throws -> NSPersistentContainer {
        let storeURL = storeURL(version: version)

       return try createStore(model: model, at: storeURL)
    }

    private func createStore(model: NSManagedObjectModel, at storeURL: URL) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(
            name: dataModelName,
            managedObjectModel: model
        )

        try container.persistentStoreCoordinator.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: storeURL,
            options: nil
        )

        return container
    }

    // MARK: - File Helpers

    private func setupStoreDirectory() throws {
        cleanupStoreDirectory()
        try FileManager.default.createDirectory(at: tmpStoreURL, withIntermediateDirectories: true)
    }

    private func cleanupStoreDirectory() {
        try? FileManager.default.removeItem(at: tmpStoreURL)
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
    ) throws {

        let duplicate1 = UserClient.insertNewObject(in: context)
        duplicate1.remoteIdentifier = identifier

        let duplicate2 = UserClient.insertNewObject(in: context)
        duplicate2.remoteIdentifier = identifier

        try context.save()
    }

}
