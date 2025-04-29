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

import WireBackup
import WireDomainPackage
import WireSettingsUI
import WireSyncEngine

// Instead of adding WireBackup as a dependency of WireUI, the use case, progress and error types exist twice and this
// adapter bridges between them.

struct CreateBackupUseCaseAdapter: WireSettingsUI.CreateBackupUseCaseProtocol {

    let createBackupUseCase: WireBackup.CreateBackupUseCaseProtocol

    init(_ createBackupUseCase: WireBackup.CreateBackupUseCaseProtocol) {
        self.createBackupUseCase = createBackupUseCase
    }

    func invoke(password: String) -> AsyncThrowingStream<WireSettingsUI.CreateBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task<Void, Never> {
                do {
                    for try await update in createBackupUseCase.invoke(password: password) {
                        switch update {
                        case let .progress(current, total):
                            continuation.yield(.progress(current, total))
                        case let .done(url):
                            continuation.yield(.done(url))
                        }
                    }
                    continuation.finish()
                } catch let error as WireBackup.CreateBackupError {
                    continuation.finish(throwing: WireSettingsUI.CreateBackupError(error))
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

}

extension WireSettingsUI.CreateBackupProgress {

    init(_ result: WireBackup.CreateBackupProgress) {
        switch result {
        case let .progress(current, total):
            self = .progress(current, total)
        case let .done(url):
            self = .done(url)
        }
    }

}

extension WireSettingsUI.CreateBackupError {

    init(_ error: WireBackup.CreateBackupError) {
        switch error {
        case .todo:
            self = .todo
        }
    }

}
