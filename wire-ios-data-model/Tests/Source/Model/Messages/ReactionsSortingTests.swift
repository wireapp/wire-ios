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

class ReactionsSortingTests: BaseZMMessageTests {
    func testThatReactionsAreSortedByDate() {
        // given
        let user1 = ZMUser(context: uiMOC)
        user1.remoteIdentifier = UUID()
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let expectedOrder = [
            "👽",
            "🤖",
            "🎃",
            "👾",
        ] // The emojis are sorted by dates of creation, newest emojis first [0x1F383, 0x1F47E, 0x1F916, 0x1F47D]
        // when
        message.setReactions(
            ["👽"],
            forUser: selfUser,
            newReactionsCreationDate: Date(timeIntervalSince1970: .oneMinute)
        )
        message.setReactions(
            ["👽", "🤖"],
            forUser: selfUser,
            newReactionsCreationDate: Date(timeIntervalSince1970: .fiveMinutes)
        )
        // Since all of the emojis were added by the same user each one of them will have different creation date
        // (corresponding to first occurrence)
        message.setReactions(
            ["👽", "🤖", "👾"],
            forUser: selfUser,
            newReactionsCreationDate: Date(timeIntervalSince1970: .oneHour)
        )
        message.setReactions(
            ["🎃"],
            forUser: user1,
            newReactionsCreationDate: Date(timeIntervalSince1970: .fiveMinutes).addingTimeInterval(.tenSeconds)
        )
        self.uiMOC.saveOrRollback()
        // then
        let result = message.reactionsSortedByCreationDate().map(\.reactionString)
        XCTAssertEqual(result, expectedOrder)
    }
}
