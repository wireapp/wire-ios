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
import WireDomainPackage
import WireFoundation
import WireLogging
import WireBackup
import UIKit

@MainActor
final class ImportBackupViewModel: ObservableObject {

    // MARK: - Dependencies

    private let importBackupUseCaseFactory: any ImportBackupUseCaseFactoryProtocol
    private let coordinator: BackgroundImportCoordinator
    private let logger: any LoggerProtocol
    private let fileManager = FileManager.default

    // MARK: - Published State (UI only)

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

    @Published var isLoadingFile = false
    @Published private(set) var importProgress = (current: 0, total: 0)

    // MARK: - Private State

    private var hasDestructiveImportBeenConfirmed = false
    private var currentBackupCopy: URL?

    private typealias Strings = L10n.Localizable.ImportBackup

    // MARK: - Initialization

    init(
        importBackupUseCaseFactory: any ImportBackupUseCaseFactoryProtocol,
        logger: any LoggerProtocol
    ) {
        self.importBackupUseCaseFactory = importBackupUseCaseFactory
        self.coordinator = BackgroundImportCoordinator(importUseCaseFactory: importBackupUseCaseFactory)
        self.logger = logger
    }

    // MARK: - Methods

    func reset() {
        coordinator.cancelImport()
        state = nil
        cleanupBackupCopy()
    }

    func pickedBackupFile(result: Result<URL, any Error>) {
        func onFailure(_ error: any Error) {
            logger.error("failed to pick backup file to restore: " + String(reflecting: error))
            state = .restoreFailed
        }

        switch result {
        case let .failure(error):
            onFailure(error)
            return
        case let .success(url):
            Task { [self] in
                do {
                    state = .loadingFile

                    // Generate temporary copy for import
                    let copy = try await generateCopy(from: url)
                    currentBackupCopy = copy
                    hasDestructiveImportBeenConfirmed = false

                    // Start import via coordinator
                    try await startImport(from: copy, password: "")
                } catch {
                    onFailure(error)
                }
            }
        }
    }
    
    func confirmOverwrite() {
        guard case let .requestConfirmation(url) = state else {
            logger.error("confirmOverwrite called while not in state `.requestConfirmation`")
            return assertionFailure()
        }
        hasDestructiveImportBeenConfirmed = true

        Task {
            do {
                try await startImport(from: url, password: "")
            } catch {
                logger.error("Failed to start import: \(error)")
                state = .restoreFailed
            }
        }
    }

    func enterPassword(_ password: String) {
        guard case let .requestingPassword(url, _) = state else {
            logger.error("enterPassword called while not in state `.requestingPassword`")
            return assertionFailure()
        }

        Task {
            do {
                try await startImport(from: url, password: password)
            } catch {
                logger.error("Failed to start import: \(error)")
                state = .restoreFailed
            }
        }
    }

    private func startImport(from url: URL, password: String) async throws {
        // Check if destructive import needs confirmation
        let useCase = try importBackupUseCaseFactory.importBackupUseCase(for: url)
        if useCase.isImportDestructive, !hasDestructiveImportBeenConfirmed {
            alertContent = .init(
                title: Strings.OverwriteConfirmation.title,
                message: Strings.OverwriteConfirmation.message,
                cancel: Strings.OverwriteConfirmation.cancel,
                action: Strings.OverwriteConfirmation.proceed
            )
            state = .requestConfirmation(url: url)
            return
        }

        // Start import via coordinator and consume the progress stream
        let progressStream = coordinator.startImport(for: url, password: password)

        do {
            for try await progress in progressStream {
                switch progress {
                case .progress(let current, let total):
                    state = .importingBackup(current: current, total: total)

                case .done:
                    state = .success
                    alertContent = .init(
                        title: Strings.Alert.Success.message,
                        message: "",
                        action: Strings.Alert.ok
                    )
                }
            }
        } catch ImportBackupError.invalidFileExtension {
            logger.warn("restore failed due to invalid file extension")
            alertContent = .init(
                title: Strings.Alert.InvalidFileError.title,
                message: Strings.Alert.InvalidFileError.message,
                action: Strings.Alert.ok
            )
            state = .restoreFailed
        } catch ImportLegacyBackupError.passwordRequired, ImportBackupError.passwordRequired {
            logger.debug("password is required to open backup file")
            state = .requestingPassword(url: url, isPasswordIncorrect: false)
            return // Don't cleanup - preserve copy for password retry
        } catch ImportBackupError.incorrectPassword {
            logger.debug("provided password is incorrect")
            state = .requestingPassword(url: url, isPasswordIncorrect: true)
            return // Don't cleanup - preserve copy for password retry
        } catch ImportLegacyBackupError.decryptionError {
            logger.warn("failed to decrypt backup file, presenting the password input again")
            state = .requestingPassword(url: url, isPasswordIncorrect: true)
            return // Don't cleanup - preserve copy for password retry
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
            return // Don't cleanup - reset() already handles it
        } catch {
            logger.error("unexpected error while restoring: " + String(reflecting: error))
            alertContent = .init(
                title: Strings.Alert.GenericError.title,
                message: Strings.Alert.GenericError.message,
                action: Strings.Alert.ok
            )
            state = .restoreFailed
        }

        // Cleanup temporary copy after success or fatal error
        cleanupBackupCopy()
    }

    private func generateCopy(from url: URL) async throws -> URL {
        let localURL = try await materializeURL(url)
        let gotAccess = localURL.startAccessingSecurityScopedResource()

        defer {
            if gotAccess {
                localURL.stopAccessingSecurityScopedResource()
            }
        }
        
        // let the file manager throw the error in case `gotAccess` is `false`.
        let tmpDirectory = try fileManager.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: localURL,
            create: true
        )
        let copy = tmpDirectory.appendingPathComponent(localURL.lastPathComponent)

        try fileManager.copyItem(at: localURL, to: copy)

        return copy
    }

    // Materialize the url if needed. If we picked from iCloud
    // then it should already be downloaded and available locally,
    // but this may not be the case for other file providers such
    // as Google Drive.
    private func materializeURL(_ url: URL) async throws -> URL {
        let task = Task.detached {
            try await withCheckedThrowingContinuation { continuation in
                let coordinator = NSFileCoordinator()
                var error: NSError?

                coordinator.coordinate(
                    readingItemAt: url,
                    options: [],
                    error: &error
                ) {
                    continuation.resume(returning: $0)
                }

                // The completion is not called if there's an error, so we need
                // to check it here.
                if let error {
                    continuation.resume(throwing: error)
                }
            }
        }

        return try await task.value
    }

    private func cleanupBackupCopy() {
        guard let copy = currentBackupCopy else { return }

        do {
            try fileManager.removeItem(at: copy)
            currentBackupCopy = nil
        } catch {
            logger.error("failed to remove temporary file: " + String(reflecting: error))
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
        case .loadingFile, .requestConfirmation, .importingBackup, .requestingPassword:
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

        let isLoadingFile = switch state {
        case .loadingFile:
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

        self.isLoadingFile = isLoadingFile
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
