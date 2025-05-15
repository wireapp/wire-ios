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
@preconcurrency import KaliumBackup

struct BackupFile: Encodable {

    let peekResult: PeekResult
    let importResult: ImportResult

    init(
        path backupFilePath: String,
        password: String
    ) async throws {

        let backupImporter = MPBackupImporter(
            pathToWorkDirectory: NSTemporaryDirectory(),
            backupFileUnzipper: ZIPFoundationBackupFileUnzipper()
        )

        let peekResult = try await backupImporter.peek(pathToBackupFile: backupFilePath)
        guard let peekResult = peekResult as? BackupPeekResult.Success else {
            throw InitializationError.some("Peek failed: \(peekResult)")
        }

        guard !peekResult.isEncrypted else {
            throw InitializationError.some("Encrypted files are not yet supported.")
        }

        let importResult = try await backupImporter.importFile(
            multiplatformBackupFilePath: backupFilePath,
            passphrase: password.isEmpty ? String?.none : password
        )
        guard let importResult = importResult as? BackupImportResult.Success else {
            throw InitializationError.some("Import failed: \(importResult)")
        }

        self.peekResult = PeekResult(peekResult)
        self.importResult = try ImportResult(importResult)

    }

    enum InitializationError: Error {
        case some(_ description: String)
    }

}
