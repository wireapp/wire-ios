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
final class ImportBackupViewModel: ObservableObject {

    let importBackupUseCase: any ImportBackupUseCaseProtocol

    private var state: ImportBackupState? {
        didSet { updatePublishedProperties() }
    }

    @Published var alertContent = ImportBackupAlertContent()
    @Published var isAlertPresented = false

    var restoreError: (any Error)? { nil } // TODO: fix

    init(importBackupUseCase: any ImportBackupUseCaseProtocol) {
        self.importBackupUseCase = importBackupUseCase
    }

    func importBackup(from url: URL) {
        Task {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                if .random() {
                    throw SomeError()
                }
            } catch {
                state = .restoreFailed(SomeError())
            }
        }
    }

    private func updatePublishedProperties() {

        /*
        isSetBackupPasswordPresented = if case .enterPassword = state {
            true
        } else {
            false
        }

        isCreatingBackupProgressPresented = switch state {
        case .enterPassword, .creatingBackup, .backupReady:
            true
        default:
            false
        }
         */

        isAlertPresented = switch state { case .restoreFailed: true default: false }

        /*
        backupProgress = switch state {
        case .creatingBackup(let progress):
            progress
        default:
            nil
        }

        backupURL = if case .backupReady(let url) = state {
            url
        } else {
            nil
        }
         */

    }
}

private struct SomeError: LocalizedError {

    var errorDescription: String? { "errorDescription" }

    var failureReason: String? { "failureReason" }

    var recoverySuggestion: String? { "recoverySuggestion" }

    var helpAnchor: String? { "helpAnchor" }

}
