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

class LoginViaEmailViewModelTests: XCTestCase, LoginViaEmailViewModel.Factory {

    private var router: MockRouter!
    private var sut: LoginViaEmailViewModel!
    private var factory: LoginViaEmailViewModel.Factory!
    private var onCreateAccountCalled = false
    private var isLoadingCalls: [Bool] = []
    private var cancellables: Set<AnyCancellable> = []

    private var mockSubmitProxyCredentialsUseCase: MockSubmitProxyCredentialsUseCaseProtocol!
    private var mockLoginViaEmailUseCase: MockLoginViaEmailUseCaseProtocol!
    private var mockCreateAuthenticationResultUseCase: MockCreateAuthenticationResultUseCaseProtocol!

    @MainActor
    override func setUp() async throws {
        router = MockRouter()
        mockSubmitProxyCredentialsUseCase = MockSubmitProxyCredentialsUseCaseProtocol()
        mockLoginViaEmailUseCase = MockLoginViaEmailUseCaseProtocol()
        mockCreateAuthenticationResultUseCase = MockCreateAuthenticationResultUseCaseProtocol()

        sut = LoginViaEmailViewModel(
            router: router,
            factory: self,
            email: "mika@example.com",
            backendInfo: MockDependencies().backendInfo,
            canCreateAccount: true,
            didDetectDomainConflict: false,
            onCreateAccount: { [self] in onCreateAccountCalled = true }
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

    // MARK: - submitPassword tests

    @MainActor
    func testSubmitPassword_passesCorrectCredentials() async {
        // given
        let authenticationResult = AuthenticationResult(
            userID: Fixture.someAccessToken.userID,
            cookies: [Fixture.someCookie],
            accessToken: Fixture.someAccessToken,
            emailCredentials: EmailCredentials(
                email: "mika@example.com",
                password: "password",
                verificationCode: nil
            ),
            backendEnvironment: Fixture.backendEnvironment
        )

        // mock
        mockLoginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockValue = (
            [Fixture.someCookie],
            Fixture.someAccessToken
        )
        mockCreateAuthenticationResultUseCase
            .invokeUserIDCookiesAccessTokenEmailCredentials_MockValue = authenticationResult

        // when
        await sut.submit(
            password: "password",
            proxyCredentials: nil
        )

        // then
        let invocations = mockLoginViaEmailUseCase.invokeEmailPasswordVerificationCode_Invocations
        XCTAssertEqual(invocations.count, 1)
        XCTAssertEqual(invocations.first?.email, "mika@example.com")
        XCTAssertEqual(invocations.first?.password, "password")
    }

    @MainActor
    func testSubmitPassword_whenSuccessful() async throws {
        // given
        let authenticationResult = AuthenticationResult(
            userID: Fixture.someAccessToken.userID,
            cookies: [Fixture.someCookie],
            accessToken: Fixture.someAccessToken,
            emailCredentials: EmailCredentials(
                email: "mika@example.com",
                password: "password",
                verificationCode: nil
            ),
            backendEnvironment: Fixture.backendEnvironment
        )

        // mock
        mockLoginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockValue = (
            [Fixture.someCookie],
            Fixture.someAccessToken
        )
        mockCreateAuthenticationResultUseCase
            .invokeUserIDCookiesAccessTokenEmailCredentials_MockValue = authenticationResult

        // when
        await sut.submit(
            password: "password",
            proxyCredentials: nil
        )

        // then
        XCTAssertNil(sut.alert)
        XCTAssertEqual(isLoadingCalls, [true, false])

        try XCTAssertCount(router.navigate_Invocations, count: 1)
        let actualDestination = try XCTUnwrap(router.navigate_Invocations[0] as? LoginViaEmailView.Destination)
        XCTAssertEqual(actualDestination, .noHistory(authenticationResult: authenticationResult))
    }

    @MainActor
    func testSubmitPassword_withInvalidCredentials() async {
        // mock
        mockLoginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = LoginViaEmailUseCaseFailure
            .invalidCredentials

        // when
        await sut.submit(
            password: "bad password",
            proxyCredentials: nil
        )

        // then
        XCTAssertEqual(sut.alert, .invalidCredentials)
        XCTAssertEqual(isLoadingCalls, [true, false])
    }

    @MainActor
    func testSubmitPassword_when2FARequired() async throws {
        // mock
        mockLoginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = LoginViaEmailUseCaseFailure
            .twoFactorAuthenticationRequired

        // when
        await sut.submit(
            password: "password",
            proxyCredentials: nil
        )

        // then
        XCTAssertNil(sut.alert)
        XCTAssertEqual(isLoadingCalls, [true, false])
        try XCTAssertCount(router.navigate_Invocations, count: 1)
        let actualDestination = try XCTUnwrap(router.navigate_Invocations[0] as? LoginViaEmailView.Destination)
        XCTAssertEqual(
            actualDestination,
            LoginViaEmailView.Destination.verifyLogin(email: "mika@example.com", password: "password")
        )
    }

    @MainActor
    func testSubmitPassword_whenAccountPendingActivation() async {
        // mock
        mockLoginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = LoginViaEmailUseCaseFailure
            .accountPendingActivation

        // when
        await sut.submit(
            password: "password",
            proxyCredentials: nil
        )

        // then
        XCTAssertEqual(sut.alert, .accountPendingActivation)
        XCTAssertEqual(isLoadingCalls, [true, false])
    }

    @MainActor
    func testSubmitPassword_whenAccountSuspended() async {
        // given
        mockLoginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = LoginViaEmailUseCaseFailure
            .accountSuspended

        // when
        await sut.submit(
            password: "password",
            proxyCredentials: nil
        )

        // then
        XCTAssertEqual(sut.alert, .accountSuspended)
        XCTAssertEqual(isLoadingCalls, [true, false])
    }

    @MainActor
    func testSubmitPassword_whenUnknownErrorOccurs() async {
        // given
        mockLoginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = URLError(.badURL)

        // when
        await sut.submit(
            password: "password",
            proxyCredentials: nil
        )

        // then
        XCTAssertEqual(router.alert_Invocations, [.unknownError])
        XCTAssertEqual(isLoadingCalls, [true, false])
    }

    // MARK: - isValidPassword tests

    @MainActor
    func testIsValidPassword() {
        XCTAssertTrue(sut.isValidPassword("p"))
        XCTAssertTrue(sut.isValidPassword("password"))
        XCTAssertFalse(sut.isValidPassword(""))
        XCTAssertFalse(sut.isValidPassword(" "))
    }

}
