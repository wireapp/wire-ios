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

import Combine
import SwiftUI
import WireAuthenticationAPI
import WireAuthenticationAPISupport
import WireFoundation
import WireNetwork
import WireReusableUIComponentsSupport
import WireTestingPackage
import XCTest

@testable import WireAuthenticationUI

final class LoginViaEmailViewModelTests: XCTestCase, LoginViaEmailViewModel.Factory {

    private var router: MockRouter!
    private var sut: LoginViaEmailViewModel!
    private var factory: LoginViaEmailViewModel.Factory!
    private var onCreateAccountCalled = false
    private var isLoadingCalls: [Bool] = []
    private var cancellables: Set<AnyCancellable> = []

    private var mockSubmitProxyCredentialsUseCase: MockSubmitProxyCredentialsUseCaseProtocol!
    private var mockLoginViaEmailUseCase: MockLoginViaEmailUseCaseProtocol!
    private var mockCreateAuthenticationResultUseCase: MockCreateAuthenticationResultUseCaseProtocol!
    private var mockValidateEmailUseCase: MockValidateEmailUseCaseProtocol!

    @MainActor
    override func setUp() async throws {
        router = MockRouter()
        mockSubmitProxyCredentialsUseCase = MockSubmitProxyCredentialsUseCaseProtocol()
        mockLoginViaEmailUseCase = MockLoginViaEmailUseCaseProtocol()
        mockCreateAuthenticationResultUseCase = MockCreateAuthenticationResultUseCaseProtocol()
        mockValidateEmailUseCase = MockValidateEmailUseCaseProtocol()

        sut = LoginViaEmailViewModel(
            factory: self,
            router: router,
            email: "mika@example.com",
            environment: MockDependencies().backendEnvironment,
            canCreateAccount: true,
            didDetectDomainConflict: false
        )

        sut.$isLoading.dropFirst().sink { [self] in isLoadingCalls.append($0) }.store(in: &cancellables)
    }

    override func tearDown() {
        factory = nil
        router = nil
        sut = nil
        onCreateAccountCalled = false
        isLoadingCalls = []
        mockSubmitProxyCredentialsUseCase = nil
        mockLoginViaEmailUseCase = nil
        mockCreateAuthenticationResultUseCase = nil
        mockValidateEmailUseCase = nil
    }

    // MARK: - Factory

    func submitProxyCredentialsUseCase() -> any SubmitProxyCredentialsUseCaseProtocol {
        mockSubmitProxyCredentialsUseCase
    }

    func loginViaEmailUseCase() async throws -> any LoginViaEmailUseCaseProtocol {
        mockLoginViaEmailUseCase
    }

    func createAuthenticationResultUseCase() -> any CreateAuthenticationResultUseCaseProtocol {
        mockCreateAuthenticationResultUseCase
    }

    func validateEmailUseCase() -> any ValidateEmailUseCaseProtocol {
        mockValidateEmailUseCase
    }

    var viewModel: LoginViaEmailViewModel {
        fatalError("not needed here")
    }

    func verificationCodeFactory(
        email: String,
        password: String,
        proxyCredentials: ProxyCredentials?
    ) -> any VerificationCodeFactory {
        fatalError("not needed here")
    }

    func verifyLoginView(email: String, password: String, proxyCredentials: ProxyCredentials?) -> VerificationCodeView {
        fatalError()
    }

    func noHistoryView(result: AuthenticationResult) -> NoHistoryView {
        fatalError()
    }

    func personalAccountCreationView(teamAccountCreationLink: URL?) -> PersonalAccountCreationView {
        fatalError("not needed here")
    }

    // MARK: - submitPassword tests

    @MainActor
    func testSubmitPassword_passesCorrectCredentials() async {
        // given
        sut.email = " mika@example.com "
        sut.password = " password  "

        let authenticationResult = AuthenticationResult(
            userID: Fixture.someAccessToken.userID,
            cookies: [Fixture.someCookie],
            accessToken: Fixture.someAccessToken,
            emailCredentials: EmailCredentials(
                email: "mika@example.com",
                password: "password",
                verificationCode: nil
            ),
            backendEnvironment: Fixture.backendEnvironment,
            backendMetadata: Fixture.backendMetadata,
            proxyCredentials: nil
        )

        // mock
        mockLoginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockValue = (
            [Fixture.someCookie],
            Fixture.someAccessToken
        )
        mockCreateAuthenticationResultUseCase
            .invokeUserIDCookiesAccessTokenEmailCredentials_MockValue = authenticationResult

        // when
        await sut.submitCredentials()

        // then
        let invocations = mockLoginViaEmailUseCase.invokeEmailPasswordVerificationCode_Invocations
        XCTAssertEqual(invocations.count, 1)
        XCTAssertEqual(invocations.first?.email, "mika@example.com")
        XCTAssertEqual(invocations.first?.password, "password")
    }

