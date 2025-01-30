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

@MainActor
final class ExportBackupViewModel: ObservableObject {

    let createBackupUseCase: any CreateBackupUseCaseProtocol
    // let cleanUpBackupsUseCase: any CleanUpBackupsUseCaseProtocol

    private var state: ExportBackupState? {
        didSet { updatePublishedProperties() }
    }

    // CreatingBackupProgress is the outer sheet, which contains/presents SetBackupPassword
    @Published var isCreatingBackupProgressPresented = false
    @Published var isSetBackupPasswordPresented = false
    @Published var isErrorAlertPresented = false

    @Published private(set) var backupProgress: Float?
    @Published private(set) var backupURL: URL?
    var backupError: (any Error)? { state?.backupError }

    private var backupTask: Task<Void, any Error>?

    init(createBackupUseCase: any CreateBackupUseCaseProtocol) {
        self.createBackupUseCase = createBackupUseCase
    }

    func requestBackupPassword() {
        guard state == nil else { return assertionFailure() }

        state = .requestingPassword(password: "")
    }

    func createBackup(password: String) {
        guard backupTask == nil else { return assertionFailure() }

        backupTask = Task {
            defer { backupTask = nil }

            do {
                for try await update in createBackupUseCase.invoke(password: password) {
                    switch update {
                    case .progress(let fraction):
                        state = .creatingBackup(progress: fraction)
                    case .done(let url):
                        state = .backupReady(url: url)
                    }
                }
            } catch is CancellationError {
                state = nil
            } catch {
                state = .backupFailed(error)
            }
        }
    }

    func cancel() {
        switch state {
        case .requestingPassword:
            state = nil
        case .creatingBackup:
            backupTask?.cancel()
        case .backupReady:
            // TODO: clean up
            state = nil
        case .backupFailed:
            fatalError("not yet implemented")
        case .none:
            assertionFailure()
        }
    }

    private func updatePublishedProperties() {

        isSetBackupPasswordPresented = if case .requestingPassword = state { true } else { false }

        isCreatingBackupProgressPresented = switch state {

        case .requestingPassword, .creatingBackup, .backupReady: true
        default: false
        }

        isErrorAlertPresented = switch state { case .backupFailed: true default: false }

        backupProgress = switch state { case .creatingBackup(let progress): progress default: nil }

        backupURL = if case .backupReady(let url) = state { url } else { nil }

    }
}

// MARK: - ExportBackupViewModel.State + Properties

private extension ExportBackupState {

    var backupError: (any Error)? {
        if case .backupFailed(let error) = self {
            error
        } else {
            .none
        }
    }
}

// TODO: ?

extension ExportBackupState {
    fileprivate var isEnterBackupPasswordStep: Bool {
        if case .requestingPassword = self { true } else { false }
    }
}
