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

    // MARK: - Properties

    private var sut: ChangeEmailViewModel!
    private var mockUserProfile: MockUserProfile!

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
        // GIVEN
        let expectation = self.expectation(description: "Email update completion")

        // WHEN && THEN
        sut.requestEmailUpdate { result in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error as? ChangeEmailError, ChangeEmailError.invalidEmail)
            case .success:
                XCTFail("Expected failure, but got success")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRequestEmailUpdateSuccess() {
        // GIVEN
        sut.updateNewEmail("new@example.com")

        mockUserProfile.requestEmailChangeEmail_MockMethod = { email in
            XCTAssertEqual(email, "new@example.com")
        }

        let expectation = self.expectation(description: "Email update completion")

        // WHEN
        sut.requestEmailUpdate { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTFail("Expected success, but got failure")
            }
            expectation.fulfill()
        }

        // THEN
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(mockUserProfile.requestEmailChangeEmail_Invocations, ["new@example.com"])
    }

    func testRequestEmailUpdateFailure() {
        // GIVEN
        sut.updateNewEmail("new@example.com")

        // Setup the mock to throw any error
        struct AnyError: Error {}
        mockUserProfile.requestEmailChangeEmail_MockError = AnyError()

        let expectation = self.expectation(description: "Email update completion")
        // WHEN
        sut.requestEmailUpdate { result in
            switch result {
            case .success:
                XCTFail("Expected failure, but got success")
            case .failure:
                // We're just checking that an error was propagated, not its specific type
                XCTAssertTrue(true, "Received expected error")
            }
            expectation.fulfill()
        }

        // THEN
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(mockUserProfile.requestEmailChangeEmail_Invocations, ["new@example.com"])
    }
}
