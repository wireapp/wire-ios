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
    case noSessionManager
    case noBackupFile
    
    var errorDescription: String? {
        switch self {
        case .emptyPassword:
            return "Password cannot be empty."
        case .noSessionManager:
            return "no SessionManager."
        case .noBackupFile:
            return "no backup file"
        }
    }
}

struct SwitchAccountIntent: AppIntent {
    static var title: LocalizedStringResource = "Select Account"
    
    
    
    func perform() async throws -> some IntentDialog {
        
        return .result(opensIntent: PerformBackupIntent(account: <#T##IntentParameter<String>#>), dialog: .)
    }
    
    
}

class SelectAccountIntentHandler: NSObject, SelectAccountIntentHandling {
    
    func resolveAccount(for intent: SelectAccountIntent, with completion: @escaping (INObjectResolutionResult) -> Void) {
        let accounts = fetchAccounts() // Fetch accounts from your data source
        
        let accountObjects = accounts.map { account in
            INObject(identifier: account.id, display: account.name)
        }

        if accountObjects.isEmpty {
            completion(.unsupported(reason: "No accounts available."))
        } else if accountObjects.count == 1 {
            completion(.success(with: accountObjects.first!))
        } else {
            completion(.disambiguation(with: accountObjects))
        }
    }
    
    private func fetchAccounts() -> [Account] {
        return [
            Account(id: "1", name: "Personal"),
            Account(id: "2", name: "Work"),
            Account(id: "3", name: "Savings")
        ]
    }
}

struct Account {
    let id: String
    let name: String
}


struct PerformBackupIntent: AppIntent {
    static var title: LocalizedStringResource = "Perform Backup"
    
    @Parameter(title: "Account")
    var account: String
    
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
            throw BackupError.emptyPassword
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
            value: IntentFile(fileURL: fileURL,
                              filename: fileURL.lastPathComponent,
                              type: UTType("com.wire.backup-ios-underscore")!)
        )
    }
}
