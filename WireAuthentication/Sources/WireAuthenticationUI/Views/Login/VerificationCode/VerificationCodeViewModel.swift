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

    package enum Alert: Hashable, Identifiable, Sendable {
        package var id: Self { self }

        case noInternet
        case invalid2FACode
        case accountPendingActivation
        case accountSuspended
        case unknownError
    }

    @Published var code: [String]
    @Published private(set) var isLoading = false
    @Published var alert: Alert?

    let email: String
    let password: String
    let numberOfDigits: Int

    private let loginViaEmailUseCase: LoginViaEmailUseCaseProtocol

    package init(
        email: String,
        password: String,
        loginViaEmailUseCase: any LoginViaEmailUseCaseProtocol,
        code: [String] = ["", "", "", "", "", ""]
    ) {
        self.email = email
        self.password = password
        self.loginViaEmailUseCase = loginViaEmailUseCase
        self.code = code
        self.numberOfDigits = code.count
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
            // TODO: [WPB-16276] Navigate to the first time login screen
            WireLogger.authentication.info("2FA login via email succeeded")
        } catch {
            WireLogger.authentication.info("2FA login via email failed: \(error)")

            switch error {
            case LoginViaEmailUseCaseFailure.noInternet:
                alert = .noInternet
            case LoginViaEmailUseCaseFailure.twoFactorAuthenticationFailed:
                alert = .invalid2FACode
            case LoginViaEmailUseCaseFailure.accountPendingActivation:
                alert = .accountPendingActivation
            case LoginViaEmailUseCaseFailure.accountSuspended:
                alert = .accountSuspended
            default:
                WireLogger.authentication.error("Unexpected error during 2FA login via email: \(error)")
                alert = .unknownError
            }
        }

        isLoading = false
    }

    func resend() async {
        // TODO: [WPB-15950] Implement
    }

}
