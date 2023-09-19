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

import Foundation
@testable import WireDataModel
import XCTest

class ReactionsSortingTests: BaseZMMessageTests {
    func testThatReactionsAreSortedByDate() {
        // given
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let expectedOrder = ["🎃", "👾", "🤖", "👽"] // The emojis are sorted by dates of creation, newest emojis first [0x1F383, 0x1F47E, 0x1F916, 0x1F47D]
        // when
        message.setReactions(["👽"], forUser: selfUser, newReactionsCreationDate: Date(timeIntervalSince1970: .oneMinute))
        message.setReactions(["👽", "🤖"], forUser: selfUser, newReactionsCreationDate: Date(timeIntervalSince1970: .fiveMinutes))
        message.setReactions(["👽", "👾", "🤖"], forUser: selfUser, newReactionsCreationDate: Date(timeIntervalSince1970: .oneHour))
        message.setReactions(["👽", "🎃", "👾", "🤖"], forUser: selfUser, newReactionsCreationDate: Date(timeIntervalSince1970: .oneWeek))
        self.uiMOC.saveOrRollback()
        // then
        let result = message.reactionsSortedByCreationDate().map { $0.reactionString }
        XCTAssertEqual(result, expectedOrder)
    }

    func testThatIfMoreReactionsHaveSameDateTheyAreSortedByValue() {
        // given
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let expectedOrder = ["🎃", "👽", "👾", "🚀"] // The emojis are sorted by their string contents which takes unicode values into account: [0x1F383, 0x1F47D, 0x1F47E, 0x1F680]
        // when
        message.setReactions(["🚀", "👽", "🎃", "👾"], forUser: selfUser, newReactionsCreationDate: Date())
        self.uiMOC.saveOrRollback()
        // then
        let result = message.reactionsSortedByCreationDate().map { $0.reactionString }
        XCTAssertEqual(result, expectedOrder)
    }

    func testThatReactionsAreSortedFirstByDateThenByValue() {
        // given
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let expectedOrder = ["🎃", "🚀", "👽", "👾"] // The emojis are sorted by dates and then their string contents which takes unicode values into account: [0x1F383, 0x1F680, 0x1F47D, 0x1F47E]
        // when
        message.setReactions(["👾", "👽"], forUser: selfUser, newReactionsCreationDate: Date(timeIntervalSince1970: .oneSecond))
        message.setReactions(["👽", "🚀", "🎃", "👾"], forUser: selfUser, newReactionsCreationDate: Date(timeIntervalSince1970: .tenSeconds))
        self.uiMOC.saveOrRollback()
        // then
        let result = message.reactionsSortedByCreationDate().map { $0.reactionString }
        XCTAssertEqual(result, expectedOrder)
    }
}
