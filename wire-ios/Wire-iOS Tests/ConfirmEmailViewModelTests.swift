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

final class ConfirmEmailViewModelTests: XCTestCase {

    func testDisplayStateUsesNewEmail() {
        // GIVEN
        let sut = ConfirmEmailViewModel(newEmail: "bill@wire.com")

        // WHEN
        let displayState = sut.displayState

        // THEN
        XCTAssertEqual(displayState.title, ConfirmEmailViewModel.Localizable.Verify.title)
        XCTAssertEqual(displayState.description, ConfirmEmailViewModel.Localizable.Verify.description)
        XCTAssertEqual(
            displayState.resendButtonTitle,
            ConfirmEmailViewModel.Localizable.Verify.resend("bill@wire.com")
        )
    }

    func testResendButtonActionReturnsConfirmationDisplayModel() {
        // GIVEN
        let sut = ConfirmEmailViewModel(newEmail: "bill@wire.com")

        // WHEN
        let action = sut.resendButtonTapped()

        // THEN
        XCTAssertEqual(
            action,
            .resendVerification(
                .init(
                    title: ConfirmEmailViewModel.Localizable.Resend.title,
                    message: ConfirmEmailViewModel.Localizable.Resend.message("bill@wire.com"),
                    buttonTitle: L10n.Localizable.General.ok
                )
            )
        )
    }

    func testRouteForObservedEmailChangeReturnsConfirmedEmailForSelfUserWithExpectedEmail() {
        // GIVEN
        let sut = ConfirmEmailViewModel(newEmail: "bill@wire.com")

        // WHEN
        let route = sut.routeForObservedEmailChange(
            isSelfUser: true,
            currentEmail: "bill@wire.com"
        )

        // THEN
        XCTAssertEqual(route, .confirmedEmail)
    }

    func testRouteForObservedEmailChangeReturnsNilForDifferentEmail() {
        // GIVEN
        let sut = ConfirmEmailViewModel(newEmail: "bill@wire.com")

        // WHEN
        let route = sut.routeForObservedEmailChange(
            isSelfUser: true,
            currentEmail: "alice@wire.com"
        )

        // THEN
        XCTAssertNil(route)
    }

    func testRouteForObservedEmailChangeReturnsNilForOtherUser() {
        // GIVEN
        let sut = ConfirmEmailViewModel(newEmail: "bill@wire.com")

        // WHEN
        let route = sut.routeForObservedEmailChange(
            isSelfUser: false,
            currentEmail: "bill@wire.com"
        )

        // THEN
        XCTAssertNil(route)
    }
}
