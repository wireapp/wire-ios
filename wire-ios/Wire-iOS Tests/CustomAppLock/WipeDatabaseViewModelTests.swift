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

import XCTest

@testable import Wire

final class WipeDatabaseViewModelTests: XCTestCase {

    func testDisplayModel() {
        let sut = WipeDatabaseViewModel()

        XCTAssertEqual(sut.displayModel.title, L10n.Localizable.WipeDatabase.titleLabel)
        XCTAssertEqual(sut.displayModel.info, L10n.Localizable.WipeDatabase.infoLabel)
        XCTAssertEqual(sut.displayModel.highlightedInfo, L10n.Localizable.WipeDatabase.InfoLabel.highlighted)
        XCTAssertEqual(sut.displayModel.confirmButton.title, L10n.Localizable.WipeDatabase.Button.title)
        XCTAssertTrue(sut.displayModel.confirmButton.isEnabled)
    }

    func testConfirmationStateEnablesConfirmOnlyForExpectedInput() {
        let sut = WipeDatabaseViewModel()

        XCTAssertFalse(sut.confirmationState(for: "wrong").isConfirmEnabled)
        XCTAssertTrue(sut.confirmationState(for: L10n.Localizable.WipeDatabase.Alert.confirmInput).isConfirmEnabled)
    }

    func testRoutes() {
        let sut = WipeDatabaseViewModel()

        XCTAssertEqual(sut.route(for: .confirmTapped), .presentConfirmation)
        XCTAssertEqual(sut.route(for: .confirmationInputChanged(L10n.Localizable.WipeDatabase.Alert.confirmInput)), .none)
        XCTAssertEqual(sut.route(for: .confirmationSubmitted(nil)), .cancel)
        XCTAssertEqual(sut.route(for: .confirmationSubmitted("wrong")), .none)
        XCTAssertEqual(
            sut.route(for: .confirmationSubmitted(L10n.Localizable.WipeDatabase.Alert.confirmInput)),
            .wipeDatabase
        )
        XCTAssertEqual(sut.route(for: .confirmationCancelled), .cancel)
        XCTAssertEqual(sut.route(for: .confirmationFailed), .none)
    }

}
