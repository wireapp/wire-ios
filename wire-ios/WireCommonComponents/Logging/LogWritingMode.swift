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

/// Controls how CocoaLumberjack writes log messages to disk.
///
/// The value is persisted in the shared app-group `UserDefaults` container so
/// that it is available before `DeveloperFlagOperation` reconfigures the
/// default storage.  The change takes effect on the **next app launch**.
public enum LogWritingMode: String, CaseIterable {

    /// Log messages are written to disk continuously (default).
    case normal
    /// No log messages are written to disk.
    case off
    /// Log messages are held in memory and flushed to disk only when the app
    /// receives a memory warning, moves to the background, is terminated, or
    /// encounters an uncaught NSException.
    case buffered

    // MARK: - Persistence

    private static let storageKey = "logWritingMode"

    /// Persistent storage used to read and write the current mode.
    ///
    /// Defaults to the shared app-group container so the setting is readable
    /// during `willFinishLaunchingWithOptions`, before `DeveloperFlagOperation`
    /// runs.
    public static var storage: UserDefaults = {
        UserDefaults(suiteName: Bundle.main.applicationGroupIdentifier) ?? .standard
    }()

    /// The currently persisted mode.  Returns `.normal` when no value has been
    /// stored yet.
    public static var current: LogWritingMode {
        get {
            guard
                let raw = storage.string(forKey: storageKey),
                let mode = LogWritingMode(rawValue: raw)
            else { return .normal }
            return mode
        }
        set {
            storage.set(newValue.rawValue, forKey: storageKey)
        }
    }

    // MARK: - Display

    public var title: String {
        switch self {
        case .normal: "Normal"
        case .off: "Off"
        case .buffered: "Buffered"
        }
    }

    public var description: String {
        switch self {
        case .normal:
            "Logs are written to disk continuously (default behaviour)."
        case .off:
            "No logs are written to disk."
        case .buffered:
            "Logs are held in memory and written to disk only on memory warning, backgrounding, termination or crash."
        }
    }
}
