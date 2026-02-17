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

import WireDataModelSupport
import XCTest
@testable import WireDataModel

final class ZMConversationTests_SystemMessage: XCTestCase {

    func test_appendMLSMigrationFinalizedSystemMessageIfNeeded_doesNotInsertTwice() async throws {
        let modelHelper = ModelHelper()
        let coreDataStack = try await CoreDataStackHelper().createStack()

        await coreDataStack.syncContext.perform {
            // GIVEN
            let conversation = modelHelper.createGroupConversation(in: coreDataStack.syncContext)
            let user = modelHelper.createUser(qualifiedID: .random(), in: coreDataStack.syncContext)

            XCTAssertEqual(conversation.allMessages.count, 0)

            // WHEN
            conversation.appendMLSMigrationFinalizedSystemMessageIfNeeded(sender: user, at: .now)
            XCTAssertEqual(conversation.allMessages.count, 1)

            // THEN

            conversation.appendMLSMigrationFinalizedSystemMessageIfNeeded(sender: user, at: .now)
            XCTAssertEqual(conversation.allMessages.count, 1)

        }

    }
}
