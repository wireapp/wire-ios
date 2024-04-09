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

class DatabaseMigrationTests_IsPendingInitialFetch: XCTestCase {

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

    func testMigratingToMessagingStore_from2_115_resetsIsPendingInitialFetch() throws {
        let conversation1ID = UUID.create()
        let conversation2ID = UUID.create()

        try helper.migrateStoreToCurrentVersion(
            sourceVersion: "2.115.0",
            preMigrationAction: { context in
                _ = createConversation(id: conversation1ID, in: context)
                _ = createConversation(id: conversation2ID, in: context)

                try context.save()
            },
            postMigrationAction: { context in
                try context.performGroupedAndWait { context in
                    let conversation1 = try XCTUnwrap(ZMConversation.fetch(with: conversation1ID, in: context))
                    let conversation2 = try XCTUnwrap(ZMConversation.fetch(with: conversation2ID, in: context))
                    XCTAssertFalse(conversation1.isPendingInitialFetch)
                    XCTAssertFalse(conversation2.isPendingInitialFetch)
                }
            },
            for: self)
    }

    private func createConversation(
        id: UUID,
        in context: NSManagedObjectContext
    ) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.remoteIdentifier = id
        return conversation
    }

}
