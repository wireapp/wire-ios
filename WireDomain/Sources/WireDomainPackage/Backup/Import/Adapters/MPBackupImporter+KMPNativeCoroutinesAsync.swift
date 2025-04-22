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

import KMPNativeCoroutinesAsync
@preconcurrency import WireBackup

extension MPBackupImporter {

    func peek(into backupFile: URL) async throws -> (version: String, isEncrypted: Bool) {

        let result = await asyncResult(for: peek(pathToBackupFile: backupFile.path()))
        let peekResult: BackupPeekResult
        switch result {
        case .failure(let error):
            throw error
        case .success(let result):
            peekResult = result
        }

        switch peekResult {
        case let result as BackupPeekResult.Success:
            return (result.version, result.isEncrypted)
        case is BackupPeekResult.FailureUnknownFormat:
            throw PeekResultError.unknownFormat
        case let error as BackupPeekResult.FailureUnsupportedVersion:
            throw PeekResultError.unsupportedVersion(error.backupVersion)
        default:
            throw PeekResultError.unexpectedPeekResultType
        }
    }
}

enum PeekResultError: Error {
    case unknownFormat
    case unsupportedVersion(_ backupVersion: String)
    case unexpectedPeekResultType
}
