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
import os
import WireLogging
import WireSystem

/// Namespace for analytics tools.
public enum WireAnalytics {

    private static let isSetUpLock = NSLock()
    private static var isSetUp = false

    public static func setup(for target: LogTarget) {
        // Adding a lock here since some app extension might execute this setup in the same process as the main app.
        // https://stackoverflow.com/a/62674277
        isSetUpLock.lock()
        defer { isSetUpLock.unlock() }

        guard !isSetUp else { return }
        isSetUp = true

        WireAnalytics.Datadog.shared.enable()

        migrateLogFilesToNewLocation(target: target)

        WireLogger.initialize {
            #if DEBUG
                SystemLogger()
            #endif
            CocoaLumberjackLogger(logsDirectory: logsDirectory(for: target))
            WireAnalytics.Datadog.shared
        }

        // pass tags to Datadog through WireLogger
        WireLogger.system.addTag(.processId, value: "\(ProcessInfo.processInfo.processIdentifier)")
        WireLogger.system.addTag(.processName, value: ProcessInfo.processInfo.processName)
    }

    private static func logsDirectory(for target: LogTarget) -> URL? {
        guard let appGroupIdentifier = Bundle.main.applicationGroupIdentifier else { return nil }
        return FileManager.default.sharedLogsDirectoryURL(for: appGroupIdentifier)?
            .appending(component: target.rawValue, directoryHint: .isDirectory)
    }

    /// With release 4.2.0 the log files of all targets (main app, notification service extension and share extension)
    /// are written to the shared container. This code tries to move the old files for the case that all log files want
    /// to be retrieved/exported.
    /// Eventually this func can just be deleted.

    private static func migrateLogFilesToNewLocation(target: LogTarget) {
        do {

            let fileManager = FileManager.default
            guard let newRootDirectory = logsDirectory(for: target) else { return }
            let previousRootDirectory = try fileManager.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            ).appending(path: "Logs", directoryHint: .isDirectory)

            guard fileManager.fileExists(atPath: previousRootDirectory.path()) else { return }

            let previousLogFileURLs = try fileManager.contentsOfDirectory(
                at: previousRootDirectory,
                includingPropertiesForKeys: nil
            )
            if !previousLogFileURLs.isEmpty {
                try fileManager.createDirectory(at: newRootDirectory, withIntermediateDirectories: true)
            }

            for previousLogFileURL in previousLogFileURLs {
                let newLogFileURL = newRootDirectory.appending(
                    path: previousLogFileURL.lastPathComponent,
                    directoryHint: .notDirectory
                )
                if fileManager.fileExists(atPath: newLogFileURL.path()) {
                    continue
                }
                try fileManager.moveItem(at: previousLogFileURL, to: newLogFileURL)
            }

            try fileManager.removeItem(at: previousRootDirectory)

        } catch {
            let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier!, category: "system")
            logger.error("Failed to migrate old log files to new location: \(error)")
        }
    }

}
