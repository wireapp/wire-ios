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

final class GiphyConfirmationViewModelTests: XCTestCase {

    func testInitialDisplayStateDisablesConfirmAndProvidesButtonTexts() {
        let sut = GiphyConfirmationViewModel(canFetchImage: true)

        XCTAssertNil(sut.displayState.previewImageData)
        XCTAssertEqual(sut.displayState.confirmButton.title, L10n.Localizable.Giphy.confirm.capitalized)
        XCTAssertFalse(sut.displayState.confirmButton.isEnabled)
        XCTAssertEqual(sut.displayState.cancelButton.title, L10n.Localizable.Giphy.cancel.capitalized)
        XCTAssertTrue(sut.displayState.cancelButton.isEnabled)
        XCTAssertEqual(sut.displayState.closeAccessibilityLabel, L10n.Localizable.General.close)
    }

    func testOpenRequestsImageFetchOnlyWhenDependenciesAreAvailable() {
        var sutWithFetch = GiphyConfirmationViewModel(canFetchImage: true)
        var sutWithoutFetch = GiphyConfirmationViewModel(canFetchImage: false)

        XCTAssertEqual(sutWithFetch.effect(for: .open), .fetchImage)
        XCTAssertEqual(sutWithoutFetch.effect(for: .open), .none)
    }

    func testImageFetchSuccessStoresDataAndEnablesConfirm() {
        let imageData = Data([1, 2, 3])
        var sut = GiphyConfirmationViewModel(canFetchImage: true)

        XCTAssertEqual(sut.effect(for: .imageFetchSucceeded(imageData)), .none)

        XCTAssertEqual(sut.displayState.previewImageData, imageData)
        XCTAssertTrue(sut.displayState.confirmButton.isEnabled)
        XCTAssertEqual(sut.route(for: .confirmTapped), .confirm(imageData))
    }

    func testRoutesForActions() {
        var sut = GiphyConfirmationViewModel(canFetchImage: true)

        XCTAssertEqual(sut.route(for: .confirmTapped), .none)
        XCTAssertEqual(sut.route(for: .cancelTapped), .pop)
        XCTAssertEqual(sut.route(for: .closeTapped), .dismiss)
        XCTAssertEqual(sut.route(for: .open), .none)
        XCTAssertEqual(sut.route(for: .imageFetchFailed), .none)

        let imageData = Data([4, 5, 6])
        _ = sut.effect(for: .imageFetchSucceeded(imageData))

        XCTAssertEqual(sut.route(for: .confirmTapped), .confirm(imageData))
    }

}
