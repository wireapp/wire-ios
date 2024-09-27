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

import Foundation
import WireSyncEngine

// MARK: - SessionManager.AccountError + LocalizedError

extension SessionManager.AccountError: LocalizedError {
    typealias SettingsAddAccountLocale = L10n.Localizable.Self.Settings.AddAccount.Error

    public var errorDescription: String? {
        switch self {
        case .accountLimitReached:
            SettingsAddAccountLocale.title
        }
    }

    public var failureReason: String? {
        switch self {
        case .accountLimitReached:
            SettingsAddAccountLocale.message
        }
    }
}

// MARK: - SessionManager.SwitchBackendError + LocalizedError

extension SessionManager.SwitchBackendError: LocalizedError {
    typealias UrlActionSwitchBackendErrorLocale = L10n.Localizable.UrlAction.SwitchBackend.Error

    public var errorDescription: String? {
        switch self {
        case .invalidBackend:
            UrlActionSwitchBackendErrorLocale.InvalidBackend.title
        case .loggedInAccounts:
            UrlActionSwitchBackendErrorLocale.LoggedIn.title
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

// MARK: - DeepLinkRequestError + LocalizedError

extension DeepLinkRequestError: LocalizedError {
    typealias UrlActionLocale = L10n.Localizable.UrlAction

    public var errorDescription: String? {
        switch self {
        case .invalidUserLink:
            UrlActionLocale.InvalidUser.title
        case .invalidConversationLink:
            UrlActionLocale.InvalidConversation.title
        case .malformedLink:
            UrlActionLocale.InvalidLink.title
        case .notLoggedIn:
            UrlActionLocale.AuthorizationRequired.title
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

// MARK: - CompanyLoginError + LocalizedError

extension CompanyLoginError: LocalizedError {
    public var errorDescription: String? {
        L10n.Localizable.General.failure
    }

    public var failureReason: String? {
        L10n.Localizable.Login.Sso.Error.Alert.message(displayCode)
    }
}

// MARK: - ConmpanyLoginRequestError + LocalizedError

extension ConmpanyLoginRequestError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidLink:
            L10n.Localizable.Login.Sso.startErrorTitle
        }
    }

    public var failureReason: String? {
        switch self {
        case .invalidLink:
            L10n.Localizable.Login.Sso.linkErrorMessage
        }
    }
}

// MARK: - ConnectToUserError + LocalizedError

extension ConnectToUserError: LocalizedError {
    typealias ConnectionError = L10n.Localizable.Error.Connection

    public var errorDescription: String? {
        ConnectionError.title
    }

    public var failureReason: String? {
        switch self {
        case .missingLegalholdConsent:
            ConnectionError.missingLegalholdConsent
        default:
            ConnectionError.genericError
        }
    }
}

// MARK: - UpdateConnectionError + LocalizedError

extension UpdateConnectionError: LocalizedError {
    typealias ConnectionError = L10n.Localizable.Error.Connection

    public var errorDescription: String? {
        ConnectionError.title
    }

    public var failureReason: String? {
        switch self {
        case .missingLegalholdConsent:
            ConnectionError.missingLegalholdConsent
        default:
            ConnectionError.genericError
        }
    }
}
