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
@testable import WireDataModel
import WireDataModelSupport

final class DatabaseMigrationTests_FixDuplicateOneOnOneConversations: XCTestCase {
    var coreDataStack: CoreDataStack!

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

    override func setUp() async throws {
        coreDataStack = try await CoreDataStackHelper().createStack()
    }

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    func test_migration_SetCorrect1on1AndMergeMessages() async throws {

        var oldConversationMessageNonces: [UUID]!
        var newConversationMessageNonces: [UUID]!

        try helper.migrateStoreToCurrentVersion(sourceVersion: "2.118.0",
                                            preMigrationAction: { context in
            try context.performAndWait {

                let model = ModelHelper()

                let selfUser = model.createSelfUser(domain: Scaffolding.domain, in: context)

                let otherUser = model.createUser(qualifiedID: Scaffolding.otherUserQualifiedID, in: context)

                let team = model.createTeam(in: context)
                model.addUsers([selfUser, otherUser], to: team, in: context)

                let oldOneOnOneConversation = model.createGroupConversation(id: Scaffolding.oldOneOnOneConversationID,
                                                                            with: Set([otherUser, selfUser]),
                                                                            team: selfUser.team,
                                                                            domain: selfUser.domain,
                                                                            in: context)
                oldOneOnOneConversation.messageProtocol = .proteus
                oldOneOnOneConversation.userDefinedName = nil

                try model.addTextMessages(to: oldOneOnOneConversation,
                                          messagePrefix: "oldConv from me",
                                          sender: selfUser,
                                          count: 3,
                                          in: context)
                try model.addTextMessages(to: oldOneOnOneConversation,
                                          messagePrefix: "oldConv from otherUser",
                                          sender: otherUser,
                                          count: 4,
                                          in: context)

                let newOneOnOneConversation = model.createGroupConversation(id: Scaffolding.newOneOnOneConversationID,
                                                                            with: Set([otherUser, selfUser]),
                                                                            team: selfUser.team,
                                                                            domain: selfUser.domain,
                                                                            in: context)
                newOneOnOneConversation.messageProtocol = .proteus
                newOneOnOneConversation.userDefinedName = nil
                // the default oneOnOne conversation done by the OneOnOneMigration was using first result of request instead of sorting by qualified id with ascending order, here let's assume we have the wrong one setup
                otherUser.setValue(newOneOnOneConversation, forKey: "oneOnOneConversation")

                try model.addTextMessages(to: newOneOnOneConversation,
                                          messagePrefix: "newConv from me",
                                          sender: selfUser,
                                          count: 1,
                                          in: context)
                try model.addTextMessages(to: newOneOnOneConversation,
                                          messagePrefix: "newConv from otherUser",
                                          sender: otherUser,
                                          count: 2,
                                          in: context)

                newConversationMessageNonces = newOneOnOneConversation.allMessages.compactMap {
                    $0.nonce
                }

                oldConversationMessageNonces = oldOneOnOneConversation.allMessages.compactMap {
                    $0.nonce
                }

                try context.save()
            }

        }, postMigrationAction: { context in

            try context.performAndWait {
                let selfUser = ZMUser.selfUser(in: context)

                let conversation = ZMConversation.fetch(with: Scaffolding.oldOneOnOneConversationID, domain: Scaffolding.domain, in: context)

                let oneOnOneConversation = try XCTUnwrap(conversation)
                XCTAssertEqual(oneOnOneConversation.qualifiedID?.uuid, Scaffolding.oldOneOnOneConversationID, "expect the patch to set the oldConversation as the new oneOnOne")

                XCTAssertEqual(oneOnOneConversation.allMessages.count, newConversationMessageNonces.count + oldConversationMessageNonces.count)

                let oneOnOneConversationMessageIds = Set(oneOnOneConversation.allMessages.compactMap { $0.nonce })
                XCTAssertEqual(oneOnOneConversationMessageIds, Set(oldConversationMessageNonces + newConversationMessageNonces))

                let otherUser = try XCTUnwrap(ZMUser.fetch(with: Scaffolding.otherUserQualifiedID.uuid,
                                                           domain: Scaffolding.otherUserQualifiedID.domain,
                                                           in: context))
                XCTAssertEqual(otherUser.oneToOneConversation, oneOnOneConversation)
                XCTAssertEqual(oneOnOneConversation.oneOnOneUser, otherUser)
            }
        }, for: self)
    }

    enum Scaffolding {
        static let domain = String.randomDomain()
        static let otherUserQualifiedID = QualifiedID.init(uuid: .create(), domain: Self.domain)
        static let oldOneOnOneConversationID = UUID(uuidString: "11118744-5514-45BB-A145-0B6F37856CDA")!
        static let newOneOnOneConversationID = UUID(uuidString: "87CF8744-5514-45BB-A145-0B6F37856CDA")!
    }
}
