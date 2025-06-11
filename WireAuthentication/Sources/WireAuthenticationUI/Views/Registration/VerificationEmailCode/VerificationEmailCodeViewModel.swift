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
public final class VerificationEmailCodeViewModel: ObservableObject {

    package typealias Factory =
    CreateAuthenticationResultUseCaseFactory &
    RegisterPersonalAccountUseCaseFactory &
    RequestEmailVerificationCodeUseCaseFactory &
    VerificationEmailCodeFactory

    // MARK: - View state

    @Published var code: [String]
    @Published private(set) var isLoading = false
    @Published private(set) var isResending = false
    @Published var alert: Alert?

    let email: String
    let password: String
    let name: String
    let numberOfDigits: Int

    var isConfirmButtonDisabled: Bool {
        code.contains { $0.isEmpty }
    }

    // MARK: - Dependencies

    package let factory: any Factory
    private let onFlowCompletion: (AuthenticationResult) -> Void
    private static let numberOfDigits = 6

    // MARK: - Life cycle

    package init(
        factory: any Factory,
        email: String,
        password: String,
        name: String,
        onFlowCompletion: @escaping (AuthenticationResult) -> Void,
        numberOfDigits: Int = VerificationEmailCodeViewModel.numberOfDigits
    ) {
        precondition(numberOfDigits > 0)

        self.factory = factory
        self.email = email
        self.password = password
        self.name = name
        self.onFlowCompletion = onFlowCompletion
        self.code = Array(repeating: "", count: numberOfDigits)
        self.numberOfDigits = numberOfDigits
    }

    // MARK: - Actions

    func handleInputReturningFocus(
        _ newValue: String,
        at index: Int
    ) -> Int? {
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

    private func register(verificationCode: String) async throws -> ([HTTPCookie], UUID?) {
        let useCase = try await factory.registerPersonalAccountUseCase()
        return try await Task.detached { [email, password, name] in
            try await useCase.invoke(
                email: email,
                password: password,
                verificationCode: verificationCode,
                name: name
            )
        }.value
    }

    func confirm() async {
        isLoading = true
        let verificationCode = code.joined()
        do {
            let (cookies, uuid) = try await register(verificationCode: verificationCode)
            guard let uuid else {
                // add logs and show the error
                return
            }
            let emailCredentials = EmailCredentials(
                email: email,
                password: password,
                verificationCode: nil
            )
            let authenticationResult = try await createAuthenticationResult(
                cookies: cookies,
                emailCredentials: emailCredentials,
                userID: uuid
            )
            onFlowCompletion(authenticationResult)
        } catch {
            //            WireLogger.authentication.error("email erification code login via email failed: \(error)")
            //
            //            switch error {
            //            case LoginViaEmailUseCaseFailure.twoFactorAuthenticationFailed:
            //                alert = .invalid2FACode
            //            case LoginViaEmailUseCaseFailure.accountPendingActivation:
            //                alert = .accountPendingActivation
            //            case LoginViaEmailUseCaseFailure.accountSuspended:
            //                alert = .accountSuspended
            //            default:
            //                router.presentAlert(for: error)
            //            }
        }

        isLoading = false

    }

    func requestVerificationCode() async {
        isResending = true

        do {
            try await resendVerificationCode(email: email)
            WireLogger.authentication.info("Resend email erification code succeeded")
        } catch {
            WireLogger.authentication.error("Resend email erification code login failed: \(error)")

            //            switch error {
            //            case RequestLoginVerificationCodeUseCaseFailure.invalidEmail:
            //                alert = .invalidEmail
            //
            //            default:
            //                router.presentAlert(for: error)
            //            }
        }

        isResending = false
    }

    // MARK: - Private

    private func resendVerificationCode(email: String) async throws {
        let useCase = try await factory.requestEmailVerificationCodeUseCase()
        try await Task.detached {
            try await useCase.invoke(email: email)
        }.value
    }

    private func createAuthenticationResult(
        cookies: [HTTPCookie],
        emailCredentials: EmailCredentials,
        userID: UUID
    ) async throws -> AuthenticationResult {
        let useCase = factory.createAuthenticationResultUseCase()
        return try await Task.detached {
            try await useCase.invoke(
                userID: userID,
                cookies: cookies,
                accessToken: nil,
                emailCredentials: emailCredentials
            )
        }.value
    }

}
