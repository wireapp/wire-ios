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

import Foundation
import XCTest
@testable import WireDataModel

class DatabaseMigrationTests_OneOnOneConversation: XCTestCase {
    // MARK: Internal

    override func setUpWithError() throws {
        try super.setUpWithError()
        try FileManager.default.createDirectory(at: tmpStoreURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: tmpStoreURL)
        try super.tearDownWithError()
    }

    func testMigratingToMessagingStore_from2_113_updatesRelationships() throws {
        let selfUserID = UUID.create()
        let teamID = UUID.create()

        let connectedUserID = UUID.create()
        let connectedConversationID = UUID.create()

        let teamUser1ID = UUID.create()
        let teamConversation1ID = UUID.create()

        let teamUser2ID = UUID.create()
        let teamConversation2ID = UUID.create()

        try helper.migrateStoreToCurrentVersion(
            sourceVersion: "2.113.0",
            preMigrationAction: { context in
                let selfUser = ZMUser.selfUser(in: context)
                selfUser.remoteIdentifier = selfUserID

                let connectedUser = ZMUser.insertNewObject(in: context)
                connectedUser.remoteIdentifier = connectedUserID

                let teamUser1 = ZMUser.insertNewObject(in: context)
                teamUser1.remoteIdentifier = teamUser1ID

                let teamUser2 = ZMUser.insertNewObject(in: context)
                teamUser2.remoteIdentifier = teamUser2ID

                let team = Team.insertNewObject(in: context)
                team.remoteIdentifier = teamID
                addUser(selfUser, to: team, in: context)
                addUser(teamUser1, to: team, in: context)

                let (connectedConversation, connection) = createConnectedConversation(
                    id: connectedConversationID,
                    with: connectedUser,
                    in: context
                )

                let teamOneOnOneConversation = createTeamConversation(
                    id: teamConversation1ID,
                    team: team,
                    with: [selfUser, teamUser1],
                    in: context
                )

                let teamGroupConversation = createTeamConversation(
                    id: teamConversation2ID,
                    team: team,
                    with: [selfUser, teamUser2],
                    name: "Not a one on one!",
                    in: context
                )

                try context.save()

                XCTAssertEqual(connectedConversation.conversationType, .oneOnOne)
                XCTAssertEqual(connectedConversation.value(forKey: "connection") as? ZMConnection, connection)
                XCTAssertEqual(connectedUser.connection, connection)
                XCTAssertEqual(teamOneOnOneConversation.conversationType, .oneOnOne)
                XCTAssertEqual(teamGroupConversation.conversationType, .group)
            },
            postMigrationAction: { context in
                try context.performGroupedAndWait {
                    let selfUser = try XCTUnwrap(ZMUser.fetch(with: selfUserID, in: context))
                    XCTAssertNil(selfUser.oneOnOneConversation)

                    // Connected conversation was migrated.
                    let connectedUser = try XCTUnwrap(ZMUser.fetch(with: connectedUserID, in: context))
                    let connectedConversation = try XCTUnwrap(ZMConversation.fetch(
                        with: connectedConversationID,
                        in: context
                    ))
                    XCTAssertEqual(connectedUser.oneOnOneConversation, connectedConversation)
                    XCTAssertEqual(connectedConversation.oneOnOneUser, connectedUser)

                    // Team one on one was migrated.
                    let teamUser1 = try XCTUnwrap(ZMUser.fetch(with: teamUser1ID, in: context))
                    let teamConversation1 = try XCTUnwrap(ZMConversation.fetch(with: teamConversation1ID, in: context))
                    XCTAssertEqual(teamUser1.oneOnOneConversation, teamConversation1)
                    XCTAssertEqual(teamConversation1.oneOnOneUser, teamUser1)

                    // Team group was not migrated.
                    let teamUser2 = try XCTUnwrap(ZMUser.fetch(with: teamUser2ID, in: context))
                    let teamConversation2 = try XCTUnwrap(ZMConversation.fetch(with: teamConversation2ID, in: context))
                    XCTAssertNil(teamUser2.oneOnOneConversation)
                    XCTAssertNil(teamConversation2.oneOnOneUser)
                }
            },
            for: self
        )
    }

    // MARK: Private

    private let bundle = Bundle(for: ZMManagedObject.self)
    private let tmpStoreURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())databasetest/")
    private let helper = DatabaseMigrationHelper()

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

    private func createTeamConversation(
        id: UUID,
        team: Team,
        with users: [ZMUser],
        name: String? = nil,
        in context: NSManagedObjectContext
    ) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.remoteIdentifier = id
        conversation.team = team
        conversation.teamRemoteIdentifier = team.remoteIdentifier
        conversation.conversationType = .group
        conversation.userDefinedName = name

        for user in users {
            let participation = ParticipantRole.insertNewObject(in: context)
            participation.conversation = conversation
            participation.user = user
        }

        return conversation
    }
}
