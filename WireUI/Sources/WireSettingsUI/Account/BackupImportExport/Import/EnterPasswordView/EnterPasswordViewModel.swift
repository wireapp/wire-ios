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

import Foundation

@MainActor
final class EnterPasswordViewModel: ObservableObject {

    /// Whether the current value in the text field is incorrect for the selected backup file.
    /// Once the user changes the value in the text field, this flag is cleared.
    @Published private(set) var passwordIsWrong: Bool

    @Published var password = ""
    @Published private(set) var isContinueEnabled = true // viewModel.password.isEmpty || viewModel.passwordIsWrong

    private let continueAction: (_ password: String) -> Void
    private let cancelAction: () -> Void

    init(
        previousWrongPassword: String,
        continueAction: @escaping (_: String) -> Void,
        cancelAction: @escaping () -> Void
    ) {
        passwordIsWrong = !previousWrongPassword.isEmpty
        password = previousWrongPassword
        self.continueAction = continueAction
        self.cancelAction = cancelAction
    }

    func `continue`() {
        continueAction(password)
    }

    func cancel() {
        cancelAction()
    }

}
