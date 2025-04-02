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

final class ExportBackupFileZipper2FileZipperAdapter: FileZipper {

    let fileManager: FileManager
    let fileArchiver: any ExportBackupFileArchiverProtocol
    let currentDateProvider: any CurrentDateProviding

    init(
        fileManager: FileManager,
        fileArchiver: any ExportBackupFileArchiverProtocol,
        currentDateProvider: any CurrentDateProviding
    ) {
        self.fileManager = fileManager
        self.fileArchiver = fileArchiver
        self.currentDateProvider = currentDateProvider
    }

    func zip(entries: [String]) throws -> String {

        let targetURLs = entries.map { entry in
            URL(filePath: entry, directoryHint: .notDirectory)
        }

        // create temporary directory for the destination file
        let destinationDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appending(path: "destination", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)

        // generate a filename
        let iso8601Date = Date.ISO8601FormatStyle().format(currentDateProvider.now)
        let filename = iso8601Date + "_backup.zip"
        let destinationURL = destinationDirectory.appendingPathComponent(filename, isDirectory: false)

        // call zip library
        try fileArchiver.zipResources(at: targetURLs, into: destinationURL)

        return destinationURL.path()

    }

}
