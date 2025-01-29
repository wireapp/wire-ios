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

    @Published var isSetBackupPasswordVisible = false
    @Published var isBackupProgressVisible = false
    @Published private(set) var backupProgress: Float?

    private var backupTask: Task<Void, any Error>?

    enum State {
        case backup(BackupStep)
        case restore

        enum BackupStep {
            case enterPassword(password: String = "")
            case creatingBackup(progress: Float)
            case backupReady
            case backupFailed(any Error)
        }
    }

    func requestBackupPassword() {
        guard state == nil else { return }

        state = .backup(.enterPassword())
    }

    func createBackup(password: String) {
        backupTask = Task {
            state = .backup(.creatingBackup(progress: 0))
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { throw CancellationError() }
            state = .backup(.creatingBackup(progress: 0.25))
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { throw CancellationError() }
            state = .backup(.creatingBackup(progress: 0.5))
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { throw CancellationError() }
            state = .backup(.creatingBackup(progress: 0.75))
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { throw CancellationError() }
            state = .backup(.creatingBackup(progress: 1))
            try? await Task.sleep(for: .seconds(0.2))
            if Task.isCancelled { throw CancellationError() }
            state = .backup(.backupReady)
        }
    }

    func cancel() {
        backupTask?.cancel()
        state = nil
    }

    private func updatePublishedProperties() {

        isSetBackupPasswordVisible = if case .backup(.enterPassword) = state {
            true
        } else {
            false
        }

        isBackupProgressVisible = switch state {
        case .backup(.creatingBackup), .backup(.backupReady):
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

    }
}
