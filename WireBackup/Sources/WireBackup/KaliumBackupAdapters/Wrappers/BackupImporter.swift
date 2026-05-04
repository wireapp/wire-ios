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
import KaliumBackup
import WireFoundation
import WireUtilitiesPackage

struct BackupImporter {

    let mpBackupImporter: MPBackupImporter
    let selfUserID: QualifiedID

    init(
        selfUserID: QualifiedID,
        workDirectoryURL: URL,
        fileUnarchiver: some FileUnarchiverProtocol
    ) {
        self.selfUserID = selfUserID
        self.mpBackupImporter = MPBackupImporter(
            pathToWorkDirectory: workDirectoryURL.path(),
            backupFileUnzipper: FileUnarchiverToBackupFileUnzipper(fileUnarchiver: fileUnarchiver)
        )
    }

}

// MARK: -

private final class FileUnarchiverToBackupFileUnzipper: BackupFileUnzipper {

    let fileUnarchiver: any FileUnarchiverProtocol

    init(fileUnarchiver: any FileUnarchiverProtocol) {
        self.fileUnarchiver = fileUnarchiver
    }

    func unzipBackup(zipPath: String) throws -> String {

        let archiveURL = URL(filePath: zipPath, directoryHint: .notDirectory)
        let destinationDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)

        try fileUnarchiver.unzipFile(at: archiveURL, to: destinationDirectory)
        return destinationDirectory.path()

    }

}
