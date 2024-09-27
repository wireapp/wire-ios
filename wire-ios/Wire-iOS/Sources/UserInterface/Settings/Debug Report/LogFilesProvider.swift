//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireSystem
import ZipArchive

// MARK: - LogFilesProviding

// sourcery: AutoMockable
protocol LogFilesProviding {
    /// Generates a zip file containing all log files and returns its data before removing the files
    ///
    /// - Returns: the log files archive data

    func generateLogFilesData() throws -> Data

    /// Generates a zip file containing all log files
    ///
    /// - Returns: the log files archive URL

    func generateLogFilesZip() throws -> URL

    /// Clears the logs directory.
    /// Call once you are done using the URL returned by `generateLogFilesZip` to clean up.

    func clearLogsDirectory() throws
}

// MARK: - LogFilesProvider

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
    // MARK: Internal

    // MARK: - Types

    enum Error: Swift.Error {
        case noLogs(description: String)
    }

    // MARK: - Interface

    func generateLogFilesData() throws -> Data {
        defer {
            // because we don't rotate file for this one, we clean it once sent
            // this regenerated from os_log anyway
            if let url = LogFileDestination.main.log {
                try? FileManager.default.removeItem(at: url)
            }
            try? clearLogsDirectory()
        }

        let logFilesURL = try generateLogFilesZip()
        let data = try Data(contentsOf: logFilesURL)

        return data
    }

    func generateLogFilesZip() throws -> URL {
        try? clearLogsDirectory()

        // Create a unique directory
        var url = try createUniqueLogDirectory()

        // Create the info file
        let infoFileURL = try createInfoFile(at: url)

        // Set the list of files to be zipped
        let filesToZip = try filesToZipURLs(
            logFilesURLs: logFilesURLs,
            infoFileURL: infoFileURL
        )

        // Create the zip file
        url.appendPathComponent("logs.zip")
        SSZipArchive.createZipFile(
            atPath: url.path,
            withFilesAtPaths: filesToZip.map(\.path)
        )

        return url
    }

    func clearLogsDirectory() throws {
        try FileManager.default.removeItem(atPath: logsDirectory.path)
    }

    // MARK: Private

    // MARK: - Properties

    private var logsDirectory: URL = {
        let baseURL = URL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
        )
        return baseURL
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("logs")
    }()

    private var logFilesURLs: [URL] {
        var urls = WireLogger.logFiles
        urls.append(contentsOf: ZMSLog.pathsForExistingLogs)
        return urls
    }

    // MARK: - Helpers

    private func filesToZipURLs(logFilesURLs: [URL], infoFileURL: URL) throws -> [URL] {
        guard !logFilesURLs.isEmpty else {
            throw Error.noLogs(description: logFilesURLs.description)
        }

        return logFilesURLs + [infoFileURL]
    }

    private func createUniqueLogDirectory() throws -> URL {
        let url = logsDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func createInfoFile(at url: URL) throws -> URL {
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

        let infoFileURL = url.appendingPathComponent("info.txt")

        try body.write(
            to: infoFileURL,
            atomically: true,
            encoding: .utf8
        )

        return infoFileURL
    }
}
