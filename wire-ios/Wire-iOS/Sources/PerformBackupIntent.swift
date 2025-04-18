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
import WireSyncEngine
import Intents
import UniformTypeIdentifiers

enum BackupError: Error, LocalizedError {
    case emptyPassword
    
    var errorDescription: String? {
        switch self {
        case .emptyPassword:
            return "Password cannot be empty."
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
        
        let fileURL = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                SessionManager.shared?.backupActiveAccount(password: password) { result in
                    switch result {
                    case .success(let url):
                        continuation.resume(returning: url)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
        
        return .result(
            value: IntentFile(fileURL: fileURL,
                              filename: fileURL.lastPathComponent,
                              type: UTType("com.wire.backup-ios-underscore")!)
        )
    }
}
