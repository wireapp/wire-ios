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
import WireSystem

/// User default key for the array of enabled logs
private let enabledLogsKey = "WireEnabledZMLogTags"

extension Settings {

    /// Enable/disable a log
    func set(logTag: String, enabled: Bool) {
        ZMSLog.set(level: enabled ? .debug : .warn, tag: logTag)
        saveEnabledLogs()
    }

    /// Save to user defaults the list of logs that are enabled
    private func saveEnabledLogs() {
        let enabledLogs = ZMSLog.allTags.filter { tag in
            let level = ZMSLog.getLevel(tag: tag)
            return level == .debug || level == .info
        } as NSArray

        UserDefaults.shared().set(enabledLogs, forKey: enabledLogsKey)
    }

    /// Loads from user default the list of logs that are enabled
    func loadEnabledLogs() {
        let tagsToEnable: Set<String> = [
            "AVS",
            "Network",
            "SessionManager",
            "Conversations",
            "calling",
            "link previews",
            "event-processing",
            "SyncStatus",
            "OperationStatus",
            "Push",
            "Crypto",
            "cryptobox",
            "backend-environment",
            "Backup",
            // added to defaults
            "TokenField",
            "FileManager",
            "AVSMediaManager CustomSounds",
            "URL",
            "EmoticonSubstitutionConfiguration",
            "URL Helper",
            "message-processing",
            "backend-environment",
            "Analytics",
            "MediaPlaybackManager",
            "UI",
            "Authentication",
            "AuthenticationReauthenticateInputHandler",
            "TextView",
            "Bundle",
            "SketchColorPickerController",
            "link opening",
            "haptics",
            "call-participant-timestamps",
            "ProfileViewController",
            "ProfileViewControllerViewModel",
            "Mentions",
            "SavableImage",
            "ConversationContentViewController",
            "MessagePresenter",
            "Drag and drop images",
            "ConversationInputBarViewController+Files",
            "ConversationInputBarViewController - Image Picker",
            "ConversationViewController+ConversationContentViewControllerDelegate",
            "ConversationListViewModel",
            "StartUIViewController",
            "AppDelegate",
            "AppState",
            "share extension",
            "NetworkStatus",
            "API Migration",
            "Cryptobox Migration",
            "ContactAddressBook",
            "ZMUserSession",
            "ZMClientRegistrationStatus",
            "UserProfileImageUpdateStatus",
            "APIVersion",
            "UnauthenticatedSession",
            "core-data",
            "Services",
            "ConversationMessageDestructionTimeout",
            "ConversationLink",
            "Teams",
            "userClientRS",
            "AssetDeletion",
            "Calling System Message",
            "PushNotificationStatus",
            "EventDecoder",
            "Dependencies",
            "EAR",
            "terminate federation",
            "feature configurations",
            "rich-profile",
            "Request Configuration",
            "Asset V3",
            "AssetPreviewDownloading",
            "link-attachments",
            "Patches",
            "DuplicateEntity",
            "AppLockController",
            "Feature",
            "Accounts",
            "CallState",
            "Conversations",
            "shared object store",
            "ephemeral",
            "Message",
            "ZMFileMetadata",
            "assets",
            "message encryption",
            "GenericMessage",
            "text search",
            "UserClient",
            "ZMManagedObjectGrouping",
            "ConversationListObserverCenter",
            "MessageChangeInfo",
            "notifications",
            "SearchUserObserverCenter",
            "DependencyKeyStore",
            "UserImageCache",
            "FileLocation",
            "local-storage",
            "UpdateEvents",
            "Push channel",
            "SafeTypes"
        ]

        // NOTE: WPB-5754: force enable logs for now
        /*
         if let savedTags = UserDefaults.shared().object(forKey: enabledLogsKey) as? [String] {
            tagsToEnable = Set(savedTags)
        }
         */

        enableLogs(tagsToEnable)
    }

    private func enableLogs(_ tags: Set<String>) {
        tags.forEach { tag in
            ZMSLog.set(level: .debug, tag: tag)
        }
    }

}
