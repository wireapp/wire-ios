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

final class ConfirmEmailViewModel {

    // MARK: - Types

    typealias Localizable = L10n.Localizable.Self.Settings.AccountSection.Email.Change

    struct DisplayState: Equatable {
        let title: String
        let description: String
        let resendButtonTitle: String
    }

    struct ResendConfirmation: Equatable {
        let title: String
        let message: String
        let buttonTitle: String
    }

    enum Action: Equatable {
        case resendVerification(ResendConfirmation)
    }

    enum Route: Equatable {
        case confirmedEmail
    }

    // MARK: - Properties

    let newEmail: String

    var displayState: DisplayState {
        DisplayState(
            title: Localizable.Verify.title,
            description: Localizable.Verify.description,
            resendButtonTitle: Localizable.Verify.resend(newEmail)
        )
    }

    // MARK: - Initialization

    init(newEmail: String) {
        self.newEmail = newEmail
    }

    // MARK: - Actions

    func resendButtonTapped() -> Action {
        .resendVerification(
            ResendConfirmation(
                title: Localizable.Resend.title,
                message: Localizable.Resend.message(newEmail),
                buttonTitle: L10n.Localizable.General.ok
            )
        )
    }

    // MARK: - Routing

    func routeForObservedEmailChange(
        isSelfUser: Bool,
        currentEmail: String?
    ) -> Route? {
        guard isSelfUser, currentEmail == newEmail else {
            return nil
        }

        return .confirmedEmail
    }
}
