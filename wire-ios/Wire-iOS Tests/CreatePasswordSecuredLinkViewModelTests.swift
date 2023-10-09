//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

class CreatePasswordSecuredLinkViewModelTests: XCTestCase {

    // MARK: - Properties

    var viewModel: CreateSecureGuestLinkViewModel!
    var mockDelegate: MockCreatePasswordSecuredLinkViewModelDelegate!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        viewModel = CreateSecureGuestLinkViewModel()
        mockDelegate = MockCreatePasswordSecuredLinkViewModelDelegate()
        viewModel.delegate = mockDelegate
    }

    // MARK: - tearDown

    override func tearDown() {
        viewModel = nil
        mockDelegate = nil
        super.tearDown()
    }

    // MARK: - Unit Tests

    func testGenerateRandomPassword() {
        // GIVEN && WHEN
        let randomPassword = viewModel.generateRandomPassword()

        // THEN
        XCTAssertEqual(randomPassword.count, 8)
        XCTAssertTrue(randomPassword.contains { "abcdefghijklmnopqrstuvwxyz".contains($0) })
        XCTAssertTrue(randomPassword.contains { "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains($0) })
        XCTAssertTrue(randomPassword.contains { "0123456789".contains($0) })
        XCTAssertTrue(randomPassword.contains { "!@#$%^&*()-_+=<>?/[]{|}".contains($0) })
    }

    func testRequestRandomPassword() {
        // GIVEN
        mockDelegate.generateButtonDidTap_MockMethod = { _ in }

        // WHEN
        viewModel.requestRandomPassword()

        // THEN
        XCTAssertEqual(mockDelegate.generateButtonDidTap_Invocations.count, 1)
        XCTAssertFalse(mockDelegate.generateButtonDidTap_Invocations.first!.isEmpty)
    }

}
