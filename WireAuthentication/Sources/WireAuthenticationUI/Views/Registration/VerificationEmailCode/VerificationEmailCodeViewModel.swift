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
    private let router: any Router
    private let onFlowCompletion: (AuthenticationResult) -> Void
    private static let numberOfDigits = 6
    private var analyticsEventTracker: (any RegistrationAnalyticsTrackerProtocol)?

    // MARK: - Life cycle

    package init(
        factory: any Factory,
        router: any Router,
        email: String,
        password: String,
        name: String,
        onFlowCompletion: @escaping (AuthenticationResult) -> Void,
        numberOfDigits: Int = VerificationEmailCodeViewModel.numberOfDigits,
        analyticsEventTracker: (any RegistrationAnalyticsTrackerProtocol)?
    ) {
        precondition(numberOfDigits > 0)

        self.factory = factory
        self.router = router
        self.email = email
        self.password = password
        self.name = name
        self.onFlowCompletion = onFlowCompletion
        self.code = Array(repeating: "", count: numberOfDigits)
        self.numberOfDigits = numberOfDigits
        self.analyticsEventTracker = analyticsEventTracker
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
            let (cookies, userID) = try await register(verificationCode: verificationCode)
            guard let userID else {
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
                userID: userID
            )
            onFlowCompletion(authenticationResult)
        } catch {
            WireLogger.authentication.error("register personal account failed: \(error)")
            analyticsEventTracker?.trackPersonalAccountCreationFailedCodeVerification()

            switch error {
            case RegisterPersonalAccountUseCaseError.invalidEmail:
                alert = .invalidEmailForRegistration
            case RegisterPersonalAccountUseCaseError.blacklistedEmail:
                alert = .blacklistedEmail
            case RegisterPersonalAccountUseCaseError.tooManyTeamMembers:
                alert = .tooManyTeamMembers
            case RegisterPersonalAccountUseCaseError.userCreationRestricted:
                alert = .userCreationRestricted
            case RegisterPersonalAccountUseCaseError.invalidCode:
                alert = .invalidCode
            case RegisterPersonalAccountUseCaseError.emailExists:
                alert = .emailExists
            default:
                router.presentAlert(for: error)
            }
        }

        isLoading = false

    }

    func requestVerificationCode() async {
        isResending = true

        do {
            try await resendVerificationCode(email: email)
            WireLogger.authentication.info("Resend email verification code succeeded")
        } catch {
            WireLogger.authentication.error("Resend email verification code login failed: \(error)")

            switch error {
            case RequestEmailVerificationCodeUseCaseFailure.invalidEmail:
                alert = .invalidEmailForRegistration
            case RequestEmailVerificationCodeUseCaseFailure.blacklistedEmail:
                alert = .blacklistedEmail
            case RequestEmailVerificationCodeUseCaseFailure.emailExists:
                alert = .emailExists
            case RequestEmailVerificationCodeUseCaseFailure.domainBlockedForRegistration:
                alert = .domainBlockedForRegistration
            default:
                router.presentAlert(for: error)
            }
        }

        isResending = false
    }

    func trackReachedVerificationCodeIfNeeded() {
        analyticsEventTracker?.trackPersonalAccountCreationReachedVerificationCode()
    }

    // MARK: - Private

    private func resendVerificationCode(email: String) async throws {
        let useCase = try await factory.requestEmailVerificationCodeUseCase()
        return try await useCase.invoke(email: email)
    }

    private func createAuthenticationResult(
        cookies: [HTTPCookie],
        emailCredentials: EmailCredentials,
        userID: UUID
    ) async throws -> AuthenticationResult {
        let useCase = factory.createAuthenticationResultUseCase()
        return try await useCase.invoke(
            userID: userID,
            cookies: cookies,
            accessToken: nil,
            emailCredentials: emailCredentials
        )
    }

}
