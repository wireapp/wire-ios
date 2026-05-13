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

final class DigitalSignatureVerificationViewModelTests: XCTestCase {

    func testRouteForSuccessPostCode() throws {
        let sut = DigitalSignatureVerificationViewModel(url: try XCTUnwrap(URL(string: "https://wire.com")))
        let url = try XCTUnwrap(URL(string: "https://wire.com/callback?postCode=sas-success"))

        switch sut.route(for: url) {
        case .verificationSucceeded:
            break
        case .verificationFailed, .none:
            XCTFail("Expected success route")
        }
    }

    func testRouteForAuthenticationFailurePostCode() throws {
        let sut = DigitalSignatureVerificationViewModel(url: try XCTUnwrap(URL(string: "https://wire.com")))
        let url = try XCTUnwrap(URL(string: "https://wire.com/callback?postCode=sas-error-authentication-failed"))

        switch sut.route(for: url) {
        case let .verificationFailed(error):
            guard case .authenticationFailed = error else {
                XCTFail("Expected authentication failure")
                return
            }
        case .verificationSucceeded, .none:
            XCTFail("Expected authentication failure route")
        }
    }

    func testRouteForMissingPostCodeAllowsNavigation() throws {
        let sut = DigitalSignatureVerificationViewModel(url: try XCTUnwrap(URL(string: "https://wire.com")))
        let url = try XCTUnwrap(URL(string: "https://wire.com/callback"))

        switch sut.route(for: url) {
        case .none:
            break
        case .verificationSucceeded, .verificationFailed:
            XCTFail("Expected no route")
        }
    }
}
