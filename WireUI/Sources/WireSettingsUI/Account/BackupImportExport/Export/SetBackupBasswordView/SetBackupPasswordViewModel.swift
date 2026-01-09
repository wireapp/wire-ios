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

@MainActor
final class SetBackupPasswordViewModel: ObservableObject {

    @Published var password = "" {
        didSet { validatePassword() }
    }

    @Published private(set) var isPasswordValid = true

    var localizedPasswordRules: String {
        passwordValidator.localizedRulesDescription
    }

    private let passwordValidator: any BackupPasswordValidatorProtocol
    private let setPasswordAction: (_ password: String) -> Void
    private let cancelAction: () -> Void

    init(
        passwordValidator: any BackupPasswordValidatorProtocol,
        cancelAction: @escaping () -> Void,
        setPasswordAction: @escaping (_ password: String) -> Void
    ) {
        self.passwordValidator = passwordValidator
        self.cancelAction = cancelAction
        self.setPasswordAction = setPasswordAction
    }

    private func validatePassword() {
        isPasswordValid = password.isEmpty || passwordValidator.isPasswordValid(password)
    }

    func cancel() {
        cancelAction()
    }

    func triggerExport() {
        if isPasswordValid {
            setPasswordAction(password)
        }
    }
}
