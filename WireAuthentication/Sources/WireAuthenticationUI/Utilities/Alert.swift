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


/// Identifies an alert and provides it's title and message.

struct Alert: Hashable, Identifiable, Sendable {

    package var id: Self { self }

    let title: String
    let message: String

}

// MARK: - Common alerts

extension Alert {

    private typealias Title = L10n.Authentication.Error.Title
    private typealias Message = L10n.Authentication.Error.Message

    static let noInternet = Alert(title: Title.noInternet, message: Message.noInternet)
    static let invalidCredentials = Alert(title: Title.invalidCredentials, message: Message.invalidCredentials)
    static let invalidEmail = Alert(title: Title.invalidCredentials, message: Message.invalidCredentials)
    static let invalid2FACode = Alert(title: Title.invalidInvalid2FACode, message: Message.invalidInvalid2FACode)
    static let accountPendingActivation = Alert(
        title: Title.accountPendingActivation,
        message: Message.accountPendingActivation
    )
    static let accountSuspended = Alert(title: Title.accountSuspended, message: Message.accountSuspended)
    static let unknownError = Alert(title: Title.general, message: Message.general)

}
