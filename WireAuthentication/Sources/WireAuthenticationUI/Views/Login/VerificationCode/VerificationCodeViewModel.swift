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

    package struct Alert: Hashable, Identifiable, Sendable {
        package var id: Self { self }

        let title: String
        let message: String

        private typealias Title = L10n.Authentication.Error.Title
        private typealias Message = L10n.Authentication.Error.Message

        static let noInternet = Alert(title: Title.noInternet, message: Message.noInternet)
        static let invalid2FACode = Alert(title: Title.invalidInvalid2FACode, message: Message.invalidInvalid2FACode)
        static let accountPendingActivation = Alert(
            title: Title.accountPendingActivation,
            message: Message.accountPendingActivation
        )
        static let accountSuspended = Alert(title: Title.accountSuspended, message: Message.accountSuspended)
        static let unknownError = Alert(title: Title.general, message: Message.general)
    }

    @Published var code: [String]
    @Published private(set) var isLoading = false
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
        code: [String] = ["", "", "", "", "", ""]
    ) {
        precondition(!code.isEmpty)

        self.email = email
        self.password = password
        self.loginViaEmailUseCase = loginViaEmailUseCase
        self.requestLoginVerificationCodeUseCase = requestLoginVerificationCodeUseCase
        self.router = router
        self.code = code
        self.numberOfDigits = code.count
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
                    accessToken: token
                )
            )
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
