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
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let expectedOrder = ["🎃", "🤖", "👾", "👽"]
        message.setReactions(["👽"], forUser: selfUser, newReactionsCreationDate: Date())
        message.setReactions(["👽", "👾"], forUser: selfUser, newReactionsCreationDate: Date())
        message.setReactions(["👽", "👾", "🤖"], forUser: selfUser, newReactionsCreationDate: Date())
        message.setReactions(["🎃", "👽", "👾", "🤖"], forUser: selfUser, newReactionsCreationDate: Date())
        self.uiMOC.saveOrRollback()
        let result = message.reactionsSortedByCreationDate().map { $0.reactionString }
        XCTAssertEqual(result, expectedOrder)
    }

    func testThatIfMoreReactionsHaveSameDateTheyAreSortedByValue() {
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let expectedOrder = ["🤖", "😍", "👾", "👽", "🎃"]
        message.setReactions(["🎃", "👽", "👾", "🤖", "😍"], forUser: selfUser, newReactionsCreationDate: Date())
        self.uiMOC.saveOrRollback()
        let result = message.reactionsSortedByCreationDate().map { $0.reactionString }
        XCTAssertEqual(result, expectedOrder)
    }

    func testThatReactionsAreSortedFirstByDateThenByValue() {
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let expectedOrder = ["🤖", "🎃", "👾", "👽"]
        message.setReactions(["👾", "👽"], forUser: selfUser, newReactionsCreationDate: Date())
        message.setReactions(["🎃", "👽", "👾", "🤖"], forUser: selfUser, newReactionsCreationDate: Date())
        self.uiMOC.saveOrRollback()
        let result = message.reactionsSortedByCreationDate().map { $0.reactionString }
        XCTAssertEqual(result, expectedOrder)
    }
}
