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
import WireDataModel
import WireDomainPkg
import WireLogging
import WireReusableUIComponents
import WireSettingsUI
import WireSyncEngine

protocol BackupRestoreControllerDelegate: AnyObject {

    func backupResoreControllerDidFinishRestoring(
        _ controller: BackupRestoreController,
        didSucceed: Bool
    )

}

/// An object that coordinates restoring a backup.

final class BackupRestoreController: NSObject { // TODO: [WPB-15336] is it still used?

    weak var delegate: BackupRestoreControllerDelegate?

    private let target: UIViewController
    private let activityIndicator: BlockingActivityIndicator
    private var temporaryFilesService: TemporaryFileServiceInterface

    // MARK: - Initialization

    init(
        target: UIViewController,
        temporaryFilesService: TemporaryFileServiceInterface = TemporaryFileService()
    ) {
        self.target = target
        self.temporaryFilesService = temporaryFilesService
        self.activityIndicator = .init(view: target.view)
        super.init()
    }

    // MARK: - Flow

    func startBackupFlow() {
        let controller = UIAlertController(
            title: L10n.Localizable.Registration.NoHistory.RestoreBackupWarning.title,
            message: L10n.Localizable.Registration.NoHistory.RestoreBackupWarning.message,
            preferredStyle: .alert
        )
        controller.addAction(.cancel())
        controller.addAction(UIAlertAction(
            title: L10n.Localizable.Registration.NoHistory.RestoreBackupWarning.proceed,
            style: .default,
            handler: { _ in
                //showFilePicker()
            }
        ))

        target.present(controller, animated: true)
    }
}
