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
    private let backupResultHandler: BackupResultHandler
    let passwordValidator: any BackupPasswordValidatorProtocol

    @Published private(set) var progress: Double?
    @Published var presentBackupFailedAlert = false

    public init(
        backupSource: any BackupSourceProtocol,
        backupResultHandler: BackupResultHandler,
        passwordValidator: any BackupPasswordValidatorProtocol
    ) {
        self.backupSource = backupSource
        self.backupResultHandler = backupResultHandler
        self.passwordValidator = passwordValidator
    }

    func backupActiveAccount(password: String) {
        do {
            progress = 0.5
            throw DummyError.some

            let backupPath = try backupSource.backupActiveAccount(password: password)
            backupResultHandler.onSuccess(backupPath) { [weak self] in
                self?.backupSource.clearPreviousBackups()
                self?.progress = 1
            }
        } catch {
            progress = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
                self.presentBackupFailedAlert = true
            }
            backupResultHandler.onFailure(error)
        }
    }
}

enum DummyError: Error {
    case some
}
