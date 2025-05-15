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

    private let peekResult: PeekResult
    private let importResult: ImportResult

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
            throw InitializationError.some("Peek failed.")
        }

        let importResult = try await backupImporter.importFile(
            multiplatformBackupFilePath: backupFilePath,
            passphrase: password.isEmpty ? String?.none : password
        )
        guard let importResult = importResult as? BackupImportResult.Success else {
            throw InitializationError.some("Import failed.")
        }

        self.peekResult = PeekResult(peekResult)
        self.importResult = ImportResult(importResult)

    }

    enum InitializationError: Error {
        case some(_ description: String)
    }

}

/*


print("version:", peekResult.version, to: &stderr)
print("isEncrypted:", peekResult.isEncrypted, to: &stderr)
guard !peekResult.isEncrypted else {
    print("Encrypted files are not yet supported.", to: &stderr)
    exit(3)
}



let pagers = importResult.pager
print("totalPagesCount:", pagers.totalPagesCount, to: &stderr)

guard let userPager = pagers.usersPager as? BackupImportDataPager<BackupUser> else {
    print("Unexpected user pager type:", String(describing: pagers.usersPager), to: &stderr)
    exit(5)
}
guard let conversationsPager = pagers.conversationsPager as? BackupImportDataPager<BackupConversation> else {
    print("Unexpected conversation pager type:", String(describing: pagers.conversationsPager), to: &stderr)
    exit(5)
}
guard let messagesPager = pagers.messagesPager as? BackupImportDataPager<BackupMessage> else {
    print("Unexpected message pager type:", String(describing: pagers.messagesPager), to: &stderr)
    exit(5)
}

for _ in 0 ..< userPager.totalPages {
    let users = userPager.nextPage()
    for u in 0 ..< users.size {
        let user = users.get(index: u)!

    }
}

for _ in 0 ..< conversationsPager.totalPages {
    //
}

for _ in 0 ..< messagesPager.totalPages {
    //
}

*/
