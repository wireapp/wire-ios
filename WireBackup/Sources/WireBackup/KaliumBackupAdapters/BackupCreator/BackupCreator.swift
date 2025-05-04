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
import KaliumBackup
import WireFoundation

/// Abstraction around the multi-platform framework, attempting to improve the interface by using proper types and Swift
/// concurrency and hide the NSObject API.
struct BackupCreator {

    let mpBackupCreator: MPBackupExporter

    init(
        selfUserID: QualifiedID,
        workDirectoryURL: URL,
        outputDirectoryURL: URL,
        fileArchiver: some FileArchiverProtocol
    ) {
        self.mpBackupCreator = MPBackupExporter(
            selfUserId: BackupQualifiedId(selfUserID),
            workDirectory: workDirectoryURL.path(),
            outputDirectory: outputDirectoryURL.path(),
            fileZipper: FileArchiverToFileZipperAdapter(fileArchiver)
        )
    }

}

private final class FileArchiverToFileZipperAdapter<FileArchiver>: FileZipper
    where FileArchiver: FileArchiverProtocol {

    let fileArchiver: FileArchiver

    init(_ fileArchiver: FileArchiver) {
        self.fileArchiver = fileArchiver
    }

    func zip(entries: [String]) throws -> String {

        let targetURLs = entries.map { entry in
            URL(filePath: entry, directoryHint: .notDirectory)
        }

        // create temporary directory for the destination file
        let destinationDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)

        // create zip file
        let destinationURL = destinationDirectory.appendingPathComponent("backup.zip", isDirectory: false)
        try fileArchiver.zipResources(at: targetURLs, into: destinationURL)

        return destinationURL.path()

    }

}
