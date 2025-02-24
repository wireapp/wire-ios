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

import WireAPI
import WireAPISupport
import WireAuthenticationAPI
import XCTest

@testable import WireAuthenticationLogic

class SSOLinkGeneratorTests: XCTestCase {

    private var mockAuthenticationAPI: MockAuthenticationAPI!
    private var sut: SSOLinkGenerator!
    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: name)
        mockAuthenticationAPI = MockAuthenticationAPI()
        sut = SSOLinkGenerator(
            authenticationAPI: mockAuthenticationAPI,
            baseURL: URL(string: "https://localhost")!,
            callbackScheme: "wire",
            defaults: defaults
        )
    }

    override func tearDown() {
        defaults = nil
        mockAuthenticationAPI = nil
        sut = nil
    }

    @MainActor
    func testItBuildsSSOLink() async throws {
        // Given
        let ssoCode = UUID()
        let userID = ssoCode

        // When
        let response = try await sut.buildSSOLink(ssoCode: ssoCode)

        guard let validationToken = SSOLoginVerificationToken.current(in: defaults) else {
            return XCTFail("no token")
        }
        let ssoURL: String = response.absoluteString.removingPercentEncoding!
        let ssoCodeString = validationToken.uuid.uuidString.lowercased()
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
