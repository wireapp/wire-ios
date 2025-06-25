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
import WireDomainPackage
import WireFoundation
import WireLogging

@MainActor
final class ImportBackupViewModel: ObservableObject {

    let importBackupUseCaseFactory: any ImportBackupUseCaseFactoryProtocol

    private var state: ImportBackupState? {
        didSet { updatePublishedProperties() }
    }

    @Published var backupPassword = ""
    @Published var isBackupPasswordWrong = false

    @Published var isImportProgressPresented = false
    @Published var isEnterBackupPasswordPresented = false
    @Published var alertContent = AlertContent(title: "", message: "", action: "")
    @Published var isImportConfirmationPresented = false
    @Published var isAlertPresented = false

    @Published private(set) var importProgress = (current: 0, total: 0)

    private var importTask: Task<Void, Never>?
    private var hasDestructiveImportBeenConfirmed = false

    private let logger: any LoggerProtocol
    private let fileManager = FileManager.default

    private typealias Strings = L10n.Localizable.ImportBackup

    init(
        importBackupUseCaseFactory: any ImportBackupUseCaseFactoryProtocol,
        logger: any LoggerProtocol
    ) {
        self.importBackupUseCaseFactory = importBackupUseCaseFactory
        self.logger = logger
    }

    // MARK: - Methods

    func reset() {
        importTask?.cancel()
        state = nil
    }

    func pickedBackupFile(result: Result<URL, any Error>) {
        do {
            switch result {

            case let .failure(error):
                throw error

            case let .success(url):
                let gotAccess = url.startAccessingSecurityScopedResource()
                // let the file manager throw the error in case `gotAccess` is `false`.

                let tmpDirectory = try fileManager.url(
                    for: .itemReplacementDirectory,
                    in: .userDomainMask,
                    appropriateFor: url,
                    create: true
                )
                let copy = tmpDirectory.appendingPathComponent(url.lastPathComponent)
                try fileManager.copyItem(at: url, to: copy)
                if gotAccess {
                    url.stopAccessingSecurityScopedResource()
                }

                hasDestructiveImportBeenConfirmed = false
                importBackup(from: copy, password: "")
            }
        } catch {
            logger.error("failed to pick backup file to restore: " + String(reflecting: error))
            state = .restoreFailed
        }
    }

    func confirmOverwrite() {
        guard case let .requestConfirmation(url) = state else {
            logger.error("confirmOverwrite called while not in state `.requestConfirmation`")
            return assertionFailure()
        }
        hasDestructiveImportBeenConfirmed = true
        importBackup(from: url, password: "")
    }

    func enterPassword(_ password: String) {
        guard case let .requestingPassword(url, _) = state else {
            logger.error("enterPassword called while not in state `.requestingPassword`")
            return assertionFailure()
        }
        importBackup(from: url, password: password)
    }

