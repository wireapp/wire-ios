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
import WireUtilities

private enum ExtensionSettingsKey: String, CaseIterable {

    case analyticsEnabledAccounts
    case disableLinkPreviews

    // deprecated, to be removed
    case disableAnalyticsSharing

    private var defaultValue: Any? {
        switch self {
        case .disableAnalyticsSharing:
            // No default value because the user needs to decide.
            nil
        case .analyticsEnabledAccounts:
            // No default value because the user needs to decide.
            [String]?.none
        case .disableLinkPreviews:
            false
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

    /// The accounts' `userIdentifier` values for which analytics tracking has been given consent.

    public var analyticsEnabledAccounts: [UUID: Bool] {
        get {
            let key = ExtensionSettingsKey.analyticsEnabledAccounts.rawValue
            if let accounts = defaults.object(forKey: key) as? [UUID: Bool] {
                return accounts
            }
            // TODO: delete from here

            // migrate from the old way of saving the consent, which was once per app
            var accounts = [UUID]()
            if let disabled = defaults.object(forKey: "disableAnalyticsSharing") as? Bool, !disabled {
                // add all accounts to the array
                //SessionManager.shared
                accounts += []
            }

            defaults.set(accounts, forKey: key)
            return accounts
        }
        set { defaults.set(newValue, forKey: ExtensionSettingsKey.analyticsEnabledAccounts.rawValue) }
    }

    public var disableLinkPreviews: Bool {
        get { defaults.bool(forKey: ExtensionSettingsKey.disableLinkPreviews.rawValue) }
        set { defaults.set(newValue, forKey: ExtensionSettingsKey.disableLinkPreviews.rawValue) }
    }

    @available(*, deprecated, message: "Use analyticsEnabledAccounts instead.")
    public var disableAnalyticsSharing_: Bool? {
        get { defaults.object(forKey: ExtensionSettingsKey.disableAnalyticsSharing.rawValue) as? Bool }
        set { defaults.set(newValue, forKey: ExtensionSettingsKey.disableAnalyticsSharing.rawValue) }
    }
}
