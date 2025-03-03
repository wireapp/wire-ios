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

import Combine
import SwiftUI
import WireAuthenticationAPI
import WireAuthenticationAPISupport
import WireFoundation
import WireReusableUIComponentsSupport
import WireTestingPackage
import XCTest

@testable import WireAuthenticationUI

class LoginViaEmailViewModelTests: XCTestCase {

    private var router: MockRouter!
    private var loginViaEmailUseCase: MockLoginViaEmailUseCaseProtocol!
    private var passwordValidator: MockPasswordValidator!
    private var sut: LoginViaEmailViewModel!
    private var onCreateAccountCalled = false
    private var isLoadingCalls: [Bool] = []
    private var cancellables: Set<AnyCancellable> = []

    @MainActor
    override func setUp() async throws {
        router = MockRouter()
        loginViaEmailUseCase = MockLoginViaEmailUseCaseProtocol()
        passwordValidator = MockPasswordValidator()
        passwordValidator.isPasswordValid_MockMethod = { _ in true }

        sut = LoginViaEmailViewModel(
            router: router,
            loginViaEmailUseCase: loginViaEmailUseCase,
            email: "mika@example.com",
            accountsURL: URL(string: "https://www.example.com")!,
            passwordValidator: passwordValidator,
            canCreateAccount: true,
            isCloudAccountAlreadyRegistered: false,
            onCreateAccount: { [self] in onCreateAccountCalled = true }
        )

        sut.$isLoading.dropFirst().sink { [self] in isLoadingCalls.append($0) }.store(in: &cancellables)
    }

    override func tearDown() {
        router = nil
        loginViaEmailUseCase = nil
        passwordValidator = nil
        sut = nil
        onCreateAccountCalled = false
        isLoadingCalls = []
    }

    // MARK: - submitPassword tests

    @MainActor
    func testSubmitPassword_passesCorrectCredentials() async {
        // given
        loginViaEmailUseCase
            .invokeEmailPasswordVerificationCode_MockValue = ([Scaffolding.someCookie], Scaffolding.someAccessToken)
        sut.password = " password "

        // when
        await sut.submitPassword()

        // then
        let invocations = loginViaEmailUseCase.invokeEmailPasswordVerificationCode_Invocations
        XCTAssertEqual(invocations.count, 1)
        XCTAssertEqual(invocations.first?.email, "mika@example.com")
        XCTAssertEqual(invocations.first?.password, "password")
    }

    @MainActor
    func testSubmitPassword_whenSuccessful() async {
        // given
        loginViaEmailUseCase
            .invokeEmailPasswordVerificationCode_MockValue = ([Scaffolding.someCookie], Scaffolding.someAccessToken)
        sut.password = "password"

        // when
        await sut.submitPassword()

        // then
        XCTAssertNil(sut.alert)
        XCTAssertEqual(isLoadingCalls, [true, false])
        XCTAssertEqual(router.modalPresent_Invocations.count, 1)
        XCTAssertEqual(
            router.modalPresent_Invocations.first as? RootView.ModalDestination,
            RootView.ModalDestination.noHistory(
                userID: Scaffolding.someAccessToken.userID,
                cookies: [Scaffolding.someCookie],
                accessToken: Scaffolding.someAccessToken
            )
        )
    }

    @MainActor
    func testSubmitPassword_withInvalidCredentials() async {
        // given
        loginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = .invalidCredentials

        // when
        await sut.submitPassword()

        // then
        XCTAssertEqual(sut.alert, .invalidCredentials)
        XCTAssertEqual(isLoadingCalls, [true, false])
    }

    @MainActor
    func testSubmitPassword_when2FARequired() async {
        // given
        loginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = .twoFactorAuthenticationRequired
        sut.password = "password"

        // when
        await sut.submitPassword()

        // then
        XCTAssertNil(sut.alert)
        XCTAssertEqual(isLoadingCalls, [true, false])
        XCTAssertEqual(router.navigate_Invocations.count, 1)
        XCTAssertEqual(
            router.navigate_Invocations.first as? LoginViaEmailView.Destination,
            LoginViaEmailView.Destination.verifyLogin(email: "mika@example.com", password: "password")
        )
    }

    @MainActor
    func testSubmitPassword_whenAccountPendingActivation() async {
        // given
        loginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = .accountPendingActivation

        // when
        await sut.submitPassword()

        // then
        XCTAssertEqual(sut.alert, .accountPendingActivation)
        XCTAssertEqual(isLoadingCalls, [true, false])
    }

    @MainActor
    func testSubmitPassword_whenAccountSuspended() async {
        // given
        loginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = .accountSuspended

        // when
        await sut.submitPassword()

        // then
        XCTAssertEqual(sut.alert, .accountSuspended)
        XCTAssertEqual(isLoadingCalls, [true, false])
    }

    @MainActor
    func testSubmitPassword_whenNoInternet() async {
        // given
        loginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = .noInternet

        // when
        await sut.submitPassword()

        // then
        XCTAssertEqual(sut.alert, .noInternet)
        XCTAssertEqual(isLoadingCalls, [true, false])
    }

    @MainActor
    func testSubmitPassword_whenUnknownErrorOccurs() async {
        // given
        loginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = .other

        // when
        await sut.submitPassword()

        // then
        XCTAssertEqual(sut.alert, .unknownError)
        XCTAssertEqual(isLoadingCalls, [true, false])
    }

    // MARK: - isPasswordValid tests

    @MainActor
    func testIsPasswordValid() {
        // given
        passwordValidator.isPasswordValid_MockMethod = { $0.count >= 4 }

        // when
        sut.password = " aaa "
        passwordValidator.isPasswordValid_Invocations = []

        // then
        XCTAssertFalse(sut.isPasswordValid)
        XCTAssertEqual(passwordValidator.isPasswordValid_Invocations, ["aaa"])

        // when
        sut.password = " aaaa "
        passwordValidator.isPasswordValid_Invocations = []

        // then
        XCTAssertTrue(sut.isPasswordValid)
        XCTAssertEqual(passwordValidator.isPasswordValid_Invocations, ["aaaa"])
    }

    // MARK: - isCreateAccount tests

    @MainActor
    func testCreateAccount_callsBridge() {
        // given, when
        sut.createAccount()

        // then
        XCTAssertTrue(onCreateAccountCalled)
    }

    // MARK: - showPasswordRules tests

    @MainActor
    func testShowPasswordRules() {
        // given
        passwordValidator.isPasswordValid_MockMethod = { $0.count >= 4 }
        XCTAssertFalse(sut.showPasswordRules) // initial state

        // when
        sut.password = "aaa"

        // then
        XCTAssertTrue(sut.showPasswordRules)

        // when
        sut.password = "aaaa"

        // then
        XCTAssertFalse(sut.showPasswordRules)
    }

    // MARK: - Scaffolding

    private enum Scaffolding {

        static let someCookie = HTTPCookie(properties: [
            .name: "some name",
            .path: "some path",
            .value: "some value",
            .domain: "some domain"
        ])!

        static let someAccessToken = AccessToken(userID: UUID(), token: "token", type: "type", expirationDate: Date())

    }

}
