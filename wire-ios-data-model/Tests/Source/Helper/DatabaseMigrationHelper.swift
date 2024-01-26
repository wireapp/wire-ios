////
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
@testable import WireDataModel

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

    // MARK: Fixture

    func createFixtureDatabase(
        applicationContainer: URL,
        accountIdentifier: UUID,
        versionName: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let storeFile = CoreDataStack.accountDataFolder(
            accountIdentifier: accountIdentifier,
            applicationContainer: applicationContainer
        ).appendingPersistentStoreLocation()

        try createFixtureDatabase(storeFile: storeFile, versionName: versionName)
    }

    func createFixtureDatabase(
        storeFile: URL,
        versionName: String,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        try FileManager.default.createDirectory(at: storeFile.deletingLastPathComponent(), withIntermediateDirectories: true)

        // copy old version database into the expected location
        guard let source = databaseFixtureURL(version: versionName, file: file, line: line) else {
            return
        }
        try FileManager.default.copyItem(at: source, to: storeFile)
    }

    func databaseFixtureURL(version: String, file: StaticString = #file, line: UInt = #line) -> URL? {
        let name = databaseFixtureFileName(for: version)
        guard let source = WireDataModelTestsBundle.bundle.url(forResource: name, withExtension: "wiredatabase") else {
            XCTFail("Could not find \(name).wiredatabase in test bundle", file: file, line: line)
            return nil
        }
        return source
    }

    // The naming scheme is slightly different for fixture files
    func databaseFixtureFileName(for version: String) -> String {
        let fixedVersion = version.replacingOccurrences(of: ".", with: "-")
        let name = "store" + fixedVersion
        return name
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
        let stack = try testCase.createStorageStackAndWaitForCompletion(
            userID: accountIdentifier,
            applicationContainer: applicationContainer
        )

        // THEN
        // perform post migration action
        try postMigrationAction(stack.viewContext)

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
        var setupError: Error?
        stack.setup(onStartMigration: {
            // do nothing
        }, onFailure: { error in
            setupError = error
            exp.fulfill()
        }, onCompletion: { _ in
            exp.fulfill()
        })
        waitForExpectations(timeout: 5.0)

        if let setupError {
            throw setupError
        }

        BackgroundActivityFactory.shared.activityManager = nil
        XCTAssertFalse(BackgroundActivityFactory.shared.isActive, file: file, line: line)

        return stack
    }
}
