//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import UIKit
import WireCommonComponents
import WireTransport

// MARK: - AuthenticationCoordinator + LandingViewControllerDelegate

extension AuthenticationCoordinator: LandingViewControllerDelegate {
    func landingViewControllerDidChooseLogin() {
        if let fastloginCredentials = AutomationHelper.sharedHelper.automationEmailCredentials {
            let loginRequest = AuthenticationLoginRequest.email(
                address: fastloginCredentials.email,
                password: fastloginCredentials.password
            )
            let proxyCredentials = BackendEnvironment.shared.proxyCredentialsInput

            executeActions([.showLoadingView, .startLoginFlow(loginRequest, proxyCredentials)])
        } else {
            stateController.transition(to: .provideCredentials(nil))
        }
    }

    func landingViewControllerDidChooseCreateAccount() {
        typealias Alert = L10n.Localizable.Landing.Alert.CreateNewAccount.NotSupported

        guard !shouldShowProxyWarning else {
            showProxyAlert(title: Alert.title, message: Alert.message)
            return
        }

        let unregisteredUser = makeUnregisteredUser()
        stateController.transition(to: .createCredentials(unregisteredUser))
    }

    func landingViewControllerDidChooseEnterpriseLogin() {
        typealias Alert = L10n.Localizable.Landing.Alert.Sso.NotSupported

        guard !shouldShowProxyWarning else {
            showProxyAlert(title: Alert.title, message: Alert.message)
            return
        }

        executeActions([.startCompanyLogin(code: nil)])
    }

    func landingViewControllerDidChooseSSOLogin() {
        executeActions([.startSSOFlow])
    }

    func landingViewControllerDidChooseInfoBackend() {
        executeActions([.presentCustomBackendAlert])
    }

    private func showProxyAlert(title: String, message: String) {
        // not supported, show alert
        let alert = AuthenticationCoordinatorAlert(
            title: title,
            message: message,
            actions: [.ok]
        )
        executeActions([.presentAlert(alert)])
    }

    private var shouldShowProxyWarning: Bool {
        BackendEnvironment.shared.proxy != nil
    }
}

extension EnvironmentTypeProvider {
    var customUrl: URL? {
        switch value {
        case let .custom(url):
            url
        default:
            nil
        }
    }
}

extension BackendEnvironment {
    var proxyCredentials: ProxyCredentials? {
        proxy.flatMap { proxy in
            ProxyCredentials.retrieve(for: proxy)
        }
    }

    var proxyCredentialsInput: AuthenticationProxyCredentialsInput? {
        proxyCredentials.flatMap {
            AuthenticationProxyCredentialsInput(username: $0.username, password: $0.password)
        }
    }
}
