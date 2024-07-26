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

import WireSyncEngine

final class ChangeEmailViewModel {

    private(set) var state: ChangeEmailState
    private weak var userProfile: UserProfile?

    init(currentEmail: String?, userProfile: UserProfile?) {
        self.state = ChangeEmailState(currentEmail: currentEmail ?? "")
        self.userProfile = userProfile
    }

    func updateNewEmail(_ newEmail: String) {
        state.newEmail = newEmail
    }

    func updateEmailValidationError(_ error: TextFieldValidator.ValidationError?) {
        state.emailValidationError = error
    }

    func requestEmailUpdate(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let email = state.validatedEmail else {
            completion(.failure(ChangeEmailError.invalidEmail))
            return
        }

        do {
            try userProfile?.requestEmailChange(email: email)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}
