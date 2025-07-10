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
import WireLogging
import WireSystem

/// Namespace for analytics tools.
public enum WireAnalytics {

    private static let isSetUpLock = NSLock()
    private static var isSetUp = false

    public static func setup(for target: Target) {
        // Adding a lock here since some app extension might execute this setup in the same process as the main app.
        // https://stackoverflow.com/a/62674277
        isSetUpLock.lock()
        defer { isSetUpLock.unlock() }

        guard !isSetUp else {
            return
        }
        isSetUp = true

        WireAnalytics.Datadog.shared.enable()

        WireLogger.initialize {
            #if DEBUG
                SystemLogger()
            #endif
            CocoaLumberjackLogger(logsDirectory: target.logsDirectory)
            WireAnalytics.Datadog.shared
        }

        // pass tags to Datadog through WireLogger
        WireLogger.system.addTag(.processId, value: "\(ProcessInfo.processInfo.processIdentifier)")
        WireLogger.system.addTag(.processName, value: ProcessInfo.processInfo.processName)
    }

    public enum Target {
        case app
        case notificationServiceExtension
        case shareExtension
    }

}

extension WireAnalytics.Target {

    fileprivate var logsDirectory: URL? {
        let fileManager = FileManager.default
        switch self {

        case .app:
            let cachesDirectory = try? fileManager.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            return cachesDirectory?.appending(path: "Logs", directoryHint: .isDirectory)

        case .notificationServiceExtension, .shareExtension:
            guard let appGroupIdentifier = Bundle.main.applicationGroupIdentifier else { return nil }
            let cachesDirectory = fileManager.cachesURL(
                forAppGroupIdentifier: appGroupIdentifier,
                accountIdentifier: nil
            )
            return cachesDirectory?
                .appending(path: "Logs", directoryHint: .isDirectory)
                .appending(component: subdirectory, directoryHint: .isDirectory)

        }
    }

    private var subdirectory: String {
        switch self {
        case .app: "App"
        case .notificationServiceExtension: "NotificationServiceExtension"
        case .shareExtension: "ShareExtension"
        }
    }

}
