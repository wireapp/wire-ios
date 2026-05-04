//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireFoundation

extension BackupImporter {

    func peek(into backupFile: URL) async throws -> PeekResult {

        let result = try await mpBackupImporter.peek(pathToBackupFile: backupFile.path())

        switch result {
        case let result as BackupPeekResult.Success:
            let userIDMatches = try await result.isCreatedBySameUser(userId: BackupQualifiedId(selfUserID)).boolValue
            guard userIDMatches else { throw ImportBackupError.selfUserIDMismatch }
            return PeekResult(result.version, result.isEncrypted)
        case is BackupPeekResult.FailureUnknownFormat:
            throw PeekBackupFileError.unknownFormat
        case let error as BackupPeekResult.FailureUnsupportedVersion:
            throw PeekBackupFileError.unsupportedVersion(error.backupVersion)
        default:
            throw PeekBackupFileError.unexpectedPeekResultType
        }
    }

    struct PeekResult {

        let version: String
        let isEncrypted: Bool

        fileprivate init(_ version: String, _ isEncrypted: Bool) {
            self.version = version
            self.isEncrypted = isEncrypted
        }

    }

    // MARK: -

    enum PeekBackupFileError: Error {

        case unknownFormat
        case unsupportedVersion(_ backupVersion: String)
        case unexpectedPeekResultType

    }

}