    @MainActor
    func testSubmitPassword_whenSuccessful() async throws {
        // given
        sut.email = " mika@example.com "
        sut.password = " password  "

        let authenticationResult = AuthenticationResult(
            userID: Fixture.someAccessToken.userID,
            cookies: [Fixture.someCookie],
            accessToken: Fixture.someAccessToken,
            emailCredentials: EmailCredentials(
                email: "mika@example.com",
                password: "password",
                verificationCode: nil
            ),
            backendEnvironment: Fixture.backendEnvironment,
            backendMetadata: Fixture.backendMetadata,
            proxyCredentials: nil
        )

        // mock
        mockLoginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockValue = (
            [Fixture.someCookie],
            Fixture.someAccessToken
        )
        mockCreateAuthenticationResultUseCase
            .invokeUserIDCookiesAccessTokenEmailCredentials_MockValue = authenticationResult

        // when
        await sut.submitCredentials()

        // then
        XCTAssertNil(sut.alert)
        XCTAssertEqual(isLoadingCalls, [true, false])

        try XCTAssertCount(router.navigate_Invocations, count: 1)
        let actualDestination = try XCTUnwrap(router.navigate_Invocations[0] as? LoginViaEmailDestination)
        XCTAssertEqual(actualDestination, .noHistory(authenticationResult: authenticationResult))
    }

    @MainActor
    func testSubmitPassword_withInvalidCredentials() async {
        // given
        sut.email = " mika@example.com "
        sut.password = " bad password  "

        // mock
        mockLoginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = LoginViaEmailUseCaseFailure
            .invalidCredentials

        // when
        await sut.submitCredentials()

        // then
        XCTAssertEqual(sut.alert, .invalidCredentials)
        XCTAssertEqual(isLoadingCalls, [true, false])
    }

    @MainActor
    func testSubmitPassword_when2FARequired() async throws {
        // given
        sut.email = " mika@example.com "
        sut.password = " password  "
        // mock
        mockLoginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = LoginViaEmailUseCaseFailure
            .twoFactorAuthenticationRequired

        // when
        await sut.submitCredentials()

        // then
        XCTAssertNil(sut.alert)
        XCTAssertEqual(isLoadingCalls, [true, false])
        try XCTAssertCount(router.navigate_Invocations, count: 1)
        let actualDestination = try XCTUnwrap(router.navigate_Invocations[0] as? LoginViaEmailDestination)
        XCTAssertEqual(
            actualDestination,
            LoginViaEmailDestination
                .verifyLogin(
                    email: "mika@example.com",
                    password: "password",
                    proxyCredentials: nil
                )
        )
    }

    @MainActor
    func testSubmitPassword_whenAccountPendingActivation() async {
        // given
        sut.email = " mika@example.com "
        sut.password = " password  "

        // mock
        mockLoginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = LoginViaEmailUseCaseFailure
            .accountPendingActivation

        // when
        await sut.submitCredentials()

        // then
        XCTAssertEqual(sut.alert, .accountPendingActivation)
        XCTAssertEqual(isLoadingCalls, [true, false])
    }

    @MainActor
    func testSubmitPassword_whenAccountSuspended() async {
        // given
        sut.email = " mika@example.com "
        sut.password = " password  "

        // mock
        mockLoginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = LoginViaEmailUseCaseFailure
            .accountSuspended

        // when
        await sut.submitCredentials()

        // then
        XCTAssertEqual(sut.alert, .accountSuspended)
        XCTAssertEqual(isLoadingCalls, [true, false])
    }

    @MainActor
    func testSubmitPassword_whenUnknownErrorOccurs() async {
        // given
        sut.email = " mika@example.com "
        sut.password = " password  "

        // mock
        mockLoginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = URLError(.badURL)

        // when
        await sut.submitCredentials()
        // then
        XCTAssertEqual(router.alert_Invocations, [.unknownError])
        XCTAssertEqual(isLoadingCalls, [true, false])
    }

    // MARK: - isValidPassword tests

    @MainActor
    func testIsValidPassword() {
        XCTAssertTrue(sut.isPasswordValid("p"))
        XCTAssertTrue(sut.isPasswordValid("password"))
        XCTAssertFalse(sut.isPasswordValid(""))
        XCTAssertFalse(sut.isPasswordValid(" "))
    }

}
