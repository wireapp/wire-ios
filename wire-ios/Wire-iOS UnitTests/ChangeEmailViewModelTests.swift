//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import WireSyncEngineSupport
import XCTest
@testable import Wire

final class ChangeEmailViewModelTests: XCTestCase {
    // MARK: Internal

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        mockUserProfile = MockUserProfile()
        sut = ChangeEmailViewModel(currentEmail: "current@example.com", userProfile: mockUserProfile)
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockUserProfile = nil
        super.tearDown()
    }

    // MARK: - Unit Tests

    func testRequestEmailUpdateWithInvalidEmail() {
        XCTAssertThrowsError(try sut.requestEmailUpdate()) { error in
            XCTAssertEqual(error as? ChangeEmailError, ChangeEmailError.invalidEmail)
        }
    }

    func testRequestEmailUpdateSuccess() {
        // GIVEN
        sut.updateNewEmail("new@example.com")
        mockUserProfile.requestEmailChangeEmail_MockMethod = { email in
            XCTAssertEqual(email, "new@example.com")
        }

        // WHEN & THEN
        XCTAssertNoThrow(try sut.requestEmailUpdate())
        XCTAssertEqual(mockUserProfile.requestEmailChangeEmail_Invocations, ["new@example.com"])
    }

    func testRequestEmailUpdateFailure() {
        // GIVEN
        sut.updateNewEmail("new@example.com")
        struct AnyError: Error {}
        mockUserProfile.requestEmailChangeEmail_MockError = AnyError()

        // WHEN & THEN
        XCTAssertThrowsError(try sut.requestEmailUpdate()) { error in
            XCTAssertTrue(error is AnyError)
        }
        XCTAssertEqual(mockUserProfile.requestEmailChangeEmail_Invocations, ["new@example.com"])
    }

    // MARK: Private

    // MARK: - Properties

    private var sut: ChangeEmailViewModel!
    private var mockUserProfile: MockUserProfile!
}
