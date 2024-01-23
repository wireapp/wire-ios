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

        let selfUserID = UUID.create()
        let teamID = UUID.create()

        let connectedUserID = UUID.create()
        let connectedConversationID = UUID.create()

        let teamUserID = UUID.create()
        let teamConversationID = UUID.create()

        try migrateStore(
            sourceVersion: "2.112.0",
            destinationVersion: "2.113.0",
            mappingModel: mappingModel,
            preMigrationAction: { context in
                let selfUser = ZMUser.selfUser(in: context)
                selfUser.remoteIdentifier = selfUserID

                let teamUser = ZMUser.insertNewObject(in: context)
                teamUser.remoteIdentifier = teamUserID

                let connectedUser = ZMUser.insertNewObject(in: context)
                connectedUser.remoteIdentifier = connectedUserID

                let team = Team.insertNewObject(in: context)
                team.remoteIdentifier = teamID
                addUser(selfUser, to: team, in: context)
                addUser(teamUser, to: team, in: context)

                let (connectedConversation, connection) = createConnectedConversation(
                    id: connectedConversationID,
                    with: connectedUser,
                    in: context
                )

                let teamOneOnOneConversation = createTeamOneOnOneConversation(
                    id: teamConversationID,
                    team: team,
                    with: [selfUser, teamUser],
                    in: context
                )

                try context.save()

                XCTAssertEqual(connectedConversation.conversationType, .oneOnOne)
                XCTAssertEqual(connectedConversation.value(forKey: "connection") as? ZMConnection, connection)
                XCTAssertEqual(connectedUser.connection, connection)

                XCTAssertEqual(teamOneOnOneConversation.conversationType, .oneOnOne)
            },
            postMigrationAction: { context in
                let selfUser = try XCTUnwrap(ZMUser.fetch(with: selfUserID, in: context))
                XCTAssertNil(selfUser.oneOnOneConversation)

                let connectedUser = try XCTUnwrap(ZMUser.fetch(with: connectedUserID, in: context))
                let connectedConversation = try XCTUnwrap(ZMConversation.fetch(with: connectedConversationID, in: context))
                XCTAssertEqual(connectedUser.oneOnOneConversation, connectedConversation)
                XCTAssertEqual(connectedConversation.oneOnOneUser, connectedUser)

                let teamUser = try XCTUnwrap(ZMUser.fetch(with: teamUserID, in: context))
                let teamConversation = try XCTUnwrap(ZMConversation.fetch(with: teamConversationID, in: context))
                XCTAssertEqual(teamUser.oneOnOneConversation, teamConversation)
                XCTAssertEqual(teamConversation.oneOnOneUser, teamUser)
            }
        )
    }

    private func addUser(
        _ user: ZMUser,
        to team: Team,
        in context: NSManagedObjectContext
    ) {
        let member = Member.insertNewObject(in: context)
        member.team = team
        member.user = user
    }

    private func createConnectedConversation(
        id: UUID,
        with user: ZMUser,
        in context: NSManagedObjectContext
    ) -> (ZMConversation, ZMConnection) {
        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.remoteIdentifier = id
        conversation.conversationType = .oneOnOne

        let connection = ZMConnection.insertNewObject(in: context)
        connection.status = .accepted
        connection.to = user

        // The connection.conversation <-> conversation.connection relationship
        // was deleted in version 2.113, so we set the value this way.
        connection.setValue(conversation, forKey: "conversation")

        return (conversation, connection)
    }

    private func createTeamOneOnOneConversation(
        id: UUID,
        team: Team,
        with users: [ZMUser],
        in context: NSManagedObjectContext
    ) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.remoteIdentifier = id
        conversation.team = team
        conversation.teamRemoteIdentifier = team.remoteIdentifier
        conversation.conversationType = .group

        for user in users {
            let participation = ParticipantRole.insertNewObject(in: context)
            participation.conversation = conversation
            participation.user = user
        }

        return conversation
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

    // MARK: - URL Helpers

    private func storeURL(version: String) -> URL {
        return tmpStoreURL.appendingPathComponent("\(version).sqlite")
    }

}
