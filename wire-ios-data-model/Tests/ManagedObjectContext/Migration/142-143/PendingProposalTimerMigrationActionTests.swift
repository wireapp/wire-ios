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

final class PendingProposalTimerMigrationActionTests: XCTestCase {

    func testLegacyPendingDateIsMovedToTimer() async throws {
        // Given
        let stack = try await CoreDataStackHelper().createStack(inMemoryStore: true)
        let context = stack.syncContext
        let groupID = MLSGroupID(Data([1, 2, 3]))
        let conversationID = UUID()
        let date = Date(timeIntervalSinceNow: 3600)

        try await context.perform {
            let conversation = ZMConversation.insertNewObject(in: context)
            conversation.remoteIdentifier = conversationID
            conversation.domain = "wire.com"
            conversation.mlsGroupID = groupID
            conversation.commitPendingProposalDate = date
            try context.save()

            // When
            try PendingProposalTimerMigrationAction().execute(in: context)

            // Then
            let timers = try context.fetch(PendingProposalTimer.fetchRequest())
            XCTAssertEqual(timers.count, 1)
            XCTAssertEqual(timers.first?.mlsGroupID, groupID.data)
            XCTAssertEqual(timers.first?.conversationID, conversationID)
            XCTAssertEqual(timers.first?.conversationDomain, "wire.com")
            XCTAssertEqual(timers.first?.fireDate, date)
            XCTAssertNil(conversation.commitPendingProposalDate)
        }
    }
}
