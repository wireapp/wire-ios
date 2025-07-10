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
import WireFoundation
import WireLogging

@MainActor
final class ExportBackupViewModel: ObservableObject {

    let createBackupUseCase: any CreateBackupUseCaseProtocol
    let cleanUpBackupsUseCase: any CleanUpBackupsUseCaseProtocol

    private var state: ExportBackupState? {
        didSet { updatePublishedProperties() }
    }

    // CreatingBackupProgress is the outer sheet, which contains/presents SetBackupPassword
    @Published var isCreatingBackupProgressPresented = false
    @Published var isSetBackupPasswordPresented = false
    @Published var isErrorAlertPresented = false

    @Published private(set) var backupProgress: CreatingBackupProgressModel = .ongoing(current: 0, total: 0)
    @Published private(set) var backupURL: URL?

    private var backupTask: Task<Void, Never>?

    private let logger: any LoggerProtocol

    init(
        createBackupUseCase: any CreateBackupUseCaseProtocol,
        cleanUpBackupsUseCase: any CleanUpBackupsUseCaseProtocol,
        logger: any LoggerProtocol
    ) {
        self.createBackupUseCase = createBackupUseCase
        self.cleanUpBackupsUseCase = cleanUpBackupsUseCase
        self.logger = logger
    }

    func reset() {
        backupTask?.cancel()
        state = nil
    }

    func showPasswordDialog() {
        guard state == nil else {
            logger.error("\(#function): state != nil")
            return assertionFailure()
        }
        state = .requestingPassword(password: "")
    }

    func createBackup(password: String) {
        backupTask?.cancel()
        backupTask = Task {
            do {
                state = .creatingBackup(current: 0, total: 0)
                for try await update in createBackupUseCase.invoke(password: password) {
                    switch update {
                    case let .progress(current, total):
                        state = .creatingBackup(current: current, total: total)
                    case let .done(url):
                        state = .backupReady(url: url)
                    }
                }
            } catch is CancellationError {
                logger.info("backup cancelled")
                state = nil
            } catch {
                logger.error("backup failed unexpectedly: " + String(reflecting: error))
                state = .backupFailed(error)
            }
        }
    }

    func cancel() {
        switch state {
        case .requestingPassword:
            state = nil
        case .creatingBackup:
            reset()
        case .backupReady:
            cleanUpBackups()
            state = nil
        case .backupFailed, .none:
            logger.error("unexpected state while received cancel: \(state == nil ? "nil" : ".backupFailed")")
            assertionFailure("unexpected state")
        }
    }

    private func updatePublishedProperties() {

        backupProgress = switch state {
        case let .creatingBackup(current, total):
            .ongoing(current: current, total: total)
        case let .backupReady(url):
            .finished(url)
        default:
            .ongoing(current: 0, total: 0)
        }

        // outer sheet
        let isCreatingBackupProgressPresented = switch state {
        case .requestingPassword, .creatingBackup, .backupReady:
            true
        default:
            false
        }

        // inner sheet
        let isSetBackupPasswordPresented = if case .requestingPassword = state {
            true
        } else {
            false
        }

        let isErrorAlertPresented = switch state {
        case .backupFailed:
            true
        default:
            false
        }

        // Workarounds for presentation issues with several sheet or alert presentation flags toggled at once.
        // This code assumes the presentation or dismissal of a modal view controller lasts less than 600ms.
        if !isCreatingBackupProgressPresented, self.isSetBackupPasswordPresented {
            // The outer sheet is dismissed while the inner sheet is still presented, so delay the outer dismissal.
            self.isSetBackupPasswordPresented = false
            return DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) { [weak self] in
                self?.updatePublishedProperties()
            }
        }
        if isSetBackupPasswordPresented, !self.isCreatingBackupProgressPresented {
            // The inner sheet is being presented while the outer sheet is not yet presented, so delay the inner.
            self.isCreatingBackupProgressPresented = true
            return DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) { [weak self] in
                self?.updatePublishedProperties()
            }
        }
        if isErrorAlertPresented, self.isCreatingBackupProgressPresented {
            // The alert is being presented while there is still a sheet presented, so delay the alert.
            self.isCreatingBackupProgressPresented = false
            return DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) { [weak self] in
                self?.updatePublishedProperties()
            }
        }

        self.isCreatingBackupProgressPresented = isCreatingBackupProgressPresented
        self.isSetBackupPasswordPresented = isSetBackupPasswordPresented
        self.isErrorAlertPresented = isErrorAlertPresented

    }

    private func cleanUpBackups() {
        Task {
            do {
                try await cleanUpBackupsUseCase.invoke()
            } catch {
                logger.error("cleaning up backups failed: \(String(reflecting: error))")
            }
        }
    }

}
