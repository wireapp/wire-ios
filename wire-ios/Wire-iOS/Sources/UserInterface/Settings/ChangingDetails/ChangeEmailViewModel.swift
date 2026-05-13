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

import WireSyncEngine

final class ChangeEmailViewModel {

    // MARK: - Types

    struct DisplayState: Equatable {
        let visibleEmail: String?
        let isSaveButtonEnabled: Bool
    }

    enum Action {
        case requestEmailUpdate
        case showAlert(Error)
    }

    enum Route: Equatable {
        case confirmEmail(newEmail: String)
    }

    // MARK: - Properties

    private weak var userProfile: UserProfile?

    private let currentEmail: String?
    private let emailValidator = TextFieldValidator()

    private(set) var newEmail: String?
    private var emailValidationError: TextFieldValidator.ValidationError?

    // MARK: - Computed Properties

    private var validatedEmail: String? {
        guard let newEmail else { return nil }
        guard case .none = emailValidationError else {
            return nil
        }
        guard !newEmail.isEmpty, newEmail != currentEmail else {
            return nil
        }
        return newEmail
    }

    var displayState: DisplayState {
        DisplayState(
            visibleEmail: newEmail ?? currentEmail,
            isSaveButtonEnabled: validatedEmail != nil
        )
    }

    // MARK: - Initialization

    init(currentEmail: String?, userProfile: UserProfile?) {
        self.currentEmail = currentEmail
        self.userProfile = userProfile
        self.emailValidationError = nil
    }

    // MARK: - Methods

    @discardableResult
    func updateNewEmail(_ newEmail: String) -> DisplayState {
        self.newEmail = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        emailValidationError = emailValidator.validate(text: self.newEmail, kind: .email)
        return displayState
    }

    func saveButtonTapped() -> Action {
        guard validatedEmail != nil else {
            return .showAlert(ChangeEmailError.invalidEmail)
        }

        return .requestEmailUpdate
    }

    func requestEmailUpdate() throws -> Route? {
        guard let email = validatedEmail else {
            throw ChangeEmailError.invalidEmail
        }

        try userProfile?.requestEmailChange(email: email)
        return routeForEmailUpdateSuccess()
    }

    func routeForEmailUpdateSuccess() -> Route? {
        guard let newEmail = validatedEmail else {
            return nil
        }

        return .confirmEmail(newEmail: newEmail)
    }

    func actionForEmailUpdateFailure(_ error: Error) -> Action {
        .showAlert(error)
    }
}
