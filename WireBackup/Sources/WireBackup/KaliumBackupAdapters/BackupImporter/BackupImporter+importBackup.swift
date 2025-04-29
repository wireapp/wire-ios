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

extension BackupImporter {

    func importBackup(
        from backupFile: URL,
        using password: String
    ) async throws -> BackupImportPager {

        let result = try await mpBackupImporter.importFile(multiplatformBackupFilePath: backupFile.path(), passphrase: password)

        switch result {
        case is BackupImportResult.FailureMissingOrWrongPassphrase:
            throw ImportResultError.incorrectPassword
        case is BackupImportResult.FailureParsingFailure:
            throw ImportResultError.parsingFailed
        case let error as BackupImportResult.FailureUnzippingError:
            throw ImportResultError.unzippingFailed(error.message)
        case let success as BackupImportResult.Success:
            return success.pager
        case let error as BackupImportResult.FailureUnknownError:
            throw ImportResultError.unknown(error.message)
        default:
            throw ImportResultError.unexpectedImportResultType
        }
    }

}

private enum ImportResultError: Error {

    case incorrectPassword
    case parsingFailed
    case unzippingFailed(_ description: String)
    case unknown(_ description: String)
    case unexpectedImportResultType

}
