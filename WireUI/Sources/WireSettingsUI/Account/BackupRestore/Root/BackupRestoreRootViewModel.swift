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

final class BackupRestoreRootViewModel: ObservableObject {

    private var state: State? {
        didSet { updatePublishedProperties() }
    }

    @Published var isSetBackupPasswordVisible = false
    @Published var isBackupProgressVisible = false
    @Published private(set) var backupProgress: Float?

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

    func startBackupProcess() {
        guard state == nil else { return }

        state = .backup(.enterPassword())
    }

    func createBackup(password: String) {
        state = .backup(.creatingBackup(progress: 0.25))
    }

    func cancel() {
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
