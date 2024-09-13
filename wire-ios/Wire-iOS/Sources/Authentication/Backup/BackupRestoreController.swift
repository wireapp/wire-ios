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

import Foundation
import UniformTypeIdentifiers
import WireDataModel
import WireReusableUIComponents
import WireSyncEngine

protocol BackupRestoreControllerDelegate: AnyObject {
    func backupResoreControllerDidFinishRestoring(_ controller: BackupRestoreController)
}

/// An object that coordinates restoring a backup.

private let zmLog = ZMSLog(tag: "Backup")

final class BackupRestoreController: NSObject {
    // There are some external apps that users can use to transfer backup files, which can modify
    // their attachments and change the underscore with a dash. This is the reason we accept 2 types
    // of file extensions: 'ios_wbu' and 'ios-wbu'.

    static let WireBackupUTIs = ["com.wire.backup-ios-underscore", "com.wire.backup-ios-hyphen"]

    weak var delegate: BackupRestoreControllerDelegate?

    private let target: UIViewController
    private let activityIndicator: BlockingActivityIndicator
    private var temporaryFilesService: TemporaryFileServiceInterface

    // MARK: - Initialization

    init(target: UIViewController, temporaryFilesService: TemporaryFileServiceInterface = TemporaryFileService()) {
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
            forOpeningContentTypes: BackupRestoreController.WireBackupUTIs.compactMap { UTType($0) },
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
        guard let sessionManager = SessionManager.shared,
              let activity = BackgroundActivityFactory.shared.startBackgroundActivity(name: "restore backup") else {
            return
        }
        Task { @MainActor in activityIndicator.start() }

        sessionManager.restoreFromBackup(at: url, password: password) { [weak self] result in
            guard let self else {
                BackgroundActivityFactory.shared.endBackgroundActivity(activity)
                zmLog.safePublic("SessionManager.self is `nil` in performRestore", level: .error)
                WireLogger.localStorage.error("SessionManager.self is `nil` in performRestore")
                return
            }
            switch result {
            case .failure(SessionManager.BackupError.decryptionError):
                zmLog.safePublic(
                    "Failed restoring backup: \(SanitizedString(stringLiteral: SessionManager.BackupError.decryptionError.localizedDescription))",
                    level: .error
                )
                WireLogger.localStorage.error("Failed restoring backup: \(SessionManager.BackupError.decryptionError)")
                Task { @MainActor in self.activityIndicator.stop() }
                BackgroundActivityFactory.shared.endBackgroundActivity(activity)
                showWrongPasswordAlert { _ in
                    self.restore(with: url)
                }

            case let .failure(error):
                zmLog.safePublic(
                    "Failed restoring backup: \(SanitizedString(stringLiteral: error.localizedDescription))",
                    level: .error
                )
                WireLogger.localStorage.error("Failed restoring backup: \(error)")
                BackupEvent.importFailed.track()
                showRestoreError(error)
                Task { @MainActor in self.activityIndicator.stop() }
                BackgroundActivityFactory.shared.endBackgroundActivity(activity)

            case .success:
                BackupEvent.importSucceeded.track()
                temporaryFilesService.removeTemporaryData()
                delegate?.backupResoreControllerDidFinishRestoring(self)
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
            onCancel: { [unowned self] in delegate?.backupResoreControllerDidFinishRestoring(self) }
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
        zmLog.safePublic(SanitizedString(stringLiteral: "opening file at: \(url.absoluteString)"), level: .debug)

        restore(with: url)
    }
}
