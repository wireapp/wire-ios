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

public enum BackendInfo {
    // MARK: Public

    /// The `UserDefaults` used to store backend configuration info.
    ///
    /// - Note: By default this is `UserDefaults.standard`. However, this property is currently overwritten by the main
    /// app on startup.

    public static var storage = UserDefaults.standard

    /// The currently selected API Version.

    public static var apiVersion: APIVersion? {
        get { apiVersion(for: Key.selectedAPIVersion) }
        set { storage.set(newValue?.rawValue, forKey: Key.selectedAPIVersion.rawValue) }
    }

    /// The preferred API Version.

    public static var preferredAPIVersion: APIVersion? {
        get { apiVersion(for: Key.preferredAPIVersion) }
        set { storage.set(newValue?.rawValue, forKey: Key.preferredAPIVersion.rawValue) }
    }

    /// The domain of the backend to which the app is connected to.

    public static var domain: String? {
        get { storage.string(forKey: Key.domain.rawValue) }
        set { storage.set(newValue, forKey: Key.domain.rawValue) }
    }

    /// Whether the connected backend has federation enabled.
    ///
    /// If the backend has federation enabled, then it may be federating with other backends.

    public static var isFederationEnabled: Bool {
        get { storage.bool(forKey: Key.isFederationEnabled.rawValue) }
        set { storage.set(newValue, forKey: Key.isFederationEnabled.rawValue) }
    }

    // MARK: Private

    private enum Key: String {
        case selectedAPIVersion = "SelectedAPIVersion"
        case preferredAPIVersion = "PreferredAPIVersion"
        case domain = "Domain"
        case isFederationEnabled = "IsFederationEnabled"
    }

    private static func apiVersion(for key: Key) -> APIVersion? {
        // Fetching an integer will default to 0 if no value exists for the key,
        // so explicitly check there is a value.
        guard storage.object(forKey: key.rawValue) != nil else { return nil }
        let storedValue = storage.integer(forKey: key.rawValue)
        return APIVersion(rawValue: Int32(storedValue))
    }
}