    private func importBackup(from url: URL, password: String) {
        importTask?.cancel()
        importTask = Task {
            do {
                let importBackupUseCase = try importBackupUseCaseFactory.importBackupUseCase(for: url)

                // for legacy backups we need to ask for confirmation
                if importBackupUseCase.isImportDestructive, !hasDestructiveImportBeenConfirmed {
                    alertContent = .init(
                        title: Strings.OverwriteConfirmation.title,
                        message: Strings.OverwriteConfirmation.message,
                        cancel: Strings.OverwriteConfirmation.cancel,
                        action: Strings.OverwriteConfirmation.proceed
                    )
                    state = .requestConfirmation(url: url)
                    return
                }

                backupPassword = password
                state = .importingBackup(current: 0, total: 0)
                for try await update in importBackupUseCase.invoke(password: password) {
                    switch update {
                    case let .progress(current, total):
                        state = .importingBackup(current: current, total: total)
                    case .done:
                        alertContent = .init(
                            title: Strings.Alert.Success.message,
                            message: "",
                            action: Strings.Alert.ok
                        )
                        state = .success
                    }
                }

                // we should consider using LocalizedError instead of this mapping:
            } catch ImportLegacyBackupError.passwordRequired, ImportBackupError.passwordRequired {
                logger.debug("password is required to open backup file")
                state = .requestingPassword(url: url, isPasswordIncorrect: false)
                return // don't clean up temporary file
            } catch ImportLegacyBackupError.passwordRequired, ImportBackupError.incorrectPassword {
                logger.debug("provided password is incorrect")
                state = .requestingPassword(url: url, isPasswordIncorrect: false)
                return // don't clean up temporary file
            } catch ImportLegacyBackupError.decryptionError {
                logger.warn("failed to decrypt backup file, presenting the password input again")
                state = .requestingPassword(url: url, isPasswordIncorrect: true)
                return // don't clean up temporary file
            } catch ImportBackupError.incompatibleFileFormat {
                logger.warn("restore failed due to incompatible file format")
                alertContent = .init(
                    title: Strings.Alert.IncompatibleBackupError.title,
                    message: Strings.Alert.IncompatibleBackupError.message,
                    action: Strings.Alert.ok
                )
                state = .restoreFailed
            } catch ImportBackupError.selfUserIDMismatch, ImportLegacyBackupError.invalidAccountID {
                logger.warn("restore failed due to invalid account ID")
                alertContent = .init(
                    title: Strings.Alert.WrongFileError.title,
                    message: Strings.Alert.WrongFileError.message,
                    action: Strings.Alert.ok
                )
                state = .restoreFailed
            } catch is CancellationError {
                logger.info("restore cancelled")
                reset()
            } catch {
                logger.error("unexpected error while restoring: " + String(reflecting: error))
                alertContent = .init(
                    title: Strings.Alert.GenericError.title,
                    message: Strings.Alert.GenericError.message,
                    action: Strings.Alert.ok
                )
                state = .restoreFailed
            }
            do {
                try fileManager.removeItem(at: url)
            } catch {
                logger.error("failed to remove temporary file: " + String(reflecting: error))
            }
        }
    }

    private func updatePublishedProperties() {

        switch state {
        case let .importingBackup(current, total):
            importProgress = (current, total)
        case .success:
            importProgress = (1, 1)
        default:
            importProgress = (0, 0)
        }

        let isImportProgressPresented = switch state {
        case .requestConfirmation, .importingBackup, .requestingPassword:
            true
        default:
            false
        }

        let isImportConfirmationPresented = switch state {
        case .requestConfirmation:
            true
        default: false
        }

        let isEnterBackupPasswordPresented = if case .requestingPassword = state {
            true
        } else {
            false
        }

        let isAlertPresented = switch state {
        case .success, .restoreFailed:
            true
        default:
            false
        }

        isBackupPasswordWrong = if case let .requestingPassword(_, isWrong) = state {
            isWrong
        } else {
            false
        }

        // Workarounds for presentation issues with several sheet or alert presentation flags toggled at once.
        // This code assumes the presentation or dismissal of a modal view controller lasts less than 600ms.
        if !isImportProgressPresented, self.isImportConfirmationPresented {
            // The outer sheet is dismissed while the inner sheet/alert is presented, so delay the outer dismissal.
            self.isImportConfirmationPresented = false
            return DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) { [weak self] in
                self?.updatePublishedProperties()
            }
        }
        if !isImportProgressPresented, self.isEnterBackupPasswordPresented {
            // The outer sheet is dismissed while the inner sheet is still presented, so delay the outer dismissal.
            self.isEnterBackupPasswordPresented = false
            return DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) { [weak self] in
                self?.updatePublishedProperties()
            }
        }
        if isEnterBackupPasswordPresented, !self.isImportProgressPresented {
            // The inner sheet is being presented while the outer sheet is not yet presented, so delay the inner.
            self.isImportProgressPresented = true
            return DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) { [weak self] in
                self?.updatePublishedProperties()
            }
        }
        if isAlertPresented, self.isImportProgressPresented {
            // The alert is being presented while there is still a sheet presented, so delay the alert.
            self.isImportProgressPresented = false
            return DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) { [weak self] in
                self?.updatePublishedProperties()
            }
        }

        self.isImportProgressPresented = isImportProgressPresented
        self.isImportConfirmationPresented = isImportConfirmationPresented
        self.isEnterBackupPasswordPresented = isEnterBackupPasswordPresented
        self.isAlertPresented = isAlertPresented

    }

    struct AlertContent: Equatable {

        let title: String
        let message: String
        var cancel = ""
        let action: String

    }

}
