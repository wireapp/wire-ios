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
import WireUtilities

// MARK: - ExtensionSettingsKey

private enum ExtensionSettingsKey: String, CaseIterable {
    case disableCrashSharing
    case disableAnalyticsSharing
    case disableLinkPreviews

    // MARK: Internal

    static var defaultValueDictionary: [String: Any] {
        allCases.reduce(into: [:]) { partialResult, current in
            partialResult[current.rawValue] = current.defaultValue
        }
    }

    // MARK: Private

    private var defaultValue: Any? {
        switch self {
        // Always disable analytics by default.
        case .disableCrashSharing:
            true
        case .disableAnalyticsSharing:
            false
        case .disableLinkPreviews:
            false
        }
    }
}

// MARK: - ExtensionSettings

public final class ExtensionSettings: NSObject {
    // MARK: Lifecycle

    public init(defaults: UserDefaults) {
        self.defaults = defaults
        super.init()
        setupDefaultValues()
    }

    // MARK: Public

    public static let shared = ExtensionSettings(defaults: .shared()!)

    public var disableAnalyticsSharing: Bool {
        get { defaults.bool(forKey: ExtensionSettingsKey.disableAnalyticsSharing.rawValue) }
        set { defaults.set(newValue, forKey: ExtensionSettingsKey.disableAnalyticsSharing.rawValue) }
    }

    public var disableCrashSharing: Bool {
        get { defaults.bool(forKey: ExtensionSettingsKey.disableCrashSharing.rawValue) }
        set { defaults.set(newValue, forKey: ExtensionSettingsKey.disableCrashSharing.rawValue) }
    }

    public var disableLinkPreviews: Bool {
        get { defaults.bool(forKey: ExtensionSettingsKey.disableLinkPreviews.rawValue) }
        set { defaults.set(newValue, forKey: ExtensionSettingsKey.disableLinkPreviews.rawValue) }
    }

    // MARK: Internal

    func reset() {
        for item in ExtensionSettingsKey.allCases {
            defaults.removeObject(forKey: item.rawValue)
        }
    }

    // MARK: Private

    private let defaults: UserDefaults

    private func setupDefaultValues() {
        defaults.register(defaults: ExtensionSettingsKey.defaultValueDictionary)
    }
}
