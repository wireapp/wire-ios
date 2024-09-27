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

final class DatabaseMigrationTests_Conversations: XCTestCase {
    // MARK: Internal

    func testThatItPerformsMigrationFrom106_deleteConversationCascadesToParticipantRole() throws {
        try migrateStoreToCurrentVersion(
            sourceVersion: "2.106.0",
            preMigrationAction: { context in
                let user = ZMUser(context: context)
                user.remoteIdentifier = UUID()
                let conversation = ZMConversation(context: context)
                conversation.remoteIdentifier = UUID()
                let participantRole = ParticipantRole(context: context)
                participantRole.conversation = conversation
                participantRole.user = user
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

    func testThatItPerformsMigrationFrom106_deleteRemotelyConversationKeepsParticipantRole() throws {
        try migrateStoreToCurrentVersion(
            sourceVersion: "2.106.0",
            preMigrationAction: { context in
                let user = ZMUser(context: context)
                user.remoteIdentifier = UUID()
                let conversation = ZMConversation(context: context)
                conversation.remoteIdentifier = UUID()
                let participantRole = ParticipantRole(context: context)
                participantRole.conversation = conversation
                participantRole.user = user
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

    func testThatItPerformsMigrationFrom106_validConversationRelationKeepsParticipantRole() throws {
        try migrateStoreToCurrentVersion(
            sourceVersion: "2.106.0",
            preMigrationAction: { context in
                let user = ZMUser(context: context)
                user.remoteIdentifier = UUID()
                let conversation = ZMConversation(context: context)
                conversation.remoteIdentifier = UUID()
                let participantRole = ParticipantRole(context: context)
                participantRole.conversation = conversation
                participantRole.user = user
                try context.save()
            },
            postMigrationAction: { context in
                let roles = try context.fetch(ParticipantRole.fetchRequest())
                XCTAssertEqual(roles.count, 1)
            }
        )
    }

    // [WPB-5993] Jira-Ticket "fix core data migrating corrupted ParticipantRole objects"
    //
    // This test was creating an error thrown by core data migration. Now this behavior is solved.
    //
    // In order to recreate this the failure migration one needs to remove the
    // `RemoveZombieParticipantRolesMigrationPolicy`
    // from `MappingModel_2.106-2.107` where the mapping `ParticipantRoleToParticipantRole` happens.
    //
    // Example from the error:
    //
    // Error Domain=NSCocoaErrorDomain Code=1570 "conversation is a required value."
    // UserInfo={NSValidationErrorObject=<NSManagedObject: 0x283002bc0> (
    // entity: ParticipantRole;
    // id: 0x91c16ef3ddc135ae <x-coredata://AC33D7EC-1515-4FDB-9FBC-FE0BE37B1D4F/ParticipantRole/p7>;
    // data: {
    //     conversation = nil;
    //     modifiedKeys = nil;
    //     role = nil;
    //     user = "0x91c16ef3dd4134be <x-coredata://AC33D7EC-1515-4FDB-9FBC-FE0BE37B1D4F/User/p3>";
    // })
    func testThatItPerformsMigrationFrom106_invalidConversationRelationDropsParticipantRole() throws {
        try migrateStoreToCurrentVersion(
            sourceVersion: "2.106.0",
            preMigrationAction: { context in
                let user = ZMUser(context: context)
                let conversation = ZMConversation(context: context)
                let participantRole = ParticipantRole(context: context)
                participantRole.conversation = conversation
                participantRole.user = user
                try context.save()

                XCTAssertEqual(user.participantRoles.count, 1)

                // Failure: model requires 'conversation' to be non-optional!
                participantRole.conversation = nil
                try context.save()
            },
            postMigrationAction: { context in
                let roles = try context.fetch(ParticipantRole.fetchRequest())
                XCTAssert(roles.isEmpty)

                // Make sure the user object relation has been updated!
                let user = try context.fetch(NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())).first
                XCTAssertEqual(user?.participantRoles.count, 0)
            }
        )
    }

    // MARK: Private

    private let helper = DatabaseMigrationHelper()

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
}
