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

extension MPBackupExporter {

    func finalize(password: String) async throws -> URL {
        let password = if password.isEmpty { String?.none } else { password }

        let result = await asyncResult(for: finalize(password: password))
        let backupResult: any BackupExportResult
        switch result {
        case .failure(let error):
            throw error
        case .success(let result):
            backupResult = result
        }

        switch backupResult {
        case let success as BackupExportResultSuccess:
            return URL(filePath: success.pathToOutputFile, directoryHint: .notDirectory)
        case let ioError as BackupExportResultFailureIOError:
            throw FinalizeBackupError.ioError(ioError.message)
        case let zipError as BackupExportResultFailureZipError:
            throw FinalizeBackupError.zipError(zipError.message)
        case let otherFailure as any BackupExportResultFailure:
            throw FinalizeBackupError.otherFailure(otherFailure.message)
        default:
            throw FinalizeBackupError.unexpectedResultType
        }
    }
}

enum FinalizeBackupError: Error {
    case success(_ outputFile: String)
    case ioError(_ message: String)
    case zipError(_ message: String)
    case otherFailure(_ message: String)
    case unexpectedResultType
}
