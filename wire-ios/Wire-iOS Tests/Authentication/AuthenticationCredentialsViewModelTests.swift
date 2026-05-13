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

import XCTest
@testable import Wire

final class AuthenticationCredentialsViewModelTests: XCTestCase {

    func testItExposesRegistrationDisplayState() {
        // Given
        let sut = AuthenticationCredentialsViewModel(flowType: .registration(nil))

        // Then
        XCTAssertEqual(
            sut.displayState,
            AuthenticationCredentialsViewModel.DisplayState(
                isEmailPasswordInputHidden: true,
                isEmailInputHidden: false,
                isLoginButtonHidden: true,
                isForgotPasswordButtonHidden: true
            )
        )
        XCTAssertEqual(sut.contextualFirstResponder, .email)
        XCTAssertFalse(sut.shouldUseScrollView)
    }

    func testItExposesLoginDisplayState() {
        // Given
        let sut = AuthenticationCredentialsViewModel(flowType: .login(nil))

        // Then
        XCTAssertEqual(
            sut.displayState,
            AuthenticationCredentialsViewModel.DisplayState(
                isEmailPasswordInputHidden: false,
                isEmailInputHidden: true,
                isLoginButtonHidden: false,
                isForgotPasswordButtonHidden: false
            )
        )
        XCTAssertEqual(sut.contextualFirstResponder, .emailPassword)
        XCTAssertTrue(sut.shouldUseScrollView)
    }

    func testItPrefillsRegistrationEmailWhenProvided() {
        // Given
        let sut = AuthenticationCredentialsViewModel(flowType: .registration(prefilledCredentials(email: "a@b.com")))

        // Then
        XCTAssertEqual(sut.prefillTarget(), .registrationEmail("a@b.com"))
    }

    func testItDisablesEditingPrefilledRegistrationEmailForWireAuthentication() {
        // Given
        let sut = AuthenticationCredentialsViewModel(flowType: .registration(prefilledCredentials(email: "a@b.com")))

        // Then
        XCTAssertFalse(sut.canBeginEditingEmail(useWireAuthentication: true))
        XCTAssertTrue(sut.canBeginEditingEmail(useWireAuthentication: false))
    }

    func testItEnablesLoginButtonWithoutProxyFromEmailPasswordValidity() {
        // Given
        let sut = AuthenticationCredentialsViewModel(flowType: .login(nil))

        // Then
        XCTAssertTrue(sut.isLoginButtonEnabled(input: .init(
            isProxyCredentialsRequired: false,
            hasValidEmailPasswordInput: true,
            hasValidEmail: false,
            hasValidPassword: false,
            hasValidProxyUsername: false,
            hasValidProxyPassword: false
        )))
        XCTAssertFalse(sut.isLoginButtonEnabled(input: .init(
            isProxyCredentialsRequired: false,
            hasValidEmailPasswordInput: false,
            hasValidEmail: true,
            hasValidPassword: true,
            hasValidProxyUsername: true,
            hasValidProxyPassword: true
        )))
    }

    func testItRequiresEmailPasswordAndProxyCredentialsForProxyLogin() {
        // Given
        let sut = AuthenticationCredentialsViewModel(flowType: .login(nil))

        // Then
        XCTAssertTrue(sut.isLoginButtonEnabled(input: .init(
            isProxyCredentialsRequired: true,
            hasValidEmailPasswordInput: false,
            hasValidEmail: true,
            hasValidPassword: true,
            hasValidProxyUsername: true,
            hasValidProxyPassword: true
        )))
        XCTAssertFalse(sut.isLoginButtonEnabled(input: .init(
            isProxyCredentialsRequired: true,
            hasValidEmailPasswordInput: true,
            hasValidEmail: true,
            hasValidPassword: true,
            hasValidProxyUsername: true,
            hasValidProxyPassword: false
        )))
    }

    func testItRoutesConfirmedCredentialsToSubmitWhenProxyIsNotRequired() {
        // Given
        let sut = AuthenticationCredentialsViewModel(flowType: .login(nil))

        // When
        let route = sut.credentialsConfirmed(
            email: "a@b.com",
            password: "password",
            isProxyCredentialsRequired: false
        )

        // Then
        guard case let .submitCredentials(input, proxyInput) = route else {
            return XCTFail("Expected credentials submit route")
        }
        XCTAssertEqual(input.email, "a@b.com")
        XCTAssertEqual(input.password, "password")
        XCTAssertNil(proxyInput)
    }

    func testItRoutesConfirmedCredentialsToProxyUsernameWhenProxyIsRequired() {
        // Given
        let sut = AuthenticationCredentialsViewModel(flowType: .login(nil))

        // Then
        guard case .focus(.proxyUsername) = sut.credentialsConfirmed(
            email: "a@b.com",
            password: "password",
            isProxyCredentialsRequired: true
        ) else {
            return XCTFail("Expected proxy username focus route")
        }
    }

    private func prefilledCredentials(email: String) -> AuthenticationPrefilledCredentials {
        AuthenticationPrefilledCredentials(
            credentials: LoginCredentials(
                emailAddress: email,
                usesCompanyLogin: false
            ),
            isExpired: false
        )
    }
}
