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
import WireDomainPackage
import WireFoundation
import WireSettingsUI
import WireSyncEngine

// TODO: [WPB-14592] clean up everything around the legacy backup creation

/// Use case for creating a backup file which can only used by iOS apps.
struct CreateLegacyBackupUseCase: CreateBackupUseCaseProtocol {

    var sessionManager: @Sendable @MainActor () -> SessionManager

    init(sessionManager: @autoclosure @Sendable @MainActor @escaping () -> SessionManager) {
        self.sessionManager = sessionManager
    }

    func invoke(password: String) -> AsyncThrowingStream<CreateBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            Task<Void, Never> { @MainActor in
                do {

                    let sessionManager = sessionManager()

                    continuation.yield(.progress(BackupProgress(current: 1, total: 2)))
                    let url = try await sessionManager.backupActiveAccount(password: password)
                    continuation.yield(.done(url))
                    continuation.finish()

                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

}
