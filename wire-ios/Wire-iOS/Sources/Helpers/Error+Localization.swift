//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireSyncEngine

extension SessionManager.AccountError: LocalizedError {

    typealias SettingsAddAccountLocale = L10n.Localizable.Self.Settings.AddAccount.Error

    public var errorDescription: String? {
        switch self {
        case .accountLimitReached:
            return SettingsAddAccountLocale.title
        }
    }

    public var failureReason: String? {
        switch self {
        case .accountLimitReached:
            return SettingsAddAccountLocale.message
        }
    }

}

extension SessionManager.SwitchBackendError: LocalizedError {

    typealias UrlActionSwitchBackendErrorLocale = L10n.Localizable.UrlAction.SwitchBackend.Error

    public var errorDescription: String? {
        switch self {
        case .invalidBackend:
            return UrlActionSwitchBackendErrorLocale.InvalidBackend.title
        case .loggedInAccounts:
            return UrlActionSwitchBackendErrorLocale.LoggedIn.title
        }
    }

    public var failureReason: String? {

        typealias UrlActionSwitchBackendErrorLocale = L10n.Localizable.UrlAction.SwitchBackend.Error

        switch self {
        case .invalidBackend:
            return UrlActionSwitchBackendErrorLocale.invalidBackend
        case .loggedInAccounts:
            return UrlActionSwitchBackendErrorLocale.loggedIn
        }
    }
}

extension DeepLinkRequestError: LocalizedError {

    typealias UrlActionLocale = L10n.Localizable.UrlAction

    public var errorDescription: String? {
        switch self {
        case .invalidUserLink:
            return UrlActionLocale.InvalidUser.title
        case .invalidConversationLink:
            return UrlActionLocale.InvalidConversation.title
        case .malformedLink:
            return UrlActionLocale.InvalidLink.title
        case .notLoggedIn:
            return UrlActionLocale.AuthorizationRequired.title
        }
    }

    public var failureReason: String? {

        typealias UrlActionLocale = L10n.Localizable.UrlAction

        switch self {
        case .invalidUserLink:
            return UrlActionLocale.InvalidUser.message
        case .invalidConversationLink:
            return UrlActionLocale.InvalidConversation.message
        case .malformedLink:
            return UrlActionLocale.InvalidLink.message
        case .notLoggedIn:
            return UrlActionLocale.AuthorizationRequired.message
        }
    }

}

extension CompanyLoginError: LocalizedError {

    public var errorDescription: String? {
        return L10n.Localizable.General.failure
    }

    public var failureReason: String? {
        return L10n.Localizable.Login.Sso.Error.Alert.message(displayCode)
    }

}

extension ConmpanyLoginRequestError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .invalidLink:
            return L10n.Localizable.Login.Sso.startErrorTitle
        }
    }

    public var failureReason: String? {
        switch self {
        case .invalidLink:
            return L10n.Localizable.Login.Sso.linkErrorMessage
        }
    }
}

extension ConnectToUserError: LocalizedError {

    typealias ConnectionError = L10n.Localizable.Error.Connection

    public var errorDescription: String? {
        return ConnectionError.title
    }

    public var failureReason: String? {
        switch self {
        case .missingLegalholdConsent:
            return ConnectionError.missingLegalholdConsent
        default:
            return ConnectionError.genericError
        }
    }

}

extension UpdateConnectionError: LocalizedError {

    typealias ConnectionError = L10n.Localizable.Error.Connection

    public var errorDescription: String? {
        return ConnectionError.title
    }

    public var failureReason: String? {
        switch self {
        case .missingLegalholdConsent:
            return ConnectionError.missingLegalholdConsent
        default:
            return ConnectionError.genericError
        }
    }

}
