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

import SwiftUI

public final class BackupActionsViewModel: ObservableObject {
    @Published var sections: [BackupActionsSection] = []

    private let backupSource: any BackupSourceProtocol
    private let backupHandler: BackupHandler
    let passwordValidator: any BackupPasswordValidatorProtocol

    public init(
        backupSource: any BackupSourceProtocol,
        backupHandler: BackupHandler,
        passwordValidator: any BackupPasswordValidatorProtocol
    ) {
        self.backupSource = backupSource
        self.backupHandler = backupHandler
        self.passwordValidator = passwordValidator

        self.sections = [
            BackupActionsSection(type: .backup)
        ]
    }

    func backupActiveAccount(password: String) {
        do {
            let backupPath = try backupSource.backupActiveAccount(password: password)
            backupHandler.onSuccess(backupPath) { [weak self] in
                self?.backupSource.clearPreviousBackups()
            }
        } catch {
            backupHandler.onFailure(error)
        }
    }
}
