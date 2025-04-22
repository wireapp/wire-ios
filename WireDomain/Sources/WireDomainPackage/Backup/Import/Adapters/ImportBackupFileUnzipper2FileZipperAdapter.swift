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
import WireBackup
import WireFoundation

final class ImportBackupFileArchiverToBackupFileUnzipper: BackupFileUnzipper {

    let fileManager: FileManager
    let fileArchiver: any ImportBackupFileArchiverProtocol

    init(
        fileManager: FileManager,
        fileArchiver: any ImportBackupFileArchiverProtocol
    ) {
        self.fileManager = fileManager
        self.fileArchiver = fileArchiver
    }

    func unzipBackup(zipPath: String) -> String { // TODO: add throws

        let archiveURL = URL(filePath: zipPath, directoryHint: .notDirectory)
        let destinationDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try! fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true) // TODO: throw error

        try! fileArchiver.unzipFile(at: archiveURL, to: destinationDirectory) // TODO: throw error
        return destinationDirectory.path()
    }

}
