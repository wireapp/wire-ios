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
import WireLogging
import WireSyncEngine
import WireSystem
import ZipArchive

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

    private var logsDirectory: URL = {
        let baseURL = URL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
        )
        return baseURL
            .appendingPathComponent("logs", isDirectory: true)
    }()

    private var logFilesURLs: [URL] {
        var urls = WireLogger.logFiles
        urls.append(contentsOf: ZMSLog.pathsForExistingLogs)
        return urls
    }

    // MARK: - Interface

    func generateLogFilesData() throws -> Data {
        defer {
            try? clearLogsDirectory()
        }

        let logFilesURL = try generateLogFilesZip()
        return try Data(contentsOf: logFilesURL)
    }

    func generateLogFilesZip() throws -> URL {
        try? clearLogsDirectory()

        // Re-create the base directory
        try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

        // Create a subfolder for the current session
        let archiveFolder = logsDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: archiveFolder, withIntermediateDirectories: true)

        // Create the info file
        let infoFileURL = try createInfoFile(at: archiveFolder)

        // Set the list of files to be zipped
        let filesToZip = try filesToZipURLs(
            logFilesURLs: logFilesURLs,
            infoFileURL: infoFileURL
        )

        // Create the zip file
        let zipURL = archiveFolder.appendingPathComponent("logs.zip")
        SSZipArchive.createZipFile(
            atPath: zipURL.path,
            withFilesAtPaths: filesToZip.map(\.path)
        )

        return zipURL
    }

    func clearLogsDirectory() throws {
        if FileManager.default.fileExists(atPath: logsDirectory.path) {
            try FileManager.default.removeItem(at: logsDirectory)
        }
    }

    func removeLogFiles() throws {
        for fileURL in logFilesURLs {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    // MARK: - Helpers

    private func filesToZipURLs(logFilesURLs: [URL], infoFileURL: URL) throws -> [URL] {
        guard !logFilesURLs.isEmpty else {
            throw Error.noLogs(description: logFilesURLs.description)
        }

        return logFilesURLs + [infoFileURL]
    }

    var info: String {
        let date = Date()

        var body = """
        App Version: \(Bundle.main.appInfo.fullVersion)
        Bundle id: \(Bundle.main.bundleIdentifier ?? "-")
        Device: \(UIDevice.current.zm_model())
        iOS version: \(UIDevice.current.systemVersion)
        Date: \(date.transportString())
        """

        if let datadogUserIdentifier = WireAnalytics.Datadog.userIdentifier {
            // display only when enabled
            body.append("\nDatadog ID: \(datadogUserIdentifier)")
        }
        return body
    }

    private func createInfoFile(at url: URL) throws -> URL {
        let infoFileURL = url.appendingPathComponent("info.txt")

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
