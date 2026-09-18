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
import WireSyncEngine

/// Localized copy for the "you've reached the maximum number of active accounts" alert,
/// spelling out the actual limit (e.g. "Two", "Three") so the same stringsdict entry works for any configured limit.
enum AccountLimitAlertLocalization {

    static func title(maxNumberAccounts: Int) -> String {
        "self.settings.add_account.error.title".localized(
            args: maxNumberAccounts,
            spelledOutNumber(maxNumberAccounts).capitalized
        )
    }

    static func message(maxNumberAccounts: Int) -> String {
        "self.settings.add_account.error.message".localized(
            args: maxNumberAccounts,
            spelledOutNumber(maxNumberAccounts)
        )
    }

    private static func spelledOutNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        return formatter.string(from: number as NSNumber) ?? String(number)
    }

}

extension SessionManager.AccountError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case let .accountLimitReached(maxNumberAccounts):
            AccountLimitAlertLocalization.title(maxNumberAccounts: maxNumberAccounts)
        }
    }

    public var failureReason: String? {
        switch self {
        case let .accountLimitReached(maxNumberAccounts):
            AccountLimitAlertLocalization.message(maxNumberAccounts: maxNumberAccounts)
        }
    }

}

extension SessionManager.SwitchBackendError: LocalizedError {

    typealias UrlActionSwitchBackendErrorLocale = L10n.Localizable.UrlAction.SwitchBackend.Error

    public var errorDescription: String? {
        switch self {
        case .invalidBackend:
            UrlActionSwitchBackendErrorLocale.InvalidBackend.title
        case .maxNumberAccountsReached:
            UrlActionSwitchBackendErrorLocale.LoggedIn.title
        }
    }

    public var failureReason: String? {

        typealias UrlActionSwitchBackendErrorLocale = L10n.Localizable.UrlAction.SwitchBackend.Error

        switch self {
        case .invalidBackend:
            return UrlActionSwitchBackendErrorLocale.invalidBackend
        case let .maxNumberAccountsReached(maxNumberAccounts):
            return AccountLimitAlertLocalization.message(maxNumberAccounts: maxNumberAccounts)
        }
    }
}

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

extension CompanyLoginError: LocalizedError {

    public var errorDescription: String? {
        L10n.Localizable.General.failure
    }

    public var failureReason: String? {
        L10n.Localizable.Login.Sso.Error.Alert.message(displayCode)
    }

}

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
