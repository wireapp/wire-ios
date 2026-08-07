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

import UIKit
import WireCommonComponents
import WireCoreCrypto
import WireDomain
import WireLogging
import WireSystem

/// Provides raw log file URLs and device/app info for building debug archives.
///
/// Archiving (ZIP creation) is handled by `CreateDebugReportUseCase`.
struct LogFilesProvider: LogFilesProviding {

    // MARK: - Properties

    private let logsDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .appendingPathComponent("logs", isDirectory: true)

    var logFileURLs: [URL] {
        let fileManager = FileManager.default
        var urls = ZMSLog.pathsForExistingLogs

        if let appGroupIdentifier = Bundle.main.applicationGroupIdentifier,
           let sharedLogsDirectoryURL = fileManager.sharedLogsDirectoryURL(for: appGroupIdentifier) {
            let targetLogDirectories = try? fileManager.contentsOfDirectory(
                at: sharedLogsDirectoryURL,
                includingPropertiesForKeys: .none
            )
            urls.append(contentsOf: targetLogDirectories ?? [])
        }

        return urls
    }

    // MARK: - LogFilesProviding

    func info(selfUserID: UUID?) -> String {
        var body = """
        App Version: \(Bundle.main.appInfo.fullVersion)
        Bundle id: \(Bundle.main.bundleIdentifier ?? "-")
        Device: \(UIDevice.current.zm_model())
        iOS version: \(UIDevice.current.systemVersion)
        Date: \(Date().transportString())
        """

        if let selfUserID {
            let journal = Journal(userID: selfUserID, storage: UserDefaults.shared())
            let entries = journal.values().compactMap { "\($0): \($1)" }.joined(separator: "\n")
            body += "\n\nJournal:\n\(entries)"
        }

        if let datadogUserIdentifier = WireAnalytics.Datadog.userIdentifier {
            body.append("\nDatadog ID: \(datadogUserIdentifier)")
        }

        let metadata = CoreCrypto.buildMetadata()
        body += """
        \n
        CoreCrypto:
        Timestamp: \(metadata.timestamp)
        Cargo debug: \(metadata.cargoDebug)
        Cargo features: \(metadata.cargoFeatures)
        Optimization level: \(metadata.optLevel)
        Target triple: \(metadata.targetTriple)
        Git branch: \(metadata.gitBranch)
        Git describe: \(metadata.gitDescribe)
        Git SHA: \(metadata.gitSha)
        Git dirty: \(metadata.gitDirty)
        """

        return body
    }

    func clearLogsDirectory(fileManager: FileManager) throws {
        if fileManager.fileExists(atPath: logsDirectory.path) {
            try fileManager.removeItem(at: logsDirectory)
        }
    }

    func removeLogFiles(fileManager: FileManager) throws {
        for fileURL in logFileURLs {
            try fileManager.removeItem(at: fileURL)
        }
    }

    func removeLegacyLogArchives() throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileManager = FileManager.default

        let contents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)

        for url in contents {
            let logsSubdir = url.appendingPathComponent("logs")
            var isDirectory: ObjCBool = false

            if fileManager.fileExists(atPath: logsSubdir.path, isDirectory: &isDirectory),
               isDirectory.boolValue {
                try fileManager.removeItem(at: url)
            }
        }
    }
}
