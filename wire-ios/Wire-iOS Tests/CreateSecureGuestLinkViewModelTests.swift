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
import WireCommonComponents
@testable import Wire
import WireSyncEngineSupport

class CreateSecureGuestLinkViewModelTests: XCTestCase {

    // MARK: - Properties

    var viewModel: CreateSecureConversationGuestLinkViewModel!
    var mockDelegate: MockCreatePasswordSecuredLinkViewModelDelegate!
    var textField: ValidatedTextField!
    var confirmPasswordField: ValidatedTextField!
    var userSession: UserSessionMock!
    var conversationGuestLinkUseCase: MockCreateConversationGuestLinkUseCaseProtocol!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        FontScheme.configure(with: .large)
        conversationGuestLinkUseCase = MockCreateConversationGuestLinkUseCaseProtocol()
        userSession = UserSessionMock()
        viewModel = CreateSecureConversationGuestLinkViewModel(
            delegate: mockDelegate,
            conversationGuestLinkUseCase: conversationGuestLinkUseCase
        )
        mockDelegate = MockCreatePasswordSecuredLinkViewModelDelegate()
        viewModel.delegate = mockDelegate
        textField = ValidatedTextField(style: .default)
        confirmPasswordField = ValidatedTextField(style: .default)
    }

    // MARK: - tearDown

    override func tearDown() {
        viewModel = nil
        mockDelegate = nil
        textField = nil
        confirmPasswordField = nil
        conversationGuestLinkUseCase = nil
        super.tearDown()
    }

    // MARK: - Unit Tests

    // MARK: - Generation of Password

    func testGenerateRandomPassword() {
        // GIVEN && WHEN
        let randomPassword = viewModel.generateRandomPassword()

        conversationGuestLinkUseCase.invokeConversationPasswordCompletion_MockMethod = { _, _, _ in }

        // THEN
        XCTAssertTrue(randomPassword.count >= 15 && randomPassword.count <= 20, "Password length should be between 15 and 20 characters")
        XCTAssertTrue(randomPassword.contains { "abcdefghijklmnopqrstuvwxyz".contains($0) }, "Password should contain at least one lowercase letter")
        XCTAssertTrue(randomPassword.contains { "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains($0) }, "Password should contain at least one uppercase letter")
        XCTAssertTrue(randomPassword.contains { "0123456789".contains($0) }, "Password should contain at least one number")
        XCTAssertTrue(randomPassword.contains { "!@#$%^&*()-_+=<>?/[]{|}".contains($0) }, "Password should contain at least one special character")
    }

    func testRequestRandomPassword() {
        // GIVEN
        mockDelegate.viewModelDidGeneratePassword_MockMethod = { _, _ in }

        // WHEN
        viewModel.requestRandomPassword()

        // THEN
        XCTAssertEqual(mockDelegate.viewModelDidGeneratePassword_Invocations.count, 1)
    }

}
