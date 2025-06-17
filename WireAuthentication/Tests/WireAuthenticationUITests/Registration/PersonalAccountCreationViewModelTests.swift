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

import SwiftUI
import WireAuthenticationAPI
import WireAuthenticationAPISupport
import WireTestingPackage
import XCTest

@testable import WireAuthenticationUI
@testable import WireReusableUIComponents

final class PersonalAccountCreationViewModelTests: XCTestCase, PersonalAccountCreationViewModel.Factory {

    private var router: MockRouter!
    private var sut: PersonalAccountCreationViewModel!
    private var mockRegisterPersonalAccountUseCase: MockRegisterPersonalAccountUseCaseProtocol!
    private var mockRequestEmailVerificationCodeUseCase: MockRequestEmailVerificationCodeUseCaseProtocol!
    private var mockValidateEmailUseCase: MockValidateEmailUseCaseProtocol!
    private var passwordValidator: (any PasswordValidator)!

    @MainActor
    override func setUp() async throws {
        router = MockRouter()
        mockRegisterPersonalAccountUseCase = MockRegisterPersonalAccountUseCaseProtocol()
        mockRequestEmailVerificationCodeUseCase = MockRequestEmailVerificationCodeUseCaseProtocol()
        mockValidateEmailUseCase = MockValidateEmailUseCaseProtocol()
        passwordValidator = MockPasswordValidator()
        sut = PersonalAccountCreationViewModel(
            factory: self,
            router: router,
            email: "mika@example.com",
            privacyPolicyURL: URL(string: "https://wire.com")!,
            termsOfUseURL: URL(string: "https://wire.com")!,
            teamAccountCreationLink: URL(string: "https://wire.com")!,
            passwordValidator: passwordValidator
        )
    }

    override func tearDown() {
        router = nil
        sut = nil
        passwordValidator = nil
        mockRegisterPersonalAccountUseCase = nil
        mockRequestEmailVerificationCodeUseCase = nil
        mockValidateEmailUseCase = nil
    }

    // MARK: - Factory

    func registerPersonalAccountUseCase() async throws -> any RegisterPersonalAccountUseCaseProtocol {
        mockRegisterPersonalAccountUseCase
    }

    func requestEmailVerificationCodeUseCase() async throws -> any RequestEmailVerificationCodeUseCaseProtocol {
        mockRequestEmailVerificationCodeUseCase
    }

    func validateEmailUseCase() -> any ValidateEmailUseCaseProtocol {
        mockValidateEmailUseCase
    }

    var viewModel: PersonalAccountCreationViewModel {
        fatalError("not needed here")
    }

    func verificationEmailCodeFactory(
        email: String,
        password: String,
        name: String
    ) -> any VerificationEmailCodeFactory {
        fatalError("not needed here")
    }

    // MARK: - requestEmailVerificationCode tests

    @MainActor
    func testRequestEmailVerificationCode_whenSuccessful() async throws {
        // given
        sut.name = "mika"
        sut.email = " mika@example.com "
        sut.password = " password  "
        sut.confirmedPassword = " password  "

        // mock
        mockValidateEmailUseCase.invokeEmail_MockMethod = { _ in .isValid }
        mockRequestEmailVerificationCodeUseCase.invokeEmail_MockMethod = { _ in }

        // when
        try? await sut.requestEmailVerificationCode()

        // then
        XCTAssertNil(sut.alert)

        try XCTAssertCount(router.navigate_Invocations, count: 1)
        let actualDestination = try XCTUnwrap(router.navigate_Invocations[0] as? PersonalAccountCreationDestination)
        XCTAssertEqual(actualDestination, .verifyEmail(email: sut.email, password: sut.password, name: sut.name))
    }

    @MainActor
    func testRequestEmailVerificationCode_withInvalidCredentials() async {
        // given
        sut.name = "mika"
        sut.email = "mika@example.com "
        sut.password = "bad password"
        sut.confirmedPassword = "bad password"

        // mock
        mockValidateEmailUseCase.invokeEmail_MockMethod = { _ in .isValid }
        mockRequestEmailVerificationCodeUseCase.invokeEmail_MockError = RequestEmailVerificationCodeUseCaseFailure
            .invalidEmail

        // when
        try? await sut.requestEmailVerificationCode()

        // then
        XCTAssertEqual(sut.alert, .invalidEmailForRegistration)
    }

    // MARK: - Validation tests

    @MainActor
    func test_isNameValid() {
        sut.name = "Jo"
        XCTAssertFalse(sut.isNameValid)

        sut.name = String(repeating: "A", count: 65)
        XCTAssertFalse(sut.isNameValid)

        sut.name = "John Doe"
        XCTAssertTrue(sut.isNameValid)
    }

    @MainActor
    func test_isPasswordMatchConfirmedPassword() {
        sut.password = "123456"
        sut.confirmedPassword = "654321"
        XCTAssertFalse(sut.isPasswordMatchConfirmedPassword)

        sut.confirmedPassword = "123456"
        XCTAssertTrue(sut.isPasswordMatchConfirmedPassword)
    }

    @MainActor
    func test_canRequestVerificationCode_returnsTrueWhenAllConditionsAreValid() {
        sut.name = "Alice"
        sut.password = "securePassword"
        sut.confirmedPassword = "securePassword"

        mockValidateEmailUseCase.invokeEmail_MockValue = .isValid
        XCTAssertTrue(sut.canRequestVerificationCode)
    }

}
