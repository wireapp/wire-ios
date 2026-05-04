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

import WireAuthenticationAPI
import XCTest

@testable import WireAuthenticationLogic

final class ValidateEmailOrSSOCodeUseCaseTests: XCTestCase {

    private var sut: ValidateEmailOrSSOCodeUseCase!

    override func setUp() {
        sut = ValidateEmailOrSSOCodeUseCase()
    }

    override func tearDown() {
        sut = nil
    }

    func testInvoke_withValidEmail() throws {
        // given, when
        let result = try sut.invoke(input: "foo@example.com")

        // then
        XCTAssertEqual(result, .email(email: "foo@example.com", domain: "example.com"))
    }

    func testInvoke_withValidEmail_containingWhitespace() throws {
        // given, when
        let result = try sut.invoke(input: " foo@example.com\n\r")

        // then
        XCTAssertEqual(result, .email(email: "foo@example.com", domain: "example.com"))
    }

    func testInvoke_withValidSSOCode() throws {
        // given, when
        let result = try sut.invoke(input: "wire-648e79cb-88b9-42a8-8ea7-dd93e97f4da1")

        // then
        XCTAssertEqual(result, .ssoCode(UUID(uuidString: "648e79cb-88b9-42a8-8ea7-dd93e97f4da1")!))
    }

    func testInvoke_withValidSSOCode_containingWhitespace() throws {
        // given, when
        let result = try sut.invoke(input: "\nwire-648e79cb-88b9-42a8-8ea7-dd93e97f4da1\t")

        // then
        XCTAssertEqual(result, .ssoCode(UUID(uuidString: "648e79cb-88b9-42a8-8ea7-dd93e97f4da1")!))
    }

    func testInvoke_withInvalidInput() {
        // given, when, then
        XCTAssertThrowsError(try sut.invoke(input: "invalid-input")) { error in
            XCTAssertTrue(error is ValidatedEmailOrSSOCodeFailure)
        }
    }

}
