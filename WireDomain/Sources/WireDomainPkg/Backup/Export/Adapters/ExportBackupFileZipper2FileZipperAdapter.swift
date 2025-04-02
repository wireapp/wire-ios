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

final class ExportBackupFileZipper2FileZipperAdapter: FileZipper {

    let fileManager: FileManager
    let fileArchiver: any ExportBackupFileArchiverProtocol

    init(
        fileManager: FileManager,
        fileArchiver: any ExportBackupFileArchiverProtocol
    ) {
        self.fileManager = fileManager
        self.fileArchiver = fileArchiver
    }

    func zip(entries: [String]) throws -> String {
        // create temporary directories
        // TODO: pass incoming reference to determine directory
        let targetDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appending(path: "target", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: targetDirectory, withIntermediateDirectories: true)

        let destinationDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appending(path: "destination", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)

        // generate a filename
        let iso8601Date = Date.ISO8601FormatStyle().format(.now)
        let filename = iso8601Date + "_backup.zip"
        let destinationURL = destinationDirectory.appendingPathComponent(filename, isDirectory: false)

        // copy the files
        // TODO: implement

        // xxx
        try fileArchiver.zipResources(at: targetDirectory, to: destinationURL)

        return destinationURL.path()
    }

}
