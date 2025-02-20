//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import XCTest

@testable import WireAuthenticationUI

class LoginViaSSOViewModelTests: XCTestCase {

    var sut: LoginViaSSOViewModel!

    override func setUp() {
        sut = LoginViaSSOViewModel()
    }

    override func tearDown() {
        sut = nil
    }

    func testItBuildsSSOLink() async throws {
        // Given
        let ssoCode = UUID()
        let userID = ssoCode

        // When
        let response = try await sut.buildSSOLink(
            baseURL: URL(string: "https://localhost")!,
            ssoCode: ssoCode,
            callbackScheme: "wire"
        )
        let ssoURL: String = response.absoluteString.removingPercentEncoding!
        let ssoCodeString = ssoCode.uuidString
        let successPart1 = "success_redirect=wire://login/success?"
        let successPart2 = "cookie=$cookie&userid=$userid&validation_token=\(ssoCodeString)"
        let success = successPart1 + successPart2
        let error = "error_redirect=wire://login/failure?label=$label&validation_token=\(ssoCodeString)"
        let expectedURL = URL(
            string: "https://localhost/sso/initiate-login/\(userID.uuidString)?\(success)&\(error)"
        )!

        // Then
        XCTAssertEqual(ssoURL, expectedURL.absoluteString)
    }

}
