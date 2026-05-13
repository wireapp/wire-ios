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

import UIKit
import WireDataModel
import XCTest

@testable import Wire

final class TopPeopleLineViewModelTests: XCTestCase {

    func testNumberOfItemsReflectsTopPeopleCount() {
        let sut = TopPeopleLineViewModel(topPeople: [ZMConversation(), ZMConversation()])

        XCTAssertEqual(sut.numberOfItems, 2)
    }

    func testConversationAtIndexPathMapsWithModulo() {
        let firstConversation = ZMConversation()
        let secondConversation = ZMConversation()
        let sut = TopPeopleLineViewModel(topPeople: [firstConversation, secondConversation])

        XCTAssertTrue(sut.conversation(at: IndexPath(item: 2, section: 0)) === firstConversation)
    }

    func testConversationAtIndexPathReturnsNilForEmptyTopPeople() {
        let sut = TopPeopleLineViewModel()

        XCTAssertNil(sut.conversation(at: IndexPath(item: 0, section: 0)))
    }

    func testActionForSelectionReturnsSelectConversation() {
        let conversation = ZMConversation()
        let sut = TopPeopleLineViewModel(topPeople: [conversation])

        guard case let .selectConversation(selectedConversation) = sut.actionForSelection(
            at: IndexPath(item: 0, section: 0)
        ) else {
            return XCTFail("Expected select conversation action")
        }

        XCTAssertTrue(selectedConversation === conversation)
    }

    func testDefaultLayoutMatchesTopPeopleLineLayout() {
        let sut = TopPeopleLineViewModel()

        XCTAssertEqual(sut.layout.sectionInsets, UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 0))
        XCTAssertEqual(sut.layout.itemSize, CGSize(width: 56, height: 78))
        XCTAssertEqual(sut.layout.minimumInteritemSpacing, 12)
    }
}
