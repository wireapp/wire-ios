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

public final class BackupRestoreViewModel: ObservableObject {

    private let backupSource: any BackupSourceProtocol
    private let restoreSource: any RestoreSourceProtocol
    private let backupResultHandler: BackupResultHandler
    private let restoreBackupResultHandler: RestoreBackupResultHandler
    let passwordValidator: any BackupPasswordValidatorProtocol

    public init(
        backupSource: any BackupSourceProtocol,
        restoreSource: any RestoreSourceProtocol,
        backupResultHandler: BackupResultHandler,
        restoreBackupResultHandler: RestoreBackupResultHandler,
        passwordValidator: any BackupPasswordValidatorProtocol
    ) {
        self.backupSource = backupSource
        self.restoreSource = restoreSource
        self.backupResultHandler = backupResultHandler
        self.restoreBackupResultHandler = restoreBackupResultHandler
        self.passwordValidator = passwordValidator
    }

    func backupActiveAccount(password: String) {
        do {
            let backupPath = try backupSource.backupActiveAccount(password: password)
            backupResultHandler.onSuccess(backupPath) { [weak self] in
                self?.backupSource.clearPreviousBackups()
            }
        } catch {
            backupResultHandler.onFailure()
        }
    }

    func restoreFromBackup(
        at location: URL,
        password: String,
        completion: @escaping (Result<Void, any Error>) -> Void
    ) {
        restoreSource.restoreFromBackup(at: location, password: password) { result in
            completion(result)
            switch result {
            case .success:
                self.restoreBackupResultHandler.onSuccess()
            case .failure:
                self.restoreBackupResultHandler.onFailure()
            }
        }
    }

    func confirmBackupRestore(completion: @escaping () -> Void) {
        restoreBackupResultHandler.onConfirmation {
            completion()
        }
    }
}
