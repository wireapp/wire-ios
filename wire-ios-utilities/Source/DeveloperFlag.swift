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

public enum DeveloperFlag: String, CaseIterable {

    public static var storage = UserDefaults.standard

    case enableMLSSupport
    case showCreateMLSGroupToggle
    case proteusViaCoreCrypto
    case forceDatabaseLoadingFailure
    case ignoreIncomingEvents
    case debugDuplicateObjects
    case decryptAndStoreEventsSleep
    case forceCRLExpiryAfterOneMinute

    public var description: String {
        switch self {
        case .enableMLSSupport:
            return "Turn on to enable MLS support. This will cause the app to register an MLS client."

        case .showCreateMLSGroupToggle:
            return "Turn on to show the MLS toggle when creating a new group."

        case .proteusViaCoreCrypto:
            return "Turn on to use CoreCrypto for proteus messaging."

        case .forceDatabaseLoadingFailure:
            return "Turn on to force database loading failure in the process of database migration"

        case .ignoreIncomingEvents:
            return "Turn on to ignore incoming update events"

        case .debugDuplicateObjects:
            return "Turn on to have actions to insert duplicate users, conversations, teams"

        case .decryptAndStoreEventsSleep:
            return "Adds a delay when decrypting and storing events"

        case .forceCRLExpiryAfterOneMinute:
            return "Turn on to force CRLs to expire after 1 minute"
        }
    }

    public var isOn: Bool {
        get {
            return Self.storage.object(forKey: rawValue) as? Bool ?? defaultValue
        }

        set {
            Self.storage.set(newValue, forKey: rawValue)
        }
    }

    private var defaultValue: Bool {
        guard let bundleKey else {
            return false
        }
        return DeveloperFlagsDefault.isEnabled(for: bundleKey)
    }

    static public func clearAllFlags() {
        allCases.forEach {
            storage.set(nil, forKey: $0.rawValue)
        }
    }

    var bundleKey: String? {
        switch self {
        case .enableMLSSupport:
            return "MLSEnabled"
        case .showCreateMLSGroupToggle:
            return "CreateMLSGroupEnabled"
        case .proteusViaCoreCrypto:
            return "ProteusByCoreCryptoEnabled"
        case .forceDatabaseLoadingFailure:
            return "ForceDatabaseLoadingFailure"
        case .debugDuplicateObjects, .forceCRLExpiryAfterOneMinute, .decryptAndStoreEventsSleep:
            return nil
        case .ignoreIncomingEvents:
            return "IgnoreIncomingEventsEnabled"
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
}

private final class DeveloperFlagsDefault {

    static func isEnabled(for bundleKey: String) -> Bool {
        return Bundle(for: self).infoForKey(bundleKey) == "1"
    }
}

public extension Bundle {
    func infoForKey(_ key: String) -> String? {
        return infoDictionary?[key] as? String
    }
}
