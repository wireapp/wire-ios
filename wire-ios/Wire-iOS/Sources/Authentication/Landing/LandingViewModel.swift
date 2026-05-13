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

import Foundation
import WireTransport

final class LandingViewModel {

    typealias Landing = L10n.Localizable.Landing

    struct DisplayState: Equatable {
        let headerAccessibilityLabel: String
        let welcomeMessage: String
        let welcomeSubmessage: String
        let loginButtonTitle: String
        let loginWithEmailButtonTitle: String
        let enterpriseLoginButtonTitle: String
        let enterpriseLoginButtonAccessibilityLabel: String
        let createAccountInfoTitle: String
        let createAccountButtonTitle: String
        let cancelButtonAccessibilityLabel: String
        let showsEnterpriseLogin: Bool
        let customBackendURL: URL?
        let usesCustomBackendLayout: Bool
    }

    enum Route: Equatable {
        case createAccount
        case login
        case enterpriseLogin
        case customBackendInfo
        case cancel
    }

    func displayState(
        environmentType: EnvironmentType,
        allowsDirectCompanyLogin: Bool,
        customBackendEnabled: Bool
    ) -> DisplayState {
        DisplayState(
            headerAccessibilityLabel: Landing.header,
            welcomeMessage: Landing.welcomeMessage,
            welcomeSubmessage: Landing.welcomeSubmessage,
            loginButtonTitle: Landing.Login.Button.title,
            loginWithEmailButtonTitle: Landing.Login.Email.Button.title,
            enterpriseLoginButtonTitle: Landing.Login.Enterprise.Button.title,
            enterpriseLoginButtonAccessibilityLabel: L10n.Accessibility.Landing.LoginEnterpriseButton.description,
            createAccountInfoTitle: Landing.CreateAccount.infotitle,
            createAccountButtonTitle: Landing.CreateAccount.title,
            cancelButtonAccessibilityLabel: L10n.Localizable.General.cancel,
            showsEnterpriseLogin: allowsDirectCompanyLogin,
            customBackendURL: customBackendURL(
                for: environmentType,
                customBackendEnabled: customBackendEnabled
            ),
            usesCustomBackendLayout: usesCustomBackendLayout(for: environmentType)
        )
    }

    func routeForCreateAccountTapped() -> Route {
        .createAccount
    }

    func routeForLoginTapped() -> Route {
        .login
    }

    func routeForEnterpriseLoginTapped() -> Route {
        .enterpriseLogin
    }

    func routeForCustomBackendInfoTapped() -> Route {
        .customBackendInfo
    }

    func routeForCancelTapped() -> Route {
        .cancel
    }

    private func customBackendURL(
        for environmentType: EnvironmentType,
        customBackendEnabled: Bool
    ) -> URL? {
        guard customBackendEnabled else {
            return nil
        }

        switch environmentType {
        case let .custom(url):
            return url
        case .default, .staging, .anta, .bella, .chala, .diya, .elna, .foma:
            return nil
        }
    }

    private func usesCustomBackendLayout(for environmentType: EnvironmentType) -> Bool {
        switch environmentType {
        case .custom:
            true
        case .default, .staging, .anta, .bella, .chala, .diya, .elna, .foma:
            false
        }
    }
}
