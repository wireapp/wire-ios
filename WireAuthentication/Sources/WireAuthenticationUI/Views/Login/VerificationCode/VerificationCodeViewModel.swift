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

    private static let numberOfDigits = 6
    private let didDetectDomainConflict: Bool

    @Published var code: [String]
    @Published private(set) var isLoading = false
    @Published private(set) var isResending = false
    @Published var alert: Alert?

    let email: String
    let password: String
    let numberOfDigits: Int

    private let loginViaEmailUseCase: any LoginViaEmailUseCaseProtocol
    private let requestLoginVerificationCodeUseCase: any RequestLoginVerificationCodeUseCaseProtocol
    private let router: any Router

    package init(
        email: String,
        password: String,
        loginViaEmailUseCase: any LoginViaEmailUseCaseProtocol,
        requestLoginVerificationCodeUseCase: any RequestLoginVerificationCodeUseCaseProtocol,
        router: any Router,
        numberOfDigits: Int = VerificationCodeViewModel.numberOfDigits,
        didDetectDomainConflict: Bool
    ) {
        precondition(numberOfDigits > 0)

        self.email = email
        self.password = password
        self.loginViaEmailUseCase = loginViaEmailUseCase
        self.requestLoginVerificationCodeUseCase = requestLoginVerificationCodeUseCase
        self.router = router
        self.code = Array(repeating: "", count: numberOfDigits)
        self.numberOfDigits = numberOfDigits
        self.didDetectDomainConflict = didDetectDomainConflict
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

        let loginTask = Task.detached { [loginViaEmailUseCase, email, password, code] in
            try await loginViaEmailUseCase.invoke(
                email: email,
                password: password,
                verificationCode: code.joined()
            )
        }

        do {
            let (cookies, token) = try await loginTask.value
            router.presentSheet(
                RootView.ModalDestination.noHistory(
                    userID: token.userID,
                    cookies: cookies,
                    accessToken: token,
                    didDetectDomainConflict: didDetectDomainConflict
                )
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
                alert = .general(for: error)
            }
        }

        isLoading = false
    }

    func resend() async {
        isResending = true

        let requestTask = Task.detached { [requestLoginVerificationCodeUseCase, email] in
            try await requestLoginVerificationCodeUseCase.invoke(email: email)
        }

        do {
            try await requestTask.value

            WireLogger.authentication.info("Resend 2FA code succeeded")
        } catch {
            WireLogger.authentication.error("Resend 2FA login failed: \(error)")

            switch error {
            case RequestLoginVerificationCodeUseCaseFailure.invalidEmail:
                alert = .invalidEmail
            default:
                alert = .general(for: error)
            }
        }

        isResending = false
    }

}
