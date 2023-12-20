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

    func testThatItPerformsInferredMigration_deleteConversationCascadesToParticipantRole() throws {
        let sourceVersion = "2.107.0"
        let destinationVersion = "2.108.0"

        let mappingModel = try helper.inferredMappingModel(sourceVersion: sourceVersion, destinationVersion: destinationVersion)

        try migrateStore(
            sourceVersion: sourceVersion,
            destinationVersion: destinationVersion,
            mappingModel: mappingModel,
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

    func testThatItPerformsInferredMigration_markConversationAsDeletedKeepsParticipantRole() throws {
        let sourceVersion = "2.107.0"
        let destinationVersion = "2.108.0"

        let mappingModel = try helper.inferredMappingModel(sourceVersion: sourceVersion, destinationVersion: destinationVersion)

        try migrateStore(
            sourceVersion: sourceVersion,
            destinationVersion: destinationVersion,
            mappingModel: mappingModel,
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

    // MARK: -

    private func migrateStore(
        sourceVersion: String,
        destinationVersion: String,
        mappingModel: NSMappingModel,
        preMigrationAction: (NSManagedObjectContext) throws -> Void,
        postMigrationAction: (NSManagedObjectContext) throws -> Void
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

    // MARK: - URL Helpers

    private func storeURL(version: String) -> URL {
        return tmpStoreURL.appendingPathComponent("\(version).sqlite")
    }
}
