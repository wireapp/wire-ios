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

extension UserDefaults {
    /// Creates an instance with a random (UUID string based) `suiteName`.
    /// When the instance is deallocated, the storage is cleaned up.
    @objc
    public static func temporary() -> Self {
        let suiteName = UUID().uuidString
        let userDefaults = Self(suiteName: suiteName)!
        objc_setAssociatedObject(
            userDefaults,
            &SuiteCleanUpHandle,
            SuiteCleanUp(suiteName),
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return userDefaults
    }
}

// MARK: UserDefaults.temporary() helpers

private let zmLog = ZMSLog(tag: "UserDefaults")

// MARK: - SuiteCleanUp

private final class SuiteCleanUp {
    private let suiteName: String

    init(_ suiteName: String) {
        self.suiteName = suiteName
    }

    deinit {
        // remove all values
        UserDefaults.standard.removePersistentDomain(forName: suiteName)

        // try to even delete the plist file from the simulator usually at
        // ~/Library/Developer/CoreSimulator/Devices/<device id>/data/Containers/Data/Application/<app
        // id>/Library/Preferences/<suiteName>.plist
        do {
            let fileManager = FileManager.default
            let url = try fileManager
                .url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: .init(string: "/")!, create: false)
                .appendingPathComponent("Preferences")
                .appendingPathComponent(suiteName + ".plist")
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        } catch {
            zmLog.warn("Could not remove temporary user defaults file: " + String(reflecting: error))
        }
    }
}

private nonisolated(unsafe) var SuiteCleanUpHandle = 0
