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

import SwiftUI

@MainActor
public final class BackupRestoreViewModel: ObservableObject {
    
    /// `nil` means no backup is in progress.
    @Published private(set) var backupProgress: Float?

    private let backupSource: any BackupSourceProtocol
    private let restoreSource: any RestoreSourceProtocol
    private let backupResultHandler: BackupResultHandler
    private let restoreBackupResultHandler: RestoreBackupResultHandler

    private let exportBackupUseCase: any ExportBackupUseCaseProtocol

    public init(
        exportBackupUseCase: any ExportBackupUseCaseProtocol
    ) {
        self.exportBackupUseCase = exportBackupUseCase

        // TODO: fix
        backupSource = DummyBackupSource()
        restoreSource = DummyRestoreSource()
        backupResultHandler = .init(onSuccess: { _, _ in fatalError() }, onFailure: {})
        restoreBackupResultHandler = .init(onSuccess: {}, onConfirmation: { _ in }, onFailure: {})

        struct DummyBackupSource: BackupSourceProtocol {
            func backupActiveAccount(password: String) throws -> URL { fatalError() }
            func clearPreviousBackups() { fatalError() }
        }
        struct DummyRestoreSource: RestoreSourceProtocol {
            func restoreFromBackup(at: URL, password: String, completion: @escaping (Result<Void, any Error>) -> Void) { fatalError() }
        }
    }

    public init(
        backupSource: any BackupSourceProtocol,
        restoreSource: any RestoreSourceProtocol,
        backupResultHandler: BackupResultHandler,
        restoreBackupResultHandler: RestoreBackupResultHandler
    ) {
        exportBackupUseCase = DummyExportBackupUseCase()

        self.backupSource = backupSource
        self.restoreSource = restoreSource
        self.backupResultHandler = backupResultHandler
        self.restoreBackupResultHandler = restoreBackupResultHandler

        struct DummyExportBackupUseCase: ExportBackupUseCaseProtocol {
            func invoke(password: String) async throws -> URL { fatalError() }
        }
    }

    func backupActiveAccount(
        password: String,
        export: @MainActor @escaping (_ url: URL) async -> Void
    ) {
        // TODO: activity indicator with progress
        Task {
            do {
                try await exportBackupUseCase.invoke(password: password) // , export: export)
            } catch {
                fatalError("TODO")
                /*backupResultHandler.onFailure()*/
            }
        }
    }

    func restoreFromBackup(
        at location: URL,
        password: String,
        completion: @escaping (Result<Void, any Error>) -> Void
    ) {
        restoreSource.restoreFromBackup(at: location, password: password) { result in
            completion(result)
            switch result {
            case .success:
                self.restoreBackupResultHandler.onSuccess()
            case .failure:
                self.restoreBackupResultHandler.onFailure()
            }
        }
    }

    func confirmBackupRestore(completion: @escaping () -> Void) {
        restoreBackupResultHandler.onConfirmation {
            completion()
        }
    }
}
