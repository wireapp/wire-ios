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

@testable import WireAuthenticationLogic

final class SSOCodeValidatorTests: XCTestCase {

    func testValidate_withValidSSOCodes() {
        // given
        let testCases: [String] = [
            "WIRE-648E79CB-88B9-42A8-8EA7-DD93E97F4DA1",
            "wire-648e79cb-88b9-42a8-8ea7-dd93e97f4da1"
        ]

        for ssoCode in testCases {
            // when, then
            XCTAssertNotNil(SSOCodeValidator.validate(ssoCode: ssoCode), "ssoCode \(ssoCode) should be valid")
        }
    }

    func testValidate_withValidInvalidSSOCodes() {
        // given
        let testCases: [String] = [
            " wire-648e79cb-88b9-42a8-8ea7-dd93e97f4da1 ",
            "wire-648e79cb-88b9-42a8-8ea7-dd93e97f4da",
            "wire-648e79cb-88b9-42a8-8ea7-dd93e97f4da12",
            "fire-648e79cb-88b9-42a8-8ea7-dd93e97f4da1"
        ]

        for ssoCode in testCases {
            // when, then
            XCTAssertNil(SSOCodeValidator.validate(ssoCode: ssoCode), "ssoCode \(ssoCode) should be valid")
        }
    }
}
