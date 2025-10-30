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

import UIKit
import WireCommonComponents
import WireDomain
import WireLogging
import WireSyncEngine
import WireSystem
import ZIPFoundation

/// Generates log files archives.
///
/// All logs are stored at the `NSTemporaryDirectory` URL (`tmp`) in the folder `/<uuid>/logs/`.
///
/// When generating the logs archive, we create a unique directory for the archive in `/<uuid>/logs/<uuid>/logs.zip`.
///
/// The logs folder `/<uuid>/logs/` is cleared:
///  - after `generateLogFilesData()` returns
///  - when calling `generateLogFilesZip()`, before the archive is created
///  - when calling `clearLogsDirectory()`
///
/// In each logs archive, an extra file `info.txt` is added. It contains general information about the app.
///
struct LogFilesProvider: LogFilesProviding {

    // MARK: - Types

    enum Error: Swift.Error {
        case noLogs(description: String)
    }

    // MARK: - Properties

    private let logsDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .appendingPathComponent("logs", isDirectory: true)

    private var logFilesURLs: [URL] {
<<<<<<< HEAD
        let fileManager = FileManager.default
        var urls = ZMSLog.pathsForExistingLogs

        // add the root directory of the app, NSE and SE logs
        if let appGroupIdentifier = Bundle.main.applicationGroupIdentifier,
           let sharedLogsDirectoryURL = fileManager.sharedLogsDirectoryURL(for: appGroupIdentifier) {
            let targetLogDirectories = try? fileManager.contentsOfDirectory(
                at: sharedLogsDirectoryURL,
                includingPropertiesForKeys: .none
            )
            urls.append(contentsOf: targetLogDirectories ?? [])
        }

=======
        var urls = WireLogger.logFiles // TODO: inject FileLoggerProtocol providing a logFiles property
        urls.append(contentsOf: ZMSLog.pathsForExistingLogs)
>>>>>>> 1f47bea48a (refactor: logging using string interpolation - WPB-14297 squashed)
        return urls
    }

    // MARK: - Interface

    func generateLogFilesData() throws -> Data {
        let fileManager = FileManager.default
        defer {
            try? clearLogsDirectory(fileManager: fileManager)
        }

        let logFilesURL = try generateLogFilesZip()
        return try Data(contentsOf: logFilesURL)
    }

    func generateLogFilesZip() throws -> URL {
        let fileManager = FileManager.default
        try? clearLogsDirectory(fileManager: fileManager)

        // Determine files to export
        let logFilesURLs = logFilesURLs
        guard !logFilesURLs.isEmpty else {
            throw Error.noLogs(description: logFilesURLs.description)
        }

        // Re-create the base directory
        try fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

        // Create a subfolder for the current session
        let archiveFolder = logsDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: archiveFolder, withIntermediateDirectories: true)

        // Create the info file
        _ = try createInfoFile(at: archiveFolder)

        // Copy files to be zipped
        for logFilesURL in logFilesURLs {
            let copy = archiveFolder.appending(path: logFilesURL.lastPathComponent, directoryHint: .notDirectory)
            try fileManager.copyItem(at: logFilesURL, to: copy)
        }

        // Create the zip file
        let zipURL = logsDirectory.appendingPathComponent("logs.zip")
        try fileManager.zipItem(at: archiveFolder, to: zipURL, shouldKeepParent: false, compressionMethod: .deflate)

        // Clean up
        try fileManager.removeItem(at: archiveFolder)

        return zipURL
    }

    func clearLogsDirectory(fileManager: FileManager) throws {
        if fileManager.fileExists(atPath: logsDirectory.path) {
            try fileManager.removeItem(at: logsDirectory)
        }
    }

    func removeLogFiles(fileManager: FileManager) throws {
        for fileURL in logFilesURLs {
            try fileManager.removeItem(at: fileURL)
        }
    }

    // MARK: - Helpers

    func info(includingJournal: Bool = false) -> String {
        let date = Date()

        var body = """
        App Version: \(Bundle.main.appInfo.fullVersion)
        Bundle id: \(Bundle.main.bundleIdentifier ?? "-")
        Device: \(UIDevice.current.zm_model())
        iOS version: \(UIDevice.current.systemVersion)
        Date: \(date.transportString())
        """

        if includingJournal {
            body += "\n\nJournal:\n\(journalInfos())"
        }

        if let datadogUserIdentifier = WireAnalytics.Datadog.userIdentifier {
            // display only when enabled
            body.append("\nDatadog ID: \(datadogUserIdentifier)")
        }
        return body
    }

    private func journalInfos() -> String {
        guard let selfUserID = ZMUserSession.shared()?.selfUser.remoteIdentifier else {
            return "Not Available"
        }

        let journal = Journal(
            userID: selfUserID,
            storage: UserDefaults.shared()
        )

        return journal.values().compactMap { "\($0): \($1)" }.joined(separator: "\n")
    }

    private func createInfoFile(at url: URL) throws -> URL {
        let infoFileURL = url.appendingPathComponent("info.txt")

        let info = self.info(includingJournal: true)
        try info.write(
            to: infoFileURL,
            atomically: true,
            encoding: .utf8
        )

        return infoFileURL
    }

    /// Deletes all log-related archives and folders created in the temp directory.
    /// This includes any leftover directories that match the pattern used in `logsDirectory`.
    func removeLegacyLogArchives() throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileManager = FileManager.default

        let contents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)

        for url in contents {
            // The `logsDirectory` structure is /tmp/<UUID>/logs
            let logsSubdir = url.appendingPathComponent("logs")
            var isDirectory: ObjCBool = false

            if fileManager.fileExists(atPath: logsSubdir.path, isDirectory: &isDirectory),
               isDirectory.boolValue {
                try fileManager.removeItem(at: url)
            }
        }
    }

}
