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

/// Abstraction of the multi-platform framework, attempting to improve the interface by using proper types and Swift
/// concurrency and hide the NSObject API.
struct BackupCreator {

    private let mpBackupCreator: MPBackupExporter

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

    func addUser(_ user: UserBackupModel) {
        mpBackupCreator.add(user: BackupUser(user))
    }

    func addConversation(_ conversation: ConversationBackupModel) {
        mpBackupCreator.add(conversation: BackupConversation(conversation))
    }

    func addMessage(_ message: MessageBackupModel) {
        mpBackupCreator.add(message: BackupMessage(message))
    }

    func finalize(password: String) async throws -> URL {

        let result: any BackupExportResult = try await mpBackupCreator.finalize(password: password)

        switch result {
        case let success as BackupExportResultSuccess:
            return URL(filePath: success.pathToOutputFile, directoryHint: .notDirectory)
        case let ioError as BackupExportResultFailureIOError:
            throw FinalizeBackupFileError.ioError(ioError.message)
        case let zipError as BackupExportResultFailureZipError:
            throw FinalizeBackupFileError.zipError(zipError.message)
        default:
            throw FinalizeBackupFileError.unexpectedResultType
        }

    }

    // MARK: -

    enum FinalizeBackupFileError: Error {

        case success(_ outputFile: String)
        case ioError(_ message: String)
        case zipError(_ message: String)
        case unexpectedResultType

    }

}

// MARK: -

private final class FileArchiverToFileZipperAdapter<FileArchiver>: FileZipper
    where FileArchiver: FileArchiverProtocol {

    let fileArchiver: FileArchiver

    init(_ fileArchiver: FileArchiver) {
        self.fileArchiver = fileArchiver
    }

    func zip(entries: [String], outputDirectory: OkioPath) throws -> String {

        let outputDirectory = outputDirectory.segments.reduce(URL(fileURLWithPath: "/")) { url, component in
            url.appendingPathComponent(component)
        }
        let targetURLs = entries.map { entry in
            URL(filePath: entry, directoryHint: .notDirectory)
        }
        let destinationURL = outputDirectory.appendingPathComponent("backup.zip", isDirectory: false)

        try fileArchiver.zipResources(at: targetURLs, into: destinationURL)

        return destinationURL.path()

    }

}
