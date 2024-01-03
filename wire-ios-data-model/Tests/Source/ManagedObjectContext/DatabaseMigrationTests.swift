//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
//

@testable import WireDataModel
import XCTest

final class DatabaseMigrationTests: DatabaseBaseTest {

    private let helper = DatabaseMigrationHelper()

    private let userPropertiesToFetch = [
        "accentColorValue",
        "emailAddress",
        "modifiedKeys",
        "name",
        "normalizedEmailAddress",
        "normalizedName",
        "handle"
    ]

    func testMessagingLatestModelHasMigrationVersion() throws {
        // given
        let dataModelVersion = CoreDataStack.loadMessagingModel().version

        // when
        let latestMigrationVersion = CoreDataMessagingMigrationVersion.allCases.first

        // then
        XCTAssertEqual(
            latestMigrationVersion?.dataModelVersion,
            dataModelVersion,
            "Current model version '\(dataModelVersion)' does not exist as core data migration version! " +
            "Please add a new case for the version, so that the migration to that version is ensured!"
        )
    }

    func testThatItPerformsMigrationFrom_Between_2_80_0_and_PreLast_ToCurrentModelVersion() throws {
        // NOTICE: When a new version of data model is created, please increase the last number of the array.
        let allVersions = [80...111]
            .joined()
            .map { "2-\($0)-0" }
        let modelVersion = CoreDataStack.loadMessagingModel().version
        let fixtureVersion = String(helper.databaseFixtureFileName(for: modelVersion).dropFirst("store".count))
        let accountIdentifier = UUID()

        // Check that we have current version fixture file
        guard helper.databaseFixtureURL(version: modelVersion) != nil else {
            let versionsWithoutCurrent = allVersions.filter { $0 != fixtureVersion }

            try helper.createFixtureDatabase(
                applicationContainer: DatabaseBaseTest.applicationContainer,
                accountIdentifier: accountIdentifier,
                versionName: versionsWithoutCurrent.last!
            )
            let directory = createStorageStackAndWaitForCompletion(userID: accountIdentifier)
            let currentDatabaseURL = directory.syncContext.persistentStoreCoordinator!.persistentStores.last!.url!

            XCTFail("\nMissing current version database file: `store\(fixtureVersion).wiredatabase`. \n\n" +
                    "**HOW TO FIX THIS** \n" +
                    "- Run the test, until you hit the assertion\n" +
                    "- **WHILE THE TEST IS PAUSED** on the assertion, do the following:\n" +
                    "- open the the folder in Finder by typing this command in your terminal. IT WILL NOT WORK IF THE TEST IS NOT PAUSED!!!.\n" +
                    "\t cp \"\(currentDatabaseURL.path)\" ~/Desktop/store\(fixtureVersion).wiredatabase\n\n" +
                    "- The command will copy a file on your desktop called `store\(fixtureVersion).wiredatabase`\n" +
                    "- Copy it to test bundle if this project in `WireDataModel/Tests/Resources` with the other stores\n\n")
            assert(false)
        }

        guard allVersions.contains(fixtureVersion) else {
            return XCTFail("Current model version '\(fixtureVersion)' is not added to allVersions array. \n" +
                "Please add it to the array above, so that we are sure it's there when we bump to the next version\n" +
                "and we don't forget to test the migration from that version")
        }

        try allVersions.forEach { version in
            // GIVEN
            try helper.createFixtureDatabase(
                applicationContainer: DatabaseBaseTest.applicationContainer,
                accountIdentifier: accountIdentifier,
                versionName: version
            )

            // WHEN
            var directory: CoreDataStack! = createStorageStackAndWaitForCompletion(userID: accountIdentifier)

            // THEN
            let conversationCount = try directory.viewContext.count(for: ZMConversation.sortedFetchRequest())
            let messageCount = try directory.viewContext.count(for: ZMClientMessage.sortedFetchRequest())
            let systemMessageCount = try directory.viewContext.count(for: ZMSystemMessage.sortedFetchRequest())
            let connectionCount = try directory.viewContext.count(for: ZMConnection.sortedFetchRequest())
            let userClientCount = try directory.viewContext.count(for: UserClient.sortedFetchRequest())
            let assetClientMessagesCount = try directory.viewContext.count(for: ZMAssetClientMessage.sortedFetchRequest())
            let messages = directory.viewContext.executeFetchRequestOrAssert(ZMMessage.sortedFetchRequest()) as! [ZMMessage]
            let users = directory.viewContext.fetchOrAssert(request: NSFetchRequest<ZMUser>(entityName: ZMUser.entityName()))

            let userFetchRequest = ZMUser.sortedFetchRequest()
            userFetchRequest.resultType = .dictionaryResultType
            userFetchRequest.propertiesToFetch = userPropertiesToFetch
            let userDictionaries = directory.viewContext.executeFetchRequestOrAssert(userFetchRequest)

            // THEN
            XCTAssertEqual(assetClientMessagesCount, 0)
            XCTAssertEqual(conversationCount, 20)
            XCTAssertEqual(messageCount, 3)
            XCTAssertEqual(systemMessageCount, 21)
            XCTAssertEqual(connectionCount, 16)
            XCTAssertEqual(userClientCount, 12)

            XCTAssertNotNil(userDictionaries)
            XCTAssertEqual(userDictionaries.count, 22)

            users.forEach({
                XCTAssertFalse($0.isAccountDeleted)
            })

            XCTAssertGreaterThan(messages.count, 0)
            messages.forEach {
                XCTAssertNil($0.normalizedText)
            }

            directory = nil // need to release
            clearStorageFolder()
        }
    }

    func testThatTheVersionIdentifiersMatchModelNameAndDoNotDuplicate() throws {
        // given
        guard let source = Bundle(for: ZMMessage.self).url(forResource: "zmessaging", withExtension: "momd") else {
            fatalError("missing resource")
        }
        let fm = FileManager.default

        let regex = try NSRegularExpression(pattern: "[0-9\\.]+[0-9]+")

        var processedVersions = Set<String>()

        try fm.contentsOfDirectory(atPath: source.path).filter { URL(fileURLWithPath: $0).pathExtension == "mom" } .forEach { modelFileName in

            let nameMatches = regex.matches(in: modelFileName, range: NSRange(modelFileName.startIndex..., in: modelFileName)).map {
                String(modelFileName[Range($0.range, in: modelFileName)!])
            }

            guard let version = nameMatches.first else {
                fatal("Wrong name format: \(modelFileName)")
            }

            XCTAssertFalse(processedVersions.contains(version))

            let store = NSManagedObjectModel(contentsOf: source.appendingPathComponent(modelFileName))!
            // then
            XCTAssertTrue(store.versionIdentifiers.contains(version), "\(version) should be contained")
            processedVersions.insert(version)
        }
    }
}
