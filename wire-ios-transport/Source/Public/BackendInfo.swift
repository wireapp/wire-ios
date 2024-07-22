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

    private enum Key: String {

        case selectedAPIVersion = "SelectedAPIVersion"
        case preferredAPIVersion = "PreferredAPIVersion"
        case domain = "Domain"
        case isFederationEnabled = "IsFederationEnabled"

    }

    #if DEBUG
    private static var mockStorage: UserDefaults?
    private static var _storage: UserDefaults { mockStorage ?? storage }
    #else
    private static var _storage: UserDefaults { storage }
    #endif

    /// The `UserDefaults` used to store backend configuration info.
    ///
    /// - Note: By default this is `UserDefaults.standard`. However, this property is currently overwritten by the main
    /// app on startup.

    public static var storage = UserDefaults.standard {
        didSet {
            didSetStorage?(storage)
        }
    }

    public static var didSetStorage: ((UserDefaults) -> Void)?

    /// The currently selected API Version.

    public static var apiVersion: APIVersion? {
        get { return apiVersion(for: Key.selectedAPIVersion) }
        set { _storage.set(newValue?.rawValue, forKey: Key.selectedAPIVersion.rawValue) }
    }

    /// The preferred API Version.

    public static var preferredAPIVersion: APIVersion? {
        get { return apiVersion(for: Key.preferredAPIVersion) }
        set { _storage.set(newValue?.rawValue, forKey: Key.preferredAPIVersion.rawValue) }
    }

    /// The domain of the backend to which the app is connected to.

    public static var domain: String? {
        get { _storage.string(forKey: Key.domain.rawValue) }
        set { _storage.set(newValue, forKey: Key.domain.rawValue) }
    }

    /// Whether the connected backend has federation enabled.
    ///
    /// If the backend has federation enabled, then it may be federating with other backends.

    public static var isFederationEnabled: Bool {
        get { _storage.bool(forKey: Key.isFederationEnabled.rawValue) }
        set { _storage.set(newValue, forKey: Key.isFederationEnabled.rawValue) }
    }

    private static func apiVersion(for key: Key) -> APIVersion? {
        // Fetching an integer will default to 0 if no value exists for the key,
        // so explicitly check there is a value.
        guard _storage.object(forKey: key.rawValue) != nil else { return nil }
        let storedValue = _storage.integer(forKey: key.rawValue)
        return APIVersion(rawValue: Int32(storedValue))
    }
}

#if DEBUG

// MARK: - Mock

extension BackendInfo {
    @_spi(MockBackendInfo)
    public static func enableMocking() {
        BackendInfo.mockStorage = MockUserDefaults(suiteName: UUID().uuidString)!
    }

    @_spi(MockBackendInfo)
    public static func resetMocking() {
        if let storage = mockStorage as? MockUserDefaults {
            storage.removePersistentDomain(forName: storage.suiteName)
        }
        BackendInfo.mockStorage = nil
    }
}

private class MockUserDefaults: UserDefaults {
    let suiteName: String

    override init?(suiteName suitename: String?) {
        self.suiteName = suitename ?? ""
        super.init(suiteName: suitename)
    }
}

#endif
