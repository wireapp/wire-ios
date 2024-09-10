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

import UIKit
import WireDataModel

extension BackupRestoreController {
    func restoreBackupFailed(
        error: Error,
        onTryAgain: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> UIAlertController {
        let controller = UIAlertController(
            title: title(for: error),
            message: message(for: error),
            preferredStyle: .alert
        )

        let tryAgainAction = UIAlertAction(
            title: L10n.Localizable.Registration.NoHistory.RestoreBackupFailed.tryAgain,
            style: .default,
            handler: { _ in onTryAgain() }
        )

        controller.addAction(tryAgainAction)
        controller.addAction(.cancel { onCancel() })
        return controller
    }

    private func title(for error: Error) -> String {
        switch error {
        case
            CoreDataStack.BackupImportError
            .incompatibleBackup(BackupMetadata.VerificationError.backupFromNewerAppVersion):
            L10n.Localizable.Registration.NoHistory.RestoreBackupFailed.WrongVersion.title
        case CoreDataStack.BackupImportError.incompatibleBackup(BackupMetadata.VerificationError.userMismatch):
            L10n.Localizable.Registration.NoHistory.RestoreBackupFailed.WrongAccount.title
        default:
            L10n.Localizable.Registration.NoHistory.RestoreBackupFailed.title
        }
    }

    private func message(for error: Error) -> String {
        switch error {
        case CoreDataStack.BackupImportError
            .incompatibleBackup(BackupMetadata.VerificationError.backupFromNewerAppVersion):
            L10n.Localizable.Registration.NoHistory.RestoreBackupFailed.WrongVersion.message
        case CoreDataStack.BackupImportError.incompatibleBackup(BackupMetadata.VerificationError.userMismatch):
            L10n.Localizable.Registration.NoHistory.RestoreBackupFailed.WrongAccount.message
        default:
            L10n.Localizable.Registration.NoHistory.RestoreBackupFailed.message + "\n\(error.localizedDescription)"
        }
    }
}
