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
import SwiftUI
import WireAuthenticationAPI
import WireLogging

@MainActor
public final class VerificationCodeViewModel: ObservableObject {

    package typealias Factory =
        LoginViaEmailUseCaseFactory &
        RequestLoginVerificationCodeUseCaseFactory

    private static let numberOfDigits = 6

    @Published var code: [String]
    @Published private(set) var isLoading = false
    @Published private(set) var isResending = false
    @Published var alert: Alert?

    let email: String
    let password: String
    let numberOfDigits: Int

    private let factory: any Factory
    private let router: any Router
    private let backendEnvironment: WireAuthenticationBackendEnvironment

    package init(
        factory: any Factory,
        email: String,
        password: String,
        router: any Router,
        backendEnvironment: WireAuthenticationBackendEnvironment,
        numberOfDigits: Int = VerificationCodeViewModel.numberOfDigits
    ) {
        precondition(numberOfDigits > 0)

        self.factory = factory
        self.email = email
        self.password = password
        self.router = router
        self.backendEnvironment = backendEnvironment
        self.code = Array(repeating: "", count: numberOfDigits)
        self.numberOfDigits = numberOfDigits
    }

    var isConfirmButtonDisabled: Bool {
        code.contains { $0.isEmpty }
    }

    func handleInputReturningFocus(_ newValue: String, at index: Int) -> Int? {
        if let intValue = Int(newValue.prefix(1)), (0 ... 9).contains(intValue) {
            code[index] = String(intValue)
        } else {
            code[index] = ""
        }

        return if !code[index].isEmpty {
            if index < numberOfDigits - 1 {
                index + 1
            } else {
                nil
            }
        } else if index > 0 {
            index - 1
        } else {
            0
        }
    }

    func confirm() async {
        isLoading = true

        do {
            let verificationCode = code.joined()
            let (cookies, token) = try await logIn(verificationCode: verificationCode)

            let emailCredentials = EmailCredentials(
                email: email,
                password: password,
                verificationCode: verificationCode
            )

            let authenticationResult = AuthenticationResult(
                userID: token.userID,
                cookies: cookies,
                accessToken: token,
                emailCredentials: emailCredentials,
                backendEnvironment: backendEnvironment
            )

            router.navigate(
                to: VerificationCodeDestination.noHistory(authenticationResult: authenticationResult)
            )
            WireLogger.authentication.info("2FA login via email succeeded")
        } catch {
            WireLogger.authentication.error("2FA login via email failed: \(error)")

            switch error {
            case LoginViaEmailUseCaseFailure.twoFactorAuthenticationFailed:
                alert = .invalid2FACode
            case LoginViaEmailUseCaseFailure.accountPendingActivation:
                alert = .accountPendingActivation
            case LoginViaEmailUseCaseFailure.accountSuspended:
                alert = .accountSuspended
            default:
                router.presentAlert(for: error)
            }
        }

        isLoading = false
    }

    func resend() async {
        isResending = true

        do {
            try await resendVerificationCode(email: email)
            WireLogger.authentication.info("Resend 2FA code succeeded")
        } catch {
            WireLogger.authentication.error("Resend 2FA login failed: \(error)")

            switch error {
            case RequestLoginVerificationCodeUseCaseFailure.invalidEmail:
                alert = .invalidEmail
            default:
                router.presentAlert(for: error)
            }
        }

        isResending = false
    }

    private func logIn(
        verificationCode: String
    ) async throws -> ([HTTPCookie], AccessToken) {
        let useCase = try await factory.loginViaEmailUseCase()
        return try await Task.detached { [email, password] in
            try await useCase.invoke(
                email: email,
                password: password,
                verificationCode: verificationCode
            )
        }.value
    }

    private func resendVerificationCode(email: String) async throws {
        let useCase = try await factory.requestLoginVerificationCodeUseCase()
        try await Task.detached {
            try await useCase.invoke(email: email)
        }.value
    }

}
