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

import WireCommonComponents
import WireSystem
import ZipArchive

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
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("logs")
    }()

    private var logFilesURLs: [URL] {
        var urls = WireLogger.logFiles
        urls.append(contentsOf: ZMSLog.pathsForExistingLogs)
        return urls
    }

    // MARK: - Interface

    func generateLogFilesData() throws -> Data {
        defer {
            // because we don't rotate file for this one, we clean it once sent
            // this regenerated from os_log anyway
            if let url = LogFileDestination.main.log {
                try? FileManager.default.removeItem(at: url)
            }
        }

        let urls = logFilesURLs

        guard !urls.isEmpty, let data = FileManager.default.zipData(from: urls) else {
            throw Error.noLogs(description: urls.description)
        }

        return data
    }

    func generateLogFilesZip() throws -> URL {
        try? clearLogsDirectory()

        var url = logsDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)

        url.appendPathComponent("logs.zip")
        SSZipArchive.createZipFile(
            atPath: url.path,
            withFilesAtPaths: logFilesURLs.map { $0.path }
        )

        return url
    }

    func clearLogsDirectory() throws {
        try FileManager.default.removeItem(atPath: logsDirectory.path)
    }
}
