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

import WireTransport
import XCTest

@testable import Wire

final class LandingViewModelTests: XCTestCase {

    private var sut: LandingViewModel!

    override func setUp() {
        super.setUp()
        sut = LandingViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testDisplayStateForDefaultBackend() {
        // When
        let state = sut.displayState(
            environmentType: .default,
            allowsDirectCompanyLogin: true,
            customBackendEnabled: true
        )

        // Then
        XCTAssertEqual(state.loginButtonTitle, L10n.Localizable.Landing.Login.Button.title)
        XCTAssertEqual(state.loginWithEmailButtonTitle, L10n.Localizable.Landing.Login.Email.Button.title)
        XCTAssertEqual(state.createAccountButtonTitle, L10n.Localizable.Landing.CreateAccount.title)
        XCTAssertTrue(state.showsEnterpriseLogin)
        XCTAssertNil(state.customBackendURL)
        XCTAssertFalse(state.usesCustomBackendLayout)
    }

    func testDisplayStateForCustomBackendWhenCustomBackendIsEnabled() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://api.example.org"))

        // When
        let state = sut.displayState(
            environmentType: .custom(url: url),
            allowsDirectCompanyLogin: false,
            customBackendEnabled: true
        )

        // Then
        XCTAssertFalse(state.showsEnterpriseLogin)
        XCTAssertEqual(state.customBackendURL, url)
        XCTAssertTrue(state.usesCustomBackendLayout)
    }

    func testDisplayStateForCustomBackendWhenCustomBackendIsDisabled() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://api.example.org"))

        // When
        let state = sut.displayState(
            environmentType: .custom(url: url),
            allowsDirectCompanyLogin: false,
            customBackendEnabled: false
        )

        // Then
        XCTAssertNil(state.customBackendURL)
        XCTAssertTrue(state.usesCustomBackendLayout)
    }

    func testRoutesForActions() {
        XCTAssertEqual(sut.routeForCreateAccountTapped(), .createAccount)
        XCTAssertEqual(sut.routeForLoginTapped(), .login)
        XCTAssertEqual(sut.routeForEnterpriseLoginTapped(), .enterpriseLogin)
        XCTAssertEqual(sut.routeForCustomBackendInfoTapped(), .customBackendInfo)
        XCTAssertEqual(sut.routeForCancelTapped(), .cancel)
    }
}
