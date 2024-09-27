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

// MARK: - DeveloperFlag

public enum DeveloperFlag: String, CaseIterable {
    case enableMLSSupport
    case showCreateMLSGroupToggle
    case proteusViaCoreCrypto
    case nseV2
    case forceDatabaseLoadingFailure
    case ignoreIncomingEvents
    case debugDuplicateObjects
    case decryptAndStoreEventsSleep
    case forceCRLExpiryAfterOneMinute

    // MARK: Public

    public static var storage = UserDefaults.standard

    public var description: String {
        switch self {
        case .enableMLSSupport:
            "Turn on to enable MLS support. This will cause the app to register an MLS client."

        case .showCreateMLSGroupToggle:
            "Turn on to show the MLS toggle when creating a new group."

        case .proteusViaCoreCrypto:
            "Turn on to use CoreCrypto for proteus messaging."

        case .nseV2:
            "Turn on to use the new implementation of the notification service extension."

        case .forceDatabaseLoadingFailure:
            "Turn on to force database loading failure in the process of database migration"

        case .ignoreIncomingEvents:
            "Turn on to ignore incoming update events"

        case .debugDuplicateObjects:
            "Turn on to have actions to insert duplicate users, conversations, teams"

        case .decryptAndStoreEventsSleep:
            "Adds a delay when decrypting and storing events"

        case .forceCRLExpiryAfterOneMinute:
            "Turn on to force CRLs to expire after 1 minute"
        }
    }

    public var isOn: Bool {
        get {
            Self.storage.object(forKey: rawValue) as? Bool ?? defaultValue
        }

        set {
            Self.storage.set(newValue, forKey: rawValue)
        }
    }

    public static func clearAllFlags() {
        for item in allCases {
            storage.set(nil, forKey: item.rawValue)
        }
    }

    /// Convenience method to set flag on or off
    ///
    /// - Note: it can be used in Tests to change storage if provided
    public func enable(_ enabled: Bool, storage: UserDefaults? = nil) {
        if let storage {
            DeveloperFlag.storage = storage
        }
        var flag = self
        flag.isOn = enabled
    }

    // MARK: Internal

    var bundleKey: String? {
        switch self {
        case .enableMLSSupport:
            "MLSEnabled"
        case .showCreateMLSGroupToggle:
            "CreateMLSGroupEnabled"
        case .proteusViaCoreCrypto:
            "ProteusByCoreCryptoEnabled"
        case .forceDatabaseLoadingFailure:
            "ForceDatabaseLoadingFailure"
        case .nseV2, .debugDuplicateObjects, .forceCRLExpiryAfterOneMinute, .decryptAndStoreEventsSleep:
            nil
        case .ignoreIncomingEvents:
            "IgnoreIncomingEventsEnabled"
        }
    }

    // MARK: Private

    private var defaultValue: Bool {
        guard let bundleKey else {
            return false
        }
        return DeveloperFlagsDefault.isEnabled(for: bundleKey)
    }
}

// MARK: - DeveloperFlagsDefault

private final class DeveloperFlagsDefault {
    static func isEnabled(for bundleKey: String) -> Bool {
        Bundle(for: self).infoForKey(bundleKey) == "1"
    }
}

extension Bundle {
    public func infoForKey(_ key: String) -> String? {
        infoDictionary?[key] as? String
    }
}
