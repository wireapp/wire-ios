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

import Foundation
import WireSystem

public enum LogFileDestination: CaseIterable, FileLoggerDestination {
    case nse
    case main
    case shareExtension

    // MARK: Public

    public var filename: String {
        switch self {
        case .main:
            "oslog_dump.log"
        case .nse:
            "oslog_NSE_dump.log"
        case .shareExtension:
            "oslog_share_dump.log"
        }
    }

    public var log: URL? {
        switch self {
        case .nse, .shareExtension:
            guard let url = Bundle.appMainBundle.applicationGroupIdentifier
                .map(FileManager.sharedContainerDirectory(for:)) else {
                return nil
            }
            return url.appendingPathComponent(filename)

        case .main:
            return Self.cachesDirectory?.appendingPathComponent(filename)
        }
    }

    public static func deleteAllLogs() {
        for destination in LogFileDestination.allCases {
            if let logURL = destination.log {
                try? FileManager.default.removeItem(at: logURL)
            }
        }
    }

    // MARK: Private

    private static var cachesDirectory: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    }
}
