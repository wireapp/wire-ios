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

private enum ExtensionSettingsKey: String, CaseIterable {

    case disableCrashSharing
    case disableAnalyticsSharing
    case disableLinkPreviews

    private var defaultValue: Any? {
        switch self {
        // Always disable analytics by default.
        case .disableCrashSharing:
            return true
        case .disableAnalyticsSharing:
            return true
        case .disableLinkPreviews:
            return false
        }
    }

    static var defaultValueDictionary: [String: Any] {
        allCases.reduce(into: [:]) { partialResult, current in
            partialResult[current.rawValue] = current.defaultValue
        }
    }
}

public final class ExtensionSettings: NSObject {

    public static let shared = ExtensionSettings(defaults: .shared()!)

    private let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
        super.init()
        setupDefaultValues()
    }

    private func setupDefaultValues() {
        defaults.register(defaults: ExtensionSettingsKey.defaultValueDictionary)
    }

    func reset() {
        ExtensionSettingsKey.allCases.forEach {
            defaults.removeObject(forKey: $0.rawValue)
        }
    }

    public var disableAnalyticsSharing: Bool {
        get { defaults.object(forKey: ExtensionSettingsKey.disableAnalyticsSharing.rawValue) as? Bool ?? true }
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
}
