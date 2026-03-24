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

#if DEBUG
/// Configuration values for UITests.
public struct UITestConfig: Codable {

    /// The key used to store the config in the environment variables when running UITests.
    public static let environmentKey = "UITEST_CONFIG"

    // MARK: - Configuration data

    public var isBuildBlacklisted = false

    // MARK: - Init

    public init() {}

    // MARK: - Encoding/Decoding

    /// The string representation of the config as a base64 encoded JSON string.
    public func encode() -> String {
        try! JSONEncoder().encode(self).base64EncodedString()
    }

    /// Returns `UITestConfig` decoded from base64 app environment or default config if none is set.
    public static func fromEnvironment() -> UITestConfig {
        guard
            let value = ProcessInfo.processInfo.environment[Self.environmentKey],
            let data = Data(base64Encoded: value),
            let config = try? JSONDecoder().decode(UITestConfig.self, from: data)
        else {
            return UITestConfig() // Return default config is none set in the environment
        }

        return config
    }
}
#endif
