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

enum Database {
    case messaging
    case event

    func databaseFixtureFileName(for version: String) -> String {
        switch self {
        case .messaging:
            // The naming scheme is slightly different for fixture files
            let fixedVersion = version.replacingOccurrences(of: ".", with: "-")
            let name = "store" + fixedVersion
            return name
        case .event:
            return "event_\(version)"
        }
    }

    var `extension`: String {
        switch self {
        case .messaging:
            "wiredatabase"
        case .event:
            "sqlite"
        }
    }
}

struct DatabaseMigrationHelper {
    typealias MigrationAction = (NSManagedObjectContext) throws -> Void

    private let bundle = WireDataModelBundle.bundle
    private let dataModelName = "zmessaging"

    func createObjectModel(version: String) throws -> NSManagedObjectModel {
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

    func createStore(model: NSManagedObjectModel, at storeURL: URL) throws -> NSPersistentContainer {
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

    // MARK: - Migration

    func migrateStore(
        sourceVersion: String,
        destinationVersion: String,
        mappingModel: NSMappingModel,
        storeDirectory: URL,
        preMigrationAction: MigrationAction,
        postMigrationAction: MigrationAction,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        // GIVEN

        // create versions models
        let sourceModel = try createObjectModel(version: sourceVersion)
        let destinationModel = try createObjectModel(version: destinationVersion)

        let sourceStoreURL = storeDirectory.appendingPathComponent("\(sourceVersion).sqlite")
        let destinationStoreURL = storeDirectory.appendingPathComponent("\(destinationVersion).sqlite")

        // create container for initial version
        let container = try createStore(model: sourceModel, at: sourceStoreURL)

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
            XCTFail("Migration failed: \(error)", file: file, line: line)
        }

        // THEN

        // create store
        let migratedContainer = try createStore(model: destinationModel, at: destinationStoreURL)

        // perform post migration action
        try postMigrationAction(migratedContainer.viewContext)
    }

    // MARK: Fixture

    func createFixtureDatabase(
        applicationContainer: URL,
        accountIdentifier: UUID,
        versionName: String,
        database: Database = .messaging,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        var storeFile = CoreDataStack.accountDataFolder(
            accountIdentifier: accountIdentifier,
            applicationContainer: applicationContainer
        )
        switch database {
        case .messaging:
            storeFile = storeFile.appendingPersistentStoreLocation()
        case .event:
            storeFile = storeFile.appendingEventStoreLocation()
        }

        try createFixtureDatabase(storeFile: storeFile, versionName: versionName, database: database)
    }

    func createFixtureDatabase(
        storeFile: URL,
        versionName: String,
        database: Database = .messaging,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        try FileManager.default.createDirectory(
            at: storeFile.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        // copy old version database into the expected location
        guard let source = databaseFixtureURL(version: versionName, database: database, file: file, line: line) else {
            return
        }
        try FileManager.default.copyItem(at: source, to: storeFile)
    }

    func databaseFixtureURL(
        version: String,
        database: Database = .messaging,
        file: StaticString = #file,
        line: UInt = #line
    ) -> URL? {
        let name = database.databaseFixtureFileName(for: version)

        guard let source = WireDataModelTestsBundle.bundle.url(forResource: name, withExtension: database.extension)
        else {
            XCTFail("Could not find \(name).\(database.extension) in test bundle", file: file, line: line)
            return nil
        }
        return source
    }

    // MARK: - Migration Helpers

    func migrateStoreToCurrentVersion(
        sourceVersion: String,
        preMigrationAction: MigrationAction,
        postMigrationAction: MigrationAction,
        for testCase: XCTestCase
    ) throws {
        // GIVEN
        let accountIdentifier = UUID()
        let applicationContainer = DatabaseBaseTest.applicationContainer

        // copy given database as source
        let storeFile = CoreDataStack.accountDataFolder(
            accountIdentifier: accountIdentifier,
            applicationContainer: applicationContainer
        ).appendingPersistentStoreLocation()

        try createFixtureDatabase(
            storeFile: storeFile,
            versionName: sourceVersion
        )

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
        var stack: CoreDataStack? = try testCase.createStorageStackAndWaitForCompletion(
            userID: accountIdentifier,
            applicationContainer: applicationContainer
        )

        // THEN
        // perform post migration action
        if let stack {
            try postMigrationAction(stack.syncContext)
        }

        // remove complete stack before removing files
        stack = nil
        try? FileManager.default.removeItem(at: applicationContainer)
    }
}

private final class WireDataModelTestsBundle {
    static let bundle = Bundle(for: WireDataModelTestsBundle.self)
}

extension XCTestCase {
    func createStorageStackAndWaitForCompletion(
        userID: UUID,
        applicationContainer: URL,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> CoreDataStack {
        let account = Account(
            userName: "",
            userIdentifier: userID
        )
        let stack = CoreDataStack(
            account: account,
            applicationContainer: applicationContainer,
            inMemoryStore: false
        )

        let exp = expectation(description: "should wait for loadStores to finish")
        var setupError: Error?
        stack.setup(onStartMigration: {
            // do nothing
        }, onFailure: { error in
            setupError = error
            exp.fulfill()
        }, onCompletion: { _ in
            exp.fulfill()
        })
        wait(for: [exp], timeout: 5)

        if let setupError {
            throw setupError
        }

        return stack
    }
}
