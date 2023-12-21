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

final class DatabaseMigrationTests_Conversations: XCTestCase {

    private let helper = DatabaseMigrationHelper()

    func testThatItPerformsMigrationFrom106_deleteConversationCascadesToParticipantRole() throws {
        try migrateStoreToCurrentVersion(
            sourceVersion: "2.106.0",
            preMigrationAction: { context in
                let user = ZMUser(context: context)
                let conversation = ZMConversation(context: context)
                _ = ParticipantRole.create(managedObjectContext: context, user: user, conversation: conversation)
                try context.save()

                context.delete(conversation)
                try context.save()
            },
            postMigrationAction: { context in
                let roles = try context.fetch(ParticipantRole.fetchRequest())
                XCTAssert(roles.isEmpty)
            }
        )
    }

    func testThatItPerformsMigrationFrom106_markConversationAsDeletedKeepsParticipantRole() throws {
        try migrateStoreToCurrentVersion(
            sourceVersion: "2.106.0",
            preMigrationAction: { context in
                let user = ZMUser(context: context)
                let conversation = ZMConversation(context: context)
                _ = ParticipantRole.create(managedObjectContext: context, user: user, conversation: conversation)
                try context.save()

                conversation.isDeletedRemotely = true
                try context.save()
            },
            postMigrationAction: { context in
                let roles = try context.fetch(ParticipantRole.fetchRequest())
                XCTAssertEqual(roles.count, 1)
            }
        )
    }

    func testThatItPerformsMigrationFrom106_invalidParticipantRoleThrowsMigrateStoreFailed() throws {
        XCTAssertThrowsError(try migrateStoreToCurrentVersion(
            sourceVersion: "2.106.0",
            preMigrationAction: { context in
                let user = ZMUser(context: context)
                let conversation = ZMConversation(context: context)
                let participantRole = ParticipantRole(context: context)
                participantRole.conversation = conversation
                participantRole.user = user
                try context.save()

                // Produce Failure: model requires 'conversation' to be non-optional!
                participantRole.conversation = nil
                try context.save()
            },
            postMigrationAction: { context in
                let roles = try context.fetch(ParticipantRole.fetchRequest())
                XCTAssertEqual(roles.count, 0)
            }
        ), "expected CoreDataMessagingMigratorError.migrateStoreFailed") { error in
            switch error as? CoreDataMessagingMigratorError {
            case .migrateStoreFailed(let nsError as NSError):
                XCTAssertEqual(nsError.code, NSValidationMissingMandatoryPropertyError)
                XCTAssertEqual(nsError.domain, NSCocoaErrorDomain)
                XCTAssertFalse(nsError.userInfo.isEmpty)
            default:
                XCTFail("expected CoreDataMessagingMigratorError.migrateStoreFailed")
            }
        }
    }

    func testThatItPerformsMigrationFrom107_invalidParticipantRoleNotThrowsMigrateStoreFailed() throws {
        XCTAssertNoThrow(try migrateStoreToCurrentVersion(
            sourceVersion: "2.107.0",
            preMigrationAction: { context in
                let user = ZMUser(context: context)
                let conversation = ZMConversation(context: context)
                let participantRole = ParticipantRole(context: context)
                participantRole.conversation = conversation
                participantRole.user = user
                try context.save()

                // Produce Failure: model requires 'conversation' to be non-optional!
                participantRole.conversation = nil
                try context.save()
            },
            postMigrationAction: { context in
                let roles = try context.fetch(ParticipantRole.fetchRequest())
                XCTAssertEqual(roles.count, 1)
            }
        ))
    }

    // MARK: -

    private func migrateStoreToCurrentVersion(
        sourceVersion: String,
        preMigrationAction: (NSManagedObjectContext) throws -> Void,
        postMigrationAction: (NSManagedObjectContext) throws -> Void
    ) throws {
        // GIVEN
        let accountIdentifier = UUID()
        let applicationContainer = DatabaseBaseTest.applicationContainer

        // copy given database as source
        let storeFile = CoreDataStack.accountDataFolder(
            accountIdentifier: accountIdentifier,
            applicationContainer: applicationContainer
        ).appendingPersistentStoreLocation()

        try helper.createFixtureDatabase(storeFile: storeFile, versionName: sourceVersion)

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
        let stack = try createStorageStackAndWaitForCompletion(
            userID: accountIdentifier,
            applicationContainer: applicationContainer
        )

        // THEN
        // perform post migration action
        try postMigrationAction(stack.viewContext)

        try? FileManager.default.removeItem(at: applicationContainer)
    }

    private func createStorageStackAndWaitForCompletion(
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
