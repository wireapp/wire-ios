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
import WireAuthenticationAPI
import WireNetwork

/// Identifies an alert and provides it's title and message.

package struct Alert: Hashable, Identifiable, Sendable {

    public var id: Self { self }

    let title: String
    let message: String

}

// MARK: - Common alerts

extension Alert {

    private typealias Title = L10n.Localizable.Authentication.Error.Title
    private typealias Message = L10n.Localizable.Authentication.Error.Message

    static let noInternet = Alert(
        title: Title.noInternet,
        message: Message.noInternet
    )

    static let invalidCredentials = Alert(
        title: Title.invalidCredentials,
        message: Message.invalidCredentials
    )

    static let invalidEmail = Alert(
        title: Title.invalidCredentials,
        message: Message.invalidCredentials
    )

    static let invalid2FACode = Alert(
        title: Title.invalidInvalid2FACode,
        message: Message.invalidInvalid2FACode
    )

    static let accountPendingActivation = Alert(
        title: Title.accountPendingActivation,
        message: Message.accountPendingActivation
    )

    static let accountSuspended = Alert(
        title: Title.accountSuspended,
        message: Message.accountSuspended
    )

    static let obsoleteClient = Alert(
        title: L10n.Localizable.ObsoleteClient.Alert.title,
        message: L10n.Localizable.ObsoleteClient.Alert.message
    )

    static let obsoleteBackend = Alert(
        title: L10n.Localizable.ObsoleteBackend.Alert.title,
        message: L10n.Localizable.ObsoleteBackend.Alert.message
    )

    static let switchBackendFailed = Alert(
        title: L10n.Localizable.SwitchBackend.Error.Title.loggedIn,
        message: L10n.Localizable.SwitchBackend.Error.Message.loggedIn
    )

    static let unknownError = Alert(
        title: Title.general,
        message: Message.general
    )

    static let ssoLoginFailed = Alert(
        title: Title.ssoLoginFailed,
        message: Message.ssoLoginFailed
    )

    static let invalidSSOLink = Alert(
        title: Title.ssoLoginFailed,
        message: Message.ssoLoginFailed
    )

    static let incorrectSSOCode = Alert(
        title: Title.incorrectSsoCode,
        message: Message.incorrectSsoCode
    )

    static let termsOfUse = Alert(
        title: L10n.Localizable.CreatePersonalAccount.ConfirmationAlert.title,
        message: L10n.Localizable.CreatePersonalAccount.ConfirmationAlert.message
    )

    static let logoutConfirmation = Alert(
        title: L10n.Localizable.Logout.Alert.title,
        message: L10n.Localizable.Logout.Alert.message
    )

}

extension Alert {

    /// Returns a suitable alert for the given error. This is intended to be used used in the unhandled alert case.

    static func general(for error: Error) -> Self {
        switch error {
        case URLError.notConnectedToInternet, URLError.networkConnectionLost:
            .noInternet
        case NetworkStackError.clientAPIVersionObsolete:
            .obsoleteClient
        case NetworkStackError.backendAPIVersionObsolete:
            .obsoleteBackend
        default:
            .unknownError
        }
    }

}
