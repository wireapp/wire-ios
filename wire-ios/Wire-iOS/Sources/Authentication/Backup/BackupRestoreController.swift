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
import WireLogging
import WireReusableUIComponents
import WireSyncEngine
import WireSettingsUI
import WireDomainPkg

protocol BackupRestoreControllerDelegate: AnyObject {

    func backupResoreControllerDidFinishRestoring(
        _ controller: BackupRestoreController,
        didSucceed: Bool
    )

}

/// An object that coordinates restoring a backup.

final class BackupRestoreController: NSObject {

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
            handler: { [showFilePicker] _ in
                showFilePicker()
            }
        ))

        target.present(controller, animated: true)
    }

    private func showFilePicker() {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: WireBackupUTIs,
            asCopy: true
        )

        picker.delegate = self
        target.present(picker, animated: true)
    }

    private func restore(with url: URL) {
        requestPassword { password in
            self.performRestore(
                using: password,
                from: url
            )
        }
    }

    private func performRestore(
        using password: String,
        from url: URL
    ) {
        guard
            let sessionManager = SessionManager.shared,
            let activity = BackgroundActivityFactory.shared.startBackgroundActivity(name: "restore backup")
        else {
            return
        }

        Task { @MainActor in activityIndicator.start() }

        sessionManager.restoreFromBackup(at: url, password: password) { [weak self] result in
            guard let self else {
                BackgroundActivityFactory.shared.endBackgroundActivity(activity)
                WireLogger.localStorage.error("SessionManager.self is `nil` in performRestore")
                return
            }

            switch result {
            case .failure(CreateLegacyBackupError.decryptionError):
                WireLogger.localStorage.error("Failed restoring backup: \(CreateLegacyBackupError.decryptionError)")
                Task { @MainActor in self.activityIndicator.stop() }
                BackgroundActivityFactory.shared.endBackgroundActivity(activity)
                showWrongPasswordAlert { _ in
                    self.restore(with: url)
                }

            case let .failure(error):
                WireLogger.localStorage.error("Failed restoring backup: \(error)")
                showRestoreError(error)
                Task { @MainActor in self.activityIndicator.stop() }
                BackgroundActivityFactory.shared.endBackgroundActivity(activity)

            case .success:
                temporaryFilesService.removeTemporaryData()
                delegate?.backupResoreControllerDidFinishRestoring(self, didSucceed: true)
                BackgroundActivityFactory.shared.endBackgroundActivity(activity)
            }
        }
    }

    // MARK: - Alerts

    private func requestPassword(completion: @escaping (String) -> Void) {
        let controller = requestRestorePassword { password in
            password.map(completion)
        }

        target.present(controller, animated: true, completion: nil)
    }

    private func showWrongPasswordAlert(completion: @escaping (UIAlertAction) -> Void) {
        let controller = importWrongPasswordError(completion: completion)
        target.present(controller, animated: true, completion: nil)
    }

    private func showRestoreError(_ error: Error) {
        let controller = restoreBackupFailed(
            error: error,
            onTryAgain: { [unowned self] in showFilePicker() },
            onCancel: { [unowned self] in delegate?.backupResoreControllerDidFinishRestoring(self, didSucceed: false) }
        )

        target.present(controller, animated: true)
    }
}

extension BackupRestoreController: UIDocumentPickerDelegate {
    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentAt url: URL
    ) {
        WireLogger.localStorage.debug("opening file at: \(url.absoluteString)")

        restore(with: url)
    }
}
