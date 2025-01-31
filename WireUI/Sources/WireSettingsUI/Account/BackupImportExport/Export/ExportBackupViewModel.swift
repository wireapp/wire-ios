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

    @Published private(set) var backupProgress: CreatingBackupProgressModel = .ongoing(0)
    @Published private(set) var backupURL: URL?

    private var backupTask: Task<Void, Never>?

    init(createBackupUseCase: any CreateBackupUseCaseProtocol) {
        self.createBackupUseCase = createBackupUseCase
    }

    func reset() {
        state = nil
    }

    func requestBackupPassword() {
        guard state == nil else { return assertionFailure() }

        state = .requestingPassword(password: "")
    }

    func createBackup(password: String) {
        backupTask?.cancel()

        backupTask = Task {
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
            state = nil
        case .backupReady:
            // TODO: clean up use case?
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

        // TODO: find better workaround for presentation issue
        let isErrorAlertPresented = switch state { case .backupFailed: true default: false }
        if isErrorAlertPresented {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { self.isErrorAlertPresented = true }
        } else {
            self.isErrorAlertPresented = false
        }

        backupProgress = switch state {
        case .creatingBackup(let progress):
            .ongoing(progress)
        case .backupReady(let url):
            .finished(url)
        default:
            .ongoing(0)
        }

    }
}

// MARK: - ExportBackupViewModel.State + Properties

//extension ExportBackupViewModel {
//
//    var backupError: (any Error)? {
//        if case .backupFailed(let error) = state {
//            error
//        } else {
//            .none
//        }
//    }
//}

// TODO: ?

extension ExportBackupState {
    fileprivate var isEnterBackupPasswordStep: Bool {
        if case .requestingPassword = self { true } else { false }
    }
}
