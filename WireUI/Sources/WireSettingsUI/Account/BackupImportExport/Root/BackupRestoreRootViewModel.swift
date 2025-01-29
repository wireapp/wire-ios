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
final class BackupRestoreRootViewModel: ObservableObject {

    private var state: State? {
        didSet { updatePublishedProperties() }
    }

    // BackupProgress is the outer sheet, which contains/presents SetBackupPassword
    @Published var isBackupProgressPresented = false
    @Published var isSetBackupPasswordPresented = false
    @Published var isErrorAlertPresented = false

    @Published private(set) var backupProgress: Float?
    @Published private(set) var backupURL: URL?
    var backupError: (any Error)? { state?.backupError }

    private var backupTask: Task<Void, any Error>?

    func requestBackupPassword() {
        guard state == nil else { return assertionFailure() }

        state = .backup(.enterPassword())
    }

    func createBackup(password: String) {
        guard backupTask == nil else { return assertionFailure() }

        backupTask = Task {
            defer { backupTask = nil }
            do {

                // TODO: backup use case

                state = .backup(.creatingBackup(progress: 0))
                try? await Task.sleep(for: .seconds(0.5))
                if Task.isCancelled { throw CancellationError() }
                state = .backup(.creatingBackup(progress: 0.25))
                try? await Task.sleep(for: .seconds(0.5))
                if Task.isCancelled { throw CancellationError() }
                state = .backup(.creatingBackup(progress: 0.5))
                try? await Task.sleep(for: .seconds(0.5))
                if Task.isCancelled { throw CancellationError() }
                state = .backup(.creatingBackup(progress: 0.75))

                if Bool.random() {
                    throw NSError(domain: "some", code: 0, userInfo: nil)
                }

                try? await Task.sleep(for: .seconds(0.5))
                if Task.isCancelled { throw CancellationError() }
                state = .backup(.creatingBackup(progress: 1))
                try? await Task.sleep(for: .seconds(0.2))
                if Task.isCancelled { throw CancellationError() }
                let url = URL(fileURLWithPath: "/")
                state = .backup(.backupReady(url: url))
            } catch is CancellationError {
                state = nil
            } catch {
                state = .backup(.backupFailed(error))
            }
        }
    }

    func cancel() {
        switch state {
        case .backup(.enterPassword):
            state = nil
        case .backup(.creatingBackup):
            backupTask?.cancel()
        case .backup(.backupReady):
            // TODO: clean up
            state = nil
        case .backup(.backupFailed(_)):
            fatalError("not yet implemented")
        case .restore:
            fatalError("not yet implemented")
        case .none:
            assertionFailure()
        }
    }

    private func updatePublishedProperties() {

        isSetBackupPasswordPresented = if case .backup(.enterPassword) = state {
            true
        } else {
            false
        }

        isBackupProgressPresented = switch state {
        case .backup(.enterPassword), .backup(.creatingBackup), .backup(.backupReady):
            true
        default:
            false
        }

        isErrorAlertPresented = switch state {
        case .backup(.backupFailed):
            true
        default:
            false
        }

        backupProgress = switch state {
        case .backup(.creatingBackup(let progress)):
            progress
        default:
            nil
        }

        backupURL = if case .backup(.backupReady(let url)) = state {
            url
        } else {
            nil
        }

    }
}

// MARK: - BackupRestoreRootViewModel + State

extension BackupRestoreRootViewModel {

    enum State {
        case backup(BackupStep)
        case restore

        enum BackupStep {
            case enterPassword(password: String = "")
            case creatingBackup(progress: Float)
            case backupReady(url: URL)
            case backupFailed(any Error)
        }
    }
}

// MARK: - BackupRestoreRootViewModel.State + Properties

private extension BackupRestoreRootViewModel.State {

    var backupError: (any Error)? {
        if case .backup(.backupFailed(let error)) = self {
            error
        } else {
            .none
        }
    }
}
