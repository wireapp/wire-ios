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
import Foundation
import Testing
import WireAuthenticationAPI
import WireAuthenticationAPISupport

@testable import WireAuthenticationUI

final class VerificationCodeViewModelTests {

    private let loginViaEmailUseCase: MockLoginViaEmailUseCaseProtocol
    private let requestLoginVerificationCodeUseCase: MockRequestLoginVerificationCodeUseCaseProtocol
    private let router: MockRouter
    private let sut: VerificationCodeViewModel
    private var isLoadingCalls: [Bool] = []
    private var isResendingCalls: [Bool] = []
    private var cancellables: Set<AnyCancellable> = []

    @MainActor
    init() {
        self.loginViaEmailUseCase = MockLoginViaEmailUseCaseProtocol()
        self.requestLoginVerificationCodeUseCase = MockRequestLoginVerificationCodeUseCaseProtocol()
        self.router = MockRouter()
        self.sut = VerificationCodeViewModel(
            email: "abc@example.com",
            password: "aaaaaa",
            loginViaEmailUseCase: loginViaEmailUseCase,
            requestLoginVerificationCodeUseCase: requestLoginVerificationCodeUseCase,
            router: router,
            numberOfDigits: 3, // Lets use a 3 digit code for simplicity
            didDetectDomainConflict: false
        )

        sut.$isLoading.dropFirst().sink { [self] in isLoadingCalls.append($0) }.store(in: &cancellables)
        sut.$isResending.dropFirst().sink { [self] in isResendingCalls.append($0) }.store(in: &cancellables)
    }

    // MARK: - isConfirmButtonDisabled tests

    @MainActor
    @Test(arguments: [
        (code: ["", "", ""], expected: true),
        (code: ["1", "2", ""], expected: true),
        (code: ["1", "2", "3"], expected: false)
    ])
    func isConfirmButtonDisabled(code: [String], expected: Bool) async throws {
        // given
        sut.code = code

        // when, then
        #expect(sut.isConfirmButtonDisabled == expected)
    }

    // MARK: - confirm tests

    @MainActor @Test
    func confirm_passesCorrectCredentials() async {
        // given
        loginViaEmailUseCase
            .invokeEmailPasswordVerificationCode_MockValue = ([Fixture.someCookie], Fixture.someAccessToken)
        sut.code = ["1", "2", "3"]

        // when
        await sut.confirm()

        // then
        let invocations = loginViaEmailUseCase.invokeEmailPasswordVerificationCode_Invocations
        #expect(invocations.count == 1)
        #expect(invocations.first?.email == "abc@example.com")
        #expect(invocations.first?.password == "aaaaaa")
        #expect(invocations.first?.verificationCode == "123")
    }

