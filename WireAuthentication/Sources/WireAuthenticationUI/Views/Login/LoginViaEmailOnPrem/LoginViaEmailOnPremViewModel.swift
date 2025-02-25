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

import Foundation
import UIKit
import WireAuthenticationAPI
import WireReusableUIComponents

@MainActor
package final class LoginViaEmailOnPremViewModel: ObservableObject {

    private let router: any Router
    private let loginViaEmailUseCase: any LoginViaEmailUseCaseProtocol
    private let passwordValidator: any PasswordValidator
    private let backendEnvironment: LocalBackendEnvironment

    let email: String
    let canCreateAccount: Bool

    // MARK: - Life cycle

    package init(
        router: any Router,
        loginViaEmailUseCase: any LoginViaEmailUseCaseProtocol,
        email: String,
        backendEnvironment: LocalBackendEnvironment,
        passwordValidator: any PasswordValidator,
        canCreateAccount: Bool
    ) {
        self.router = router
        self.loginViaEmailUseCase = loginViaEmailUseCase
        self.email = email
        self.passwordValidator = passwordValidator
        self.canCreateAccount = canCreateAccount
        self.backendEnvironment = backendEnvironment
    }

    private var forgotPasswordURL: URL {
        backendEnvironment.accountsURL.appendingPathComponent("forgot")
    }

    var backendName: String {
        backendEnvironment.title
    }

    var backendInfo: String {
        [
            L10n.OnPremUserLogin.Alert.Message.backendName,
            backendName,
            "",
            L10n.OnPremUserLogin.Alert.Message.backendUrl,
            backendEnvironment.url.absoluteString
        ].joined(separator: "\n")
    }

    var localizedPasswordRules: String? {
        passwordValidator.localizedRulesDescription
    }

    var hasProxySupport: Bool {
        backendEnvironment.proxySettings != nil
    }

    var proxyServer: String {
        backendEnvironment.url.absoluteString
    }

    func isValidPassword(_ password: String) -> Bool {
        passwordValidator.isPasswordValid(password)
    }

    func submitPassword(_ password: String) {
        Task.detached {
            do {
                try await self.loginViaEmailUseCase.invoke(
                    email: self.email,
                    password: password,
                    verificationCode: ""
                )
            } catch {
                // TODO: [WPB-15944] Error handling
                print("error: \(error)")
            }
        }
    }

    func recoverPassword() {
        UIApplication.shared.open(forgotPasswordURL)
    }

    func createAccount() {
        // TODO: [WPB-15926] Initiate account registration flow
    }

}

// TODO: [WPB-16272] Remove duplication
public struct LocalBackendEnvironment {

    public init(
        title: String,
        url: URL,
        accountsURL: URL,
        proxySettings: LocalProxySettings? = nil
    ) {
        self.title = title
        self.url = url
        self.accountsURL = accountsURL
        self.proxySettings = proxySettings
    }

    /// The  name of the backend.
    ///
    public let title: String

    /// The `URL` of the backend.

    public let url: URL

    /// The `URL` of the accounts.

    public let accountsURL: URL

    /// The proxy settings for the backend if any.

    public let proxySettings: LocalProxySettings?

}

/// Proxy settings for communicating with a backend server.

// TODO: [WPB-16272] Remove duplication
public enum LocalProxySettings {

    /// Settings for an unauthenticated proxy.

    case unauthenticated(host: String, port: Int)

    /// Settings for an authenticated proxy.

    case authenticated(host: String, port: Int, username: String, password: String)

    /// Dictionary to be used with `URLSessionConfiguration.connectionProxyDictionary`.

    func proxyDictionary() -> [AnyHashable: Any] {
        let socksEnable = "SOCKSEnable"
        let socksProxy = "SOCKSProxy"
        let socksPort = "SOCKSPort"

        var result: [AnyHashable: Any] = [
            socksEnable: 1,
            kCFProxyTypeKey: kCFProxyTypeSOCKS,
            kCFStreamPropertySOCKSVersion: kCFStreamSocketSOCKSVersion5
        ]

        switch self {
        case let .unauthenticated(host, port):
            result[socksProxy] = host
            result[socksPort] = port
        case let .authenticated(host, port, username, password):
            result[socksProxy] = host
            result[socksPort] = port
            result[kCFStreamPropertySOCKSUser] = username
            result[kCFStreamPropertySOCKSPassword] = password
        }

        return result
    }

}
