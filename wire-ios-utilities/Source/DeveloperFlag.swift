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
    case preventAdminlessGroups
    case showCreateMLSGroupToggle
    case showUnreadConversationsFilter
    case skipMLSMessagesDecryption
    case useWireAuthentication
    case wireMeetings
    case lowKeyPackageCount
    case enabledCCDebugLogs
    case shakeToReport
    case showNSEErrors
    case simulateMainAppRequiredError
    // TODO: [WPB-25941] Remove drive permissions flag when feature is complete
    case enableDrivePermissions
    case unSafeLogsForPublic
    case useBackgroundTaskAPIInAppBackgroundTaskExecuter

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

        case .preventAdminlessGroups:
            "Turn on to prevent last admins from leaving groups without promoting someone else"

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

        case .lowKeyPackageCount:
            "Turn on to set the minimum number of packages to 1"

        case .enabledCCDebugLogs:
            "Turn on to enable Core Crypto debug logs"

        case .shakeToReport:
            "Turn on to enable default shake gesture to present debug report share sheet. Shake again to present DeveloperTools once debug report share sheet presented"

        case .showNSEErrors:
            "Turn on to show Notification Service Extension errors as notifications"

        case .simulateMainAppRequiredError:
            "Turn on to force a 'main app required' error in the Notification Service and Share Extensions"

        case .enableDrivePermissions:
            "Turn on to enable drive permissions"

        case .unSafeLogsForPublic:
            "Turn on to write all logs (including debug and non-public) to disk in release builds"

        case .useBackgroundTaskAPIInAppBackgroundTaskExecuter:
            "Turn on to use Apple's UIApplication task API directly in AppBackgroundTaskExecuter"
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
