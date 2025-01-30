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
import WireSettingsUI
import WireSyncEngine

struct ExportBackupUseCase: ExportBackupUseCaseProtocol {

    var sessionManager: @Sendable @MainActor () -> SessionManager

    init(sessionManager: @autoclosure @Sendable @MainActor @escaping () -> SessionManager) {
        self.sessionManager = sessionManager
    }

    func invoke(password: String) -> AsyncThrowingStream<ExportBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            Task { @MainActor in
                do {

                    let sessionManager = sessionManager()

                    continuation.yield(.progress(0.5))

                    let url = try await withCheckedThrowingContinuation { continuation in
                        sessionManager.backupActiveAccount(password: password) { result in
                            continuation.resume(with: result)
                        }
                    }

                    continuation.yield(.success(url))
                    continuation.finish()

                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

}

// TODO: delete
extension ExportBackupUseCase: BackupSourceProtocol {

    enum BackupSourceError: Error {
        case missingSessionManager
    }

    func backupActiveAccount(password: String) throws -> URL {
        guard let sessionManager = SessionManager.shared else {
            throw BackupSourceError.missingSessionManager
        }
//        return try sessionManager.backupActiveAccount(password: password)
        fatalError()
    }

    func clearPreviousBackups() {
        SessionManager.shared?.clearPreviousBackups()
    }
}
