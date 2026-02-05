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

final class ValidateSSOCodeUseCaseTests: XCTestCase {

    private var sut: ValidateSSOCodeUseCase!

    override func setUp() {
        sut = ValidateSSOCodeUseCase()
    }

    override func tearDown() {
        sut = nil
    }

    // MARK: - Valid SSO Codes

    func testInvoke_withValidSSOCode_lowercase() throws {
        // given
        let uuidString = "648e79cb-88b9-42a8-8ea7-dd93e97f4da1"
        let ssoCode = "wire-\(uuidString)"
        let expectedUUID = UUID(uuidString: uuidString)!

        // when
        let result = try sut.invoke(ssoCode: ssoCode)

        // then
        XCTAssertEqual(result, expectedUUID)
    }

    func testInvoke_withValidSSOCode_uppercase() throws {
        // given
        let uuidString = "648e79cb-88b9-42a8-8ea7-dd93e97f4da1"
        let ssoCode = "WIRE-\(uuidString.uppercased())"
        let expectedUUID = UUID(uuidString: uuidString)!

        // when
        let result = try sut.invoke(ssoCode: ssoCode)

        // then
        XCTAssertEqual(result, expectedUUID)
    }

    // MARK: - Valid SSO Codes with Whitespace

    func testInvoke_withValidSSOCode_containingLeadingWhitespace() throws {
        // given
        let uuidString = "648e79cb-88b9-42a8-8ea7-dd93e97f4da1"
        let ssoCode = " wire-\(uuidString)"
        let expectedUUID = UUID(uuidString: uuidString)!

        // when
        let result = try sut.invoke(ssoCode: ssoCode)

        // then
        XCTAssertEqual(result, expectedUUID)
    }

    func testInvoke_withValidSSOCode_containingTrailingWhitespace() throws {
        // given
        let uuidString = "648e79cb-88b9-42a8-8ea7-dd93e97f4da1"
        let ssoCode = "wire-\(uuidString) "
        let expectedUUID = UUID(uuidString: uuidString)!

        // when
        let result = try sut.invoke(ssoCode: ssoCode)

        // then
        XCTAssertEqual(result, expectedUUID)
    }

    func testInvoke_withValidSSOCode_containingLeadingAndTrailingWhitespace() throws {
        // given
        let uuidString = "648e79cb-88b9-42a8-8ea7-dd93e97f4da1"
        let ssoCode = "  wire-\(uuidString)  "
        let expectedUUID = UUID(uuidString: uuidString)!

        // when
        let result = try sut.invoke(ssoCode: ssoCode)

        // then
        XCTAssertEqual(result, expectedUUID)
    }

    func testInvoke_withValidSSOCode_containingNewlines() throws {
        // given
        let uuidString = "648e79cb-88b9-42a8-8ea7-dd93e97f4da1"
        let ssoCode = "\nwire-\(uuidString)\n"
        let expectedUUID = UUID(uuidString: uuidString)!

        // when
        let result = try sut.invoke(ssoCode: ssoCode)

        // then
        XCTAssertEqual(result, expectedUUID)
    }

    func testInvoke_withValidSSOCode_containingTabs() throws {
        // given
        let uuidString = "648e79cb-88b9-42a8-8ea7-dd93e97f4da1"
        let ssoCode = "\twire-\(uuidString)\t"
        let expectedUUID = UUID(uuidString: uuidString)!

        // when
        let result = try sut.invoke(ssoCode: ssoCode)

        // then
        XCTAssertEqual(result, expectedUUID)
    }

    func testInvoke_withValidSSOCode_containingMixedWhitespace() throws {
        // given
        let uuidString = "648e79cb-88b9-42a8-8ea7-dd93e97f4da1"
        let ssoCode = " \n\t wire-\(uuidString) \r\n\t "
        let expectedUUID = UUID(uuidString: uuidString)!

        // when
        let result = try sut.invoke(ssoCode: ssoCode)

        // then
        XCTAssertEqual(result, expectedUUID)
    }

