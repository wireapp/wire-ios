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

import avs
import Foundation
import WireCommonComponents
import WireDesign
import WireSyncEngine

// MARK: - LaunchSequenceOperation
protocol LaunchSequenceOperation {
    func execute()
}

// MARK: - DeveloperFlagOperation
final class DeveloperFlagOperation: LaunchSequenceOperation {
    func execute() {
        DeveloperFlag.storage = .applicationGroup
    }
}

// MARK: - BackendEnvironmentOperation
final class BackendEnvironmentOperation: LaunchSequenceOperation {
    func execute() {
        guard let backendTypeOverride = AutomationHelper.sharedHelper.backendEnvironmentTypeOverride() else {
            return
        }
        AutomationHelper.sharedHelper.persistBackendTypeOverrideIfNeeded(with: backendTypeOverride)
    }
}

// MARK: - PerformanceDebuggerOperation
final class PerformanceDebuggerOperation: LaunchSequenceOperation {
    func execute() {
        PerformanceDebugger.shared.start()
    }
}

// MARK: - ZMSLogOperation
final class AVSLoggingOperation: LaunchSequenceOperation {
    func execute() {
        SessionManager.startAVSLogging()
    }
}

// MARK: - AutomationHelperOperation
final class AutomationHelperOperation: LaunchSequenceOperation {
    func execute() {
        AutomationHelper.sharedHelper.installDebugDataIfNeeded()

        if AutomationHelper.sharedHelper.enableMLSSupport == true {
            var flag = DeveloperFlag.enableMLSSupport
            flag.isOn = true
        }
    }
}

// MARK: - MediaManagerOperation
final class MediaManagerOperation: LaunchSequenceOperation {
    private let mediaManagerLoader = MediaManagerLoader()

    func execute() {
        mediaManagerLoader.send(message: .appStart)
    }
}

// MARK: - FileBackupExcluderOperation
final class FileBackupExcluderOperation: LaunchSequenceOperation {
    private let fileBackupExcluder = FileBackupExcluder()

    func execute() {
        guard let appGroupIdentifier = Bundle.main.appGroupIdentifier else {
            return
        }

        let sharedContainerURL = FileManager.sharedContainerDirectory(for: appGroupIdentifier)
        fileBackupExcluder.excludeLibraryFolderInSharedContainer(sharedContainerURL: sharedContainerURL)
    }
}

// MARK: - BackendInfoOperation

final class BackendInfoOperation: LaunchSequenceOperation {

    func execute() {
        BackendInfo.storage = .applicationGroup

        if let preferredVersion = AutomationHelper.sharedHelper.preferredAPIVersion {
            WireLogger.environment.info("automation helper will set preferred api version to \(preferredVersion)")
            BackendInfo.preferredAPIVersion = preferredVersion
        }
    }
}

final class FontSchemeOperation: LaunchSequenceOperation {

    func execute() {
        FontScheme.shared.configure(with: UIApplication.shared.preferredContentSizeCategory)
    }
}

final class VoIPPushHelperOperation: LaunchSequenceOperation {

    func execute() {
        VoIPPushHelper.storage = .applicationGroup
    }
}

/// This operation cleans up any state that may have been set in debug builds so that
/// release builds don't exhibit any debugging behaviour.
///
/// This is a safety precaution: users of release builds likely won't ever run a debug
/// build, but it's better to be sure.

final class CleanUpDebugStateOperation: LaunchSequenceOperation {

    func execute() {
        guard !Bundle.developerModeEnabled else { return }

        // Clearing this ensures that the api version is negotiated with the backend
        // and not set explicitly.
        BackendInfo.preferredAPIVersion = nil

        // Clearing all developer flags ensures that no custom behavior is
        // present in the app.
        DeveloperFlag.clearAllFlags()
    }
}
