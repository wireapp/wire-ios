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

final class ProxyCredentialsViewModelTests: XCTestCase {

    private var sut: ProxyCredentialsViewModel!

    override func setUp() {
        super.setUp()
        sut = ProxyCredentialsViewModel(backendURL: URL(string: "https://proxy.example.com")!)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testInitialDisplayStateDisablesSubmit() {
        XCTAssertEqual(sut.displayState.username, "")
        XCTAssertEqual(sut.displayState.password, "")
        XCTAssertFalse(sut.displayState.isSubmitButtonEnabled)
    }

    func testUpdateCredentialsEnablesSubmitWhenBothFieldsArePresent() {
        sut.update(.username, text: "proxy-user")
        let displayState = sut.update(.password, text: "proxy-password")

        XCTAssertEqual(displayState.username, "proxy-user")
        XCTAssertEqual(displayState.password, "proxy-password")
        XCTAssertTrue(displayState.isSubmitButtonEnabled)
    }

    func testSubmitWithValidCredentialsReturnsSubmitActionAndRoute() {
        sut.update(.username, text: "proxy-user")
        sut.update(.password, text: "proxy-password")

        let credentials = ProxyCredentialsViewModel.Credentials(
            username: "proxy-user",
            password: "proxy-password"
        )

        XCTAssertEqual(sut.submitButtonTapped(), .submit(credentials))
        XCTAssertEqual(sut.routeForSubmit(), .submit(credentials))
    }

    func testSubmitWithoutPasswordReturnsMissingPasswordError() {
        sut.update(.username, text: "proxy-user")

        XCTAssertEqual(sut.submitButtonTapped(), .showError(.missingPassword))
        XCTAssertNil(sut.routeForSubmit())
    }

    func testCancelReturnsCancelActionAndRoute() {
        XCTAssertEqual(sut.cancelButtonTapped(), .cancel)
        XCTAssertEqual(sut.routeForCancel(), .cancel)
    }
}
