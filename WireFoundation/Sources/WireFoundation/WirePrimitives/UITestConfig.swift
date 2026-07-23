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

/// Configuration values for UITests.
public struct UITestConfig: Codable {

    /// The key used to store the config in the environment variables when running UITests.
    public static let environmentKey = "UITEST_CONFIG"

    // MARK: - Configuration data

    public var isBuildBlacklisted = false

    /// When `true`, a triple-tap on the app window triggers the same action as the shake gesture.
    /// On XCUITests, shake gesture is not available.
    public var useTripleTapForShakeGesture = false

    /// When `true`, audio recording UI uses a deterministic mock recorder.
    public var useMockAudioRecorder = false

    /// Developer flags to apply at launch, keyed by `DeveloperFlag.rawValue`.
    /// Overrides any flags already stored in `UserDefaults`.
    public var developerFlags: [String: Bool] = [:]

    /// Credentials used by UI tests to start the app in an authenticated state.
    public var authenticationBypass: UITestAuthenticationBypass?

    // MARK: - Init

    public init() {}

    // MARK: - Encoding/Decoding

    /// The string representation of the config as a base64 encoded JSON string.
    public func encode() -> String {
        try! JSONEncoder().encode(self).base64EncodedString()
    }

    #if DEBUG
        public static var environment: UITestConfig? {
            guard
                let value = ProcessInfo.processInfo.environment[environmentKey],
                let data = Data(base64Encoded: value),
                let config = try? JSONDecoder().decode(UITestConfig.self, from: data)
            else {
                return nil
            }

            return config
        }
    #endif
}

public struct UITestAuthenticationBypass: Codable {

    public let email: String
    public let password: String
    /// Expected identifier of the fixture user. When set, the app verifies the logged-in user
    /// matches, catching a stale or mismatched credentials configuration.
    public let expectedUserID: String?

    public init(email: String, password: String, expectedUserID: String? = nil) {
        self.email = email
        self.password = password
        self.expectedUserID = expectedUserID
    }

}