    @MainActor @Test
    func confirm_whenSuccess() async {
        // given
        loginViaEmailUseCase
            .invokeEmailPasswordVerificationCode_MockValue = ([Fixture.someCookie], Fixture.someAccessToken)
        sut.code = ["1", "2", "3"]

        // when
        await sut.confirm()

        // then
        #expect(sut.alert == nil)
        #expect(isLoadingCalls == [true, false])
        #expect(router.modalPresent_Invocations.count == 1)
        #expect(
            router.modalPresent_Invocations.first as? RootView.ModalDestination ==
                RootView.ModalDestination.noHistory(
                    userID: Fixture.someAccessToken.userID,
                    cookies: [Fixture.someCookie],
                    accessToken: Fixture.someAccessToken,
                    didDetectDomainConflict: false
                )
        )
    }

    @MainActor @Test
    func submitPassword_withInvalidCode() async {
        // given
        loginViaEmailUseCase
            .invokeEmailPasswordVerificationCode_MockError = LoginViaEmailUseCaseFailure.twoFactorAuthenticationFailed

        // when
        await sut.confirm()

        // then
        #expect(sut.alert == .invalid2FACode)
        #expect(isLoadingCalls == [true, false])
    }

    @MainActor
    @Test(arguments: [
        URLError(.notConnectedToInternet),
        URLError(.networkConnectionLost)
    ])
    func submitPassword_whenNoInternet(error: Error) async {
        // given
        loginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = error

        // when
        await sut.confirm()

        // then
        #expect(sut.alert == .noInternet)
        #expect(isLoadingCalls == [true, false])
    }

    @MainActor @Test
    func submitPassword_whenAccountPendingActivation() async {
        // given
        loginViaEmailUseCase
            .invokeEmailPasswordVerificationCode_MockError = LoginViaEmailUseCaseFailure.accountPendingActivation

        // when
        await sut.confirm()

        // then
        #expect(sut.alert == .accountPendingActivation)
        #expect(isLoadingCalls == [true, false])
    }

    @MainActor @Test
    func submitPassword_whenAccountSuspended() async {
        // given
        loginViaEmailUseCase
            .invokeEmailPasswordVerificationCode_MockError = LoginViaEmailUseCaseFailure.accountSuspended

        // when
        await sut.confirm()

        // then
        #expect(sut.alert == .accountSuspended)
        #expect(isLoadingCalls == [true, false])
    }

    @MainActor @Test(arguments: [
        LoginViaEmailUseCaseFailure.twoFactorAuthenticationRequired,
//        LoginViaEmailUseCaseFailure.other,
        LoginViaEmailUseCaseFailure.invalidCredentials
    ])
    func submitPassword_whenAnUnhandledError(error: LoginViaEmailUseCaseFailure) async {
        // given
        loginViaEmailUseCase.invokeEmailPasswordVerificationCode_MockError = error

        // when
        await sut.confirm()

        // then
        #expect(sut.alert == .unknownError)
        #expect(isLoadingCalls == [true, false])
    }

    // MARK: - handleInputReturningFocus tests

    @MainActor @Test(arguments: [
        (value: "", index: 0, expectedCode: ["", "2", "3"]),
        (value: "6a", index: 1, expectedCode: ["1", "6", "3"]),
        (value: "a6", index: 2, expectedCode: ["1", "2", ""]),
        (value: "6", index: 2, expectedCode: ["1", "2", "6"])
    ])
    func handleInputReturningFocus_updatesCode(value: String, index: Int, expectedCode: [String]) async {
        // given
        sut.code = ["1", "2", "3"]

        // when
        _ = sut.handleInputReturningFocus(value, at: index)

        // then
        #expect(sut.code == expectedCode)
    }

    @MainActor @Test(arguments: [
        (value: "1", index: 0, expectedFocus: 1), // Move to next field
        (value: "1", index: 2, expectedFocus: Int?.none), // Finished
        (value: "", index: 1, expectedFocus: 0), // Move to previous field
        (value: "", index: 0, expectedFocus: 0) // Already at the start
    ])
    func handleInputReturningFocus_returnsCorrectFocus(value: String, index: Int, outputFocus: Int?) async {
        // given
        sut.code = ["1", "2", "3"]

        // when
        let result = sut.handleInputReturningFocus(value, at: index)

        // then
        #expect(result == outputFocus)
    }

    // MARK: - resend tests

    @MainActor @Test
    func resend_whenSuccess() async {
        // given, when
        await sut.resend()

        // then
        #expect(isResendingCalls == [true, false])
        #expect(requestLoginVerificationCodeUseCase.invokeEmail_Invocations == ["abc@example.com"])
    }

    @MainActor @Test
    func resend_withInvalidEmail() async {
        // given
        requestLoginVerificationCodeUseCase.invokeEmail_MockError = .invalidEmail

        // when
        await sut.resend()

        // then
        #expect(isResendingCalls == [true, false])
        #expect(sut.alert == .invalidEmail)
    }

    @MainActor @Test(arguments: [
        RequestLoginVerificationCodeUseCaseFailure.unexpected(URLError(.notConnectedToInternet)),
        RequestLoginVerificationCodeUseCaseFailure.unexpected(URLError(.networkConnectionLost))
    ])
    func resend_whenNoInternet(error: RequestLoginVerificationCodeUseCaseFailure) async {
        // given
        requestLoginVerificationCodeUseCase.invokeEmail_MockError = error

        // when
        await sut.resend()

        // then
        #expect(isResendingCalls == [true, false])
        #expect(sut.alert == .noInternet)
    }

    @MainActor @Test
    func resend_whenSomeOtherError() async {
        // given
        requestLoginVerificationCodeUseCase.invokeEmail_MockError = RequestLoginVerificationCodeUseCaseFailure
            .unexpected(URLError(.badURL))

        // when
        await sut.resend()

        // then
        #expect(isResendingCalls == [true, false])
        #expect(sut.alert == .unknownError)
    }

}
