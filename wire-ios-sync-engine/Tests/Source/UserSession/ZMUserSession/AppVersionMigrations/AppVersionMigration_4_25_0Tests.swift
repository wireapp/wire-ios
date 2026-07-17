//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import Testing
import WireDataModelSupport

@testable import WireSyncEngine

struct AppVersionMigration_4_25_0Tests {

    let coreDataHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()

    let stack: CoreDataStack
    let sut: AppVersionMigration_4_25_0

    init() async throws {
        self.stack = try await coreDataHelper.createStack()
        self.sut = AppVersionMigration_4_25_0(coreDataStack: stack)
    }

    @Test("Restores blocked 1:1 conversation that was marked as deleted remotely")
    func testRestoresBlockedOneOnOne() async throws {
        let context = stack.syncContext

        var conversation: ZMConversation?
        try await context.perform {
            modelHelper.createSelfUser(in: context)
            let otherUser = modelHelper.createUser(in: context)
            let (_, oneOnOne) = modelHelper.createConnection(
                status: .blocked,
                to: otherUser,
                in: context
            )
            oneOnOne.isDeletedRemotely = true
            conversation = oneOnOne
            try context.save()
        }

        // WHEN
        try await sut.perform()

        // THEN
        try await context.perform {
            let restored = try XCTUnwrap(conversation)
            XCTAssertFalse(restored.isDeletedRemotely)
        }
    }

    @Test("Does not restore accepted 1:1 conversation marked as deleted remotely")
    func testDoesNotRestoreAcceptedOneOnOne() async throws {
        let context = stack.syncContext

        var conversation: ZMConversation?
        try await context.perform {
            modelHelper.createSelfUser(in: context)
            let otherUser = modelHelper.createUser(in: context)
            let (_, oneOnOne) = modelHelper.createConnection(
                status: .accepted,
                to: otherUser,
                in: context
            )
            oneOnOne.isDeletedRemotely = true
            conversation = oneOnOne
            try context.save()
        }

        // WHEN
        try await sut.perform()

        // THEN
        try await context.perform {
            let untouched = try XCTUnwrap(conversation)
            XCTAssertTrue(untouched.isDeletedRemotely)
        }
    }

    @Test("Does not restore group conversation marked as deleted remotely")
    func testDoesNotRestoreGroup() async throws {
        let context = stack.syncContext

        var conversation: ZMConversation?
        try await context.perform {
            modelHelper.createSelfUser(in: context)
            let group = modelHelper.createGroupConversation(in: context)
            group.isDeletedRemotely = true
            conversation = group
            try context.save()
        }

        // WHEN
        try await sut.perform()

        // THEN
        try await context.perform {
            let untouched = try XCTUnwrap(conversation)
            XCTAssertTrue(untouched.isDeletedRemotely)
        }
    }

    @Test("Leaves visible blocked 1:1 unchanged")
    func testLeavesVisibleBlockedOneOnOneUnchanged() async throws {
        let context = stack.syncContext

        var conversation: ZMConversation?
        try await context.perform {
            modelHelper.createSelfUser(in: context)
            let otherUser = modelHelper.createUser(in: context)
            let (_, oneOnOne) = modelHelper.createConnection(
                status: .blocked,
                to: otherUser,
                in: context
            )
            conversation = oneOnOne
            try context.save()
        }

        // WHEN
        try await sut.perform()

        // THEN
        try await context.perform {
            let unchanged = try XCTUnwrap(conversation)
            XCTAssertFalse(unchanged.isDeletedRemotely)
        }
    }
}
