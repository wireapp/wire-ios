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

import Foundation
import Testing
import WireAuthenticationAPI

@testable import WireAuthenticationLogic

@Suite
struct ValidateSSOCodeUseCaseTests {

    let sut: ValidateSSOCodeUseCase
    let testUUIDString = "648e79cb-88b9-42a8-8ea7-dd93e97f4da1"

    init() {
        sut = ValidateSSOCodeUseCase()
    }

    // MARK: - Valid SSO Codes

    @Test(
        "Valid SSO codes with different cases",
        arguments: [
            ("wire-648e79cb-88b9-42a8-8ea7-dd93e97f4da1", "lowercase"),
            ("WIRE-648E79CB-88B9-42A8-8EA7-DD93E97F4DA1", "uppercase"),
            ("Wire-648E79CB-88b9-42a8-8ea7-DD93E97F4DA1", "mixedCase")
        ]
    )
    func validSSOCodes(ssoCode: String, caseName: String) throws {
        // when
        let result = try sut.invoke(ssoCode: ssoCode)

        // then
        let expectedUUID = UUID(uuidString: testUUIDString)!
        #expect(result == expectedUUID)
    }

    // MARK: - Valid SSO Codes with Whitespace

    @Test(
        "Valid SSO codes with various whitespace",
        arguments: [
            (" ", " ", "leading and trailing spaces"),
            ("  ", "  ", "multiple leading and trailing spaces"),
            ("\n", "\n", "newlines"),
            ("\t", "\t", "tabs"),
            (" \n\t ", " \r\n\t ", "mixed whitespace")
        ]
    )
    func validSSOCodesWithWhitespace(leading: String, trailing: String, description: String) throws {
        // given
        let ssoCode = "\(leading)wire-\(testUUIDString)\(trailing)"

        // when
        let result = try sut.invoke(ssoCode: ssoCode)

        // then
        let expectedUUID = UUID(uuidString: testUUIDString)!
        #expect(result == expectedUUID)
    }

    // MARK: - Invalid SSO Codes

    @Test(
        "Invalid SSO codes throw error",
        arguments: [
            ("648e79cb-88b9-42a8-8ea7-dd93e97f4da1", "missing prefix"),
            ("fire-648e79cb-88b9-42a8-8ea7-dd93e97f4da1", "wrong prefix"),
            ("wire-invalid-uuid-format", "invalid UUID format"),
            ("wire-648e79cb-88b9-42a8-8ea7-dd93e97f4da", "too short UUID"),
            ("wire-648e79cb-88b9-42a8-8ea7-dd93e97f4da12", "too long UUID"),
            ("", "empty string"),
            ("   \n\t  ", "only whitespace"),
            ("wire-", "only prefix"),
            (" wire- ", "whitespace with prefix")
        ]
    )
    func invalidSSOCodes(ssoCode: String, description: String) throws {
        // when/then
        #expect(throws: ValidateSSOCodeFailure.self) {
            try sut.invoke(ssoCode: ssoCode)
        }
    }

    // MARK: - Specific Edge Cases

    @Test("Valid SSO code with only leading whitespace")
    func validSSOCodeWithLeadingWhitespace() throws {
        // given
        let ssoCode = " wire-\(testUUIDString)"

        // when
        let result = try sut.invoke(ssoCode: ssoCode)

        // then
        let expectedUUID = UUID(uuidString: testUUIDString)!
        #expect(result == expectedUUID)
    }

    @Test("Valid SSO code with only trailing whitespace")
    func validSSOCodeWithTrailingWhitespace() throws {
        // given
        let ssoCode = "wire-\(testUUIDString) "

        // when
        let result = try sut.invoke(ssoCode: ssoCode)

        // then
        let expectedUUID = UUID(uuidString: testUUIDString)!
        #expect(result == expectedUUID)
    }
}
