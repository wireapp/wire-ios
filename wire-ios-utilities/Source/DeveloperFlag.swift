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

public enum DeveloperFlag: String, CaseIterable {

    public static var storage = UserDefaults.standard

    case channelsHistory
    case chatBubbles
    case consumableNotifications
    case createLegacyBackups
    case debugDuplicateObjects
    case decryptAndStoreEventsSleep
    case disablePushChannelBatching
    case forceCRLExpiryAfterOneMinute
    case forceDatabaseLoadingFailure
    case ignoreIncomingEvents
    case newRegistration
    case showCreateMLSGroupToggle
    case showUnreadConversationsFilter
    case skipMLSMessagesDecryption
    case useWireAuthentication
    case wireMeetings

    public var description: String {
        switch self {
        case .createLegacyBackups:
            "Don't use the cross-platform library when creating backups."

        case .showCreateMLSGroupToggle:
            "Turn on to show the MLS toggle when creating a new group."

        case .forceDatabaseLoadingFailure:
            "Turn on to force database loading failure in the process of database migration"

        case .ignoreIncomingEvents:
            "Turn on to ignore incoming update events"

        case .skipMLSMessagesDecryption:
            "Turn on to skip MLS message decryption"

        case .debugDuplicateObjects:
            "Turn on to have actions to insert duplicate users, conversations, teams"

        case .decryptAndStoreEventsSleep:
            "Adds a delay when decrypting and storing events"

        case .forceCRLExpiryAfterOneMinute:
            "Turn on to force CRLs to expire after 1 minute"

        case .useWireAuthentication:
            "Use the new WireAuthentication feature module"

        case .disablePushChannelBatching:
            "Turn on to disable batching while app is live"

        case .newRegistration:
            "Turn on to use the new registration flow"

        case .showUnreadConversationsFilter:
            "Turn on to show the new conversation filter options"

        case .channelsHistory:
            "Turn on to enable channels history"

        case .chatBubbles:
            "Show conversation messages as chat bubbles"

        case .consumableNotifications:
            "Turn on to enable consumable notifications"

        case .wireMeetings:
            "Turn on to enable Wire meetings"
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

    private var defaultValue: Bool {
        guard let bundleKey else {
            return false
        }
        return DeveloperFlagsDefault.isEnabled(for: bundleKey)
    }

    public static func clearAllFlags() {
        allCases.forEach {
            storage.set(nil, forKey: $0.rawValue)
        }
    }

    private var bundleKey: String? {
        switch self {
        case .createLegacyBackups:
            "CreateLegacyBackupsEnabled"
        case .forceDatabaseLoadingFailure:
            "ForceDatabaseLoadingFailure"
        case .ignoreIncomingEvents:
            "IgnoreIncomingEventsEnabled"
        case .useWireAuthentication:
            "WireAuthenticationEnabled"
        default:
            nil
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
        Bundle(for: self).infoForKey(bundleKey) == "1"
    }
}

public extension Bundle {
    func infoForKey(_ key: String) -> String? {
        infoDictionary?[key] as? String
    }
}