    // MARK: - Invalid SSO Codes

    func testInvoke_withInvalidCode_missingPrefix() {
        // given
        let ssoCode = "648e79cb-88b9-42a8-8ea7-dd93e97f4da1"

        // when, then
        XCTAssertThrowsError(try sut.invoke(ssoCode: ssoCode)) { error in
            XCTAssertTrue(error is ValidateSSOCodeFailure)
            XCTAssertEqual(error as? ValidateSSOCodeFailure, .invalidCode)
        }
    }

    func testInvoke_withInvalidCode_wrongPrefix() {
        // given
        let ssoCode = "fire-648e79cb-88b9-42a8-8ea7-dd93e97f4da1"

        // when, then
        XCTAssertThrowsError(try sut.invoke(ssoCode: ssoCode)) { error in
            XCTAssertTrue(error is ValidateSSOCodeFailure)
            XCTAssertEqual(error as? ValidateSSOCodeFailure, .invalidCode)
        }
    }

    func testInvoke_withInvalidCode_invalidUUIDFormat() {
        // given
        let ssoCode = "wire-invalid-uuid-format"

        // when, then
        XCTAssertThrowsError(try sut.invoke(ssoCode: ssoCode)) { error in
            XCTAssertTrue(error is ValidateSSOCodeFailure)
            XCTAssertEqual(error as? ValidateSSOCodeFailure, .invalidCode)
        }
    }

    func testInvoke_withInvalidCode_tooShortUUID() {
        // given
        let ssoCode = "wire-648e79cb-88b9-42a8-8ea7-dd93e97f4da"

        // when, then
        XCTAssertThrowsError(try sut.invoke(ssoCode: ssoCode)) { error in
            XCTAssertTrue(error is ValidateSSOCodeFailure)
            XCTAssertEqual(error as? ValidateSSOCodeFailure, .invalidCode)
        }
    }

    func testInvoke_withInvalidCode_tooLongUUID() {
        // given
        let ssoCode = "wire-648e79cb-88b9-42a8-8ea7-dd93e97f4da12"

        // when, then
        XCTAssertThrowsError(try sut.invoke(ssoCode: ssoCode)) { error in
            XCTAssertTrue(error is ValidateSSOCodeFailure)
            XCTAssertEqual(error as? ValidateSSOCodeFailure, .invalidCode)
        }
    }

    func testInvoke_withInvalidCode_emptyString() {
        // given
        let ssoCode = ""

        // when, then
        XCTAssertThrowsError(try sut.invoke(ssoCode: ssoCode)) { error in
            XCTAssertTrue(error is ValidateSSOCodeFailure)
            XCTAssertEqual(error as? ValidateSSOCodeFailure, .invalidCode)
        }
    }

    func testInvoke_withInvalidCode_onlyWhitespace() {
        // given
        let ssoCode = "   \n\t  "

        // when, then
        XCTAssertThrowsError(try sut.invoke(ssoCode: ssoCode)) { error in
            XCTAssertTrue(error is ValidateSSOCodeFailure)
            XCTAssertEqual(error as? ValidateSSOCodeFailure, .invalidCode)
        }
    }

    func testInvoke_withInvalidCode_onlyPrefix() {
        // given
        let ssoCode = "wire-"

        // when, then
        XCTAssertThrowsError(try sut.invoke(ssoCode: ssoCode)) { error in
            XCTAssertTrue(error is ValidateSSOCodeFailure)
            XCTAssertEqual(error as? ValidateSSOCodeFailure, .invalidCode)
        }
    }

    func testInvoke_withInvalidCode_whitespaceWithPrefix() {
        // given
        let ssoCode = " wire- "

        // when, then
        XCTAssertThrowsError(try sut.invoke(ssoCode: ssoCode)) { error in
            XCTAssertTrue(error is ValidateSSOCodeFailure)
            XCTAssertEqual(error as? ValidateSSOCodeFailure, .invalidCode)
        }
    }
}
