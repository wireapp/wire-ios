// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

// MARK: - Current

extension APIVersion {

    private enum Key: String {

        case highestProductionVersion = "APIVersionHighestProductionVersion"
        case preferredVersion = "APIVersionPreferredVersion"
        case productionVersions = "APIVersionProductionVersions"
        case developmentVersions = "APIVersionDevelopmentVersions"
        case domain = "APIVersionDomain"
        case federation = "APIVersionFederation"

    }

    /// Where the api version information (i.e current version, local domain and federation
    /// flag) is stored.
    ///
    /// **Important:** set this value to a UserDefaults instance with a suite name
    /// matching the App Group id so that the values are accessible not only from
    /// the main app but also the app extensions.

    public static var storage: UserDefaults = .standard

    /// The API version against which all new backend requests should be made.
    ///
    /// The current version is calculated as the preferred version (if set), otherwise
    /// the highest prodction version supported by both the client and backend.
    ///
    /// A `nil` value indicates that no version is selected yet and therefore one
    /// should be (re-)negotiated with the backend.

    public static var current: APIVersion? {
        return preferredVersion ?? highestProductionVersion
    }

    /// The highest supported version in common between the client and the backend.

    public private(set) static var highestProductionVersion: APIVersion? {
        get {
            return apiVersion(for: Key.highestProductionVersion)
        }

        set {
            storage.set(newValue?.rawValue, forKey: Key.highestProductionVersion.rawValue)
        }
    }

    /// If available, the preferred version is used instead of the highest supported
    /// version. This is only for development purposes.

    public static var preferredVersion: APIVersion? {
        get {
            return apiVersion(for: Key.preferredVersion)
        }

        set {
            storage.set(newValue?.rawValue, forKey: Key.preferredVersion.rawValue)
        }
    }

    private static func apiVersion(for key: Key) -> APIVersion? {
        // Fetching an integer will default to 0 if no value exists for the key,
        // so explicitly check there is a value.
        guard storage.hasValue(for: key.rawValue) else { return nil }
        let storedValue = storage.integer(forKey: key.rawValue)
        return APIVersion(rawValue: Int32(storedValue))
    }

    /// Set the production and development versions supported by the backend.

    public static func setVersions(production: [APIVersion], development: [APIVersion]) {
        productionVersions = production
        developmentVersions = development
        clearPreferredVersionIfNeeded()
    }

    /// The production versions available on the backend.

    public private(set) static var productionVersions: [APIVersion] {
        get {
            let values = storage.array(forKey: Key.productionVersions.rawValue) as? [Int] ?? []
            return values.compactMap { APIVersion.init(rawValue: Int32($0)) }
        }

        set {
            storage.set(newValue.map(\.rawValue), forKey: Key.productionVersions.rawValue)
            highestProductionVersion = newValue.max()
        }
    }

    /// The development versions available on the backend.

    public private(set) static var developmentVersions: [APIVersion] {
        get {
            let values = storage.array(forKey: Key.developmentVersions.rawValue) as? [Int] ?? []
            return values.compactMap { APIVersion.init(rawValue: Int32($0)) }
        }

        set {
            storage.set(newValue.map(\.rawValue), forKey: Key.developmentVersions.rawValue)
        }
    }

    private static func clearPreferredVersionIfNeeded() {
        guard let version = preferredVersion else { return }
        let allVersions = productionVersions + developmentVersions

        if !allVersions.contains(version) {
            preferredVersion = nil
        }
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
        get { storage.bool(forKey: Key.federation.rawValue) }
        set { storage.set(newValue, forKey: Key.federation.rawValue) }
    }

}

// MARK: - Helper

private extension UserDefaults {

    func hasValue(for key: String) -> Bool {
        return object(forKey: key) != nil
    }

}
