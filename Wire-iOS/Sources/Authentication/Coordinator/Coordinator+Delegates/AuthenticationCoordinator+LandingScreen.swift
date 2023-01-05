//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireCommonComponents
import WireTransport

extension AuthenticationCoordinator: LandingViewControllerDelegate {

    func landingViewControllerDidChooseLogin() {
        if let fastloginCredentials = AutomationHelper.sharedHelper.automationEmailCredentials {
            let loginRequest = AuthenticationLoginRequest.email(address: fastloginCredentials.email, password: fastloginCredentials.password)
            let proxyCredentials = BackendEnvironment.shared.proxy.flatMap { proxy in
                ProxyCredentials.retrieve(for: proxy).flatMap { AuthenticationProxyCredentialsInput(username: $0.username, password: $0.password) }
            }

            executeActions([.showLoadingView, .startLoginFlow(loginRequest, proxyCredentials)])
        } else {
            stateController.transition(to: .provideCredentials(.email, nil))
        }
    }

    func landingViewControllerDidChooseCreateAccount() {
        if !showAlertIfProxy(title: L10n.Localizable.Landing.Alert.CreateNewAccount.NotSupported.title,
                                message: L10n.Localizable.Landing.Alert.CreateNewAccount.NotSupported.message) {
            let unregisteredUser = makeUnregisteredUser()
            stateController.transition(to: .createCredentials(unregisteredUser))
        }
    }

    func landingViewControllerDidChooseEnterpriseLogin() {
        if !showAlertIfProxy(title: L10n.Localizable.Landing.Alert.Sso.NotSupported.title,
                                message: L10n.Localizable.Landing.Alert.Sso.NotSupported.message) {
            executeActions([.startCompanyLogin(code: nil)])
        }
    }

    func landingViewControllerDidChooseSSOLogin() {
        executeActions([.startSSOFlow])
    }

    func landingViewControllerDidChooseInfoBackend() {
        let env = BackendEnvironment.shared

        let info = [
            L10n.Localizable.Landing.CustomBackend.Alert.Message.backendName,
            env.title,
            L10n.Localizable.Landing.CustomBackend.Alert.Message.backendUrl,
            env.backendURL.absoluteString
        ].joined(separator: "\n")

        executeActions([.presentAlert(.init(title: L10n.Localizable.Landing.CustomBackend.Alert.title,
                                            message: info,
                                            actions: [.ok]))])
    }

    private func showAlertIfProxy(title: String, message: String) -> Bool {
        guard BackendEnvironment.shared.proxy == nil else {
            // not supported, show alert
            let alert = AuthenticationCoordinatorAlert(title: title,
                                                       message: message,
                                                       actions: [.ok])
            executeActions([.presentAlert(alert)])
            return true
        }
        return false
    }
}

extension EnvironmentTypeProvider {
    var customUrl: URL? {
        switch value {
        case .custom(let url):
            return url
        default:
            return nil
        }
    }
}
