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

struct BackupSource: BackupSourceProtocol, ExportBackupUseCaseProtocol {

    // TODO: remove
    enum BackupSourceError: Error {
        case missingSessionManager
    }

    // TODO: remove
    func backupActiveAccount(password: String) throws -> URL {
        guard let sessionManager = SessionManager.shared else {
            throw BackupSourceError.missingSessionManager
        }
//        return try sessionManager.backupActiveAccount(password: password)
        fatalError()
    }

    // TODO: remove
    func clearPreviousBackups() {
        SessionManager.shared?.clearPreviousBackups()
    }

    var sessionManager: () -> SessionManager

    init(sessionManager: @autoclosure @escaping () -> SessionManager) {
        self.sessionManager = sessionManager
    }

    @MainActor
    func invoke(
        password: String,
        export: @escaping (_ url: URL) async -> Void
    ) async throws {
        let sessionManager = sessionManager()

        let url = try await withCheckedThrowingContinuation { continuation in
            sessionManager.backupActiveAccount(password: password) { result in
                continuation.resume(with: result)
            }
        }
        await export(url)
        sessionManager.clearPreviousBackups()
    }

}
