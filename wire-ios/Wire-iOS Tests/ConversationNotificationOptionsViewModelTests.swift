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

import WireDataModel
import XCTest

@testable import Wire

final class ConversationNotificationOptionsViewModelTests: XCTestCase {

    func testStateMapsNotificationOptionsInExpectedOrder() {
        let sut = ConversationNotificationOptionsViewModel(currentSelection: .regular)

        XCTAssertEqual(sut.state.options.map(\.value), [.none, .regular, .all])
        XCTAssertEqual(
            sut.state.options.map(\.title),
            [
                L10n.Localizable.Meta.Menu.ConfigureNotification.buttonEverything,
                L10n.Localizable.Meta.Menu.ConfigureNotification.buttonMentionsAndReplies,
                L10n.Localizable.Meta.Menu.ConfigureNotification.buttonNothing
            ]
        )
        XCTAssertEqual(sut.state.options.map(\.isSelected), [false, true, false])
    }

    func testActionForSelectionReturnsNoneWhenSelectingCurrentOption() {
        let sut = ConversationNotificationOptionsViewModel(currentSelection: .regular)

        XCTAssertEqual(sut.actionForSelection(at: 1), .none)
    }

    func testActionForSelectionReturnsUpdateWhenSelectingDifferentOption() {
        let sut = ConversationNotificationOptionsViewModel(currentSelection: .regular)

        XCTAssertEqual(sut.actionForSelection(at: 2), .update(.all))
    }

    func testUpdateCurrentSelectionRefreshesState() {
        let sut = ConversationNotificationOptionsViewModel(currentSelection: .regular)

        sut.updateCurrentSelection(.all)

        XCTAssertEqual(sut.state.options.map(\.isSelected), [false, false, true])
    }
}
