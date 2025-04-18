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

import AppIntents
import Foundation
import Intents
import UniformTypeIdentifiers
import WireSyncEngine

enum BackupError: Error, LocalizedError {
    case emptyPassword
    case noSessionManager
    case noBackupFile

    var errorDescription: String? {
        switch self {
        case .emptyPassword:
            "Password cannot be empty."
        case .noSessionManager:
            "no SessionManager."
        case .noBackupFile:
            "no backup file"
        }
    }
}

struct PerformBackupIntent: AppIntent {
    static var title: LocalizedStringResource = "Perform Backup"

    @Parameter(title: "Password")
    var password: String

    static var description: IntentDescription {
        IntentDescription("Perform a backup with the provided password.")
    }

    func perform() async throws -> some ReturnsValue<IntentFile> {
        if password.isEmpty {
            throw BackupError.emptyPassword
        }

        guard let sessionManager = SessionManager.shared else {
            throw BackupError.noSessionManager
        }

        var fileURL: URL?
        let useCase = CreateLegacyBackupUseCase(sessionManager: sessionManager)
        for try await update in useCase.invoke(password: password) {
            switch update {
            case let .progress(fraction):
                break
            case let .done(url):
                fileURL = url
            }
        }
        guard let fileURL else {
            throw BackupError.noBackupFile
        }
        return .result(
            value: IntentFile(
                fileURL: fileURL,
                filename: fileURL.lastPathComponent,
                type: UTType("com.wire.backup-ios-underscore")!
            )
        )
    }
}
