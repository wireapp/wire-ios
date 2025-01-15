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

final class ExportBackupViewModel: ObservableObject {

    @Published var password = "" {
        didSet { validatePassword() }
    }

    @Published var isPasswordVisible = false
    @Published private(set) var isPasswordValid = true

    var localizedPasswordRules: String { passwordValidator.localizedRulesDescription }

    private let passwordValidator: any BackupPasswordValidatorProtocol
    private let alertPresenter: any BackupRestoreAlertPresenterProtocol
    private let exportBackupUseCase: any ExportBackupUseCaseProtocol

    init(
        passwordValidator: any BackupPasswordValidatorProtocol,
        alertPresenter: any BackupRestoreAlertPresenterProtocol,
        exportBackupUseCase: any ExportBackupUseCaseProtocol
    ) {
        self.passwordValidator = passwordValidator
        self.alertPresenter = alertPresenter
        self.exportBackupUseCase = exportBackupUseCase
    }

    private func validatePassword() {
        isPasswordValid = passwordValidator.isPasswordValid(password)
    }

    func triggerExport() {
        let password = password
        let exportBackupUseCase = exportBackupUseCase
        Task {
            do {
                let url: URL! = .init(string: "https://example.org")
                try await exportBackupUseCase.invoke(url: url, password: password)
            } catch {
                fatalError("TODO: use alertPresenter")
            }
        }
    }
}
