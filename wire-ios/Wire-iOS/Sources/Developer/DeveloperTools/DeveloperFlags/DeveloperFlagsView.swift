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

import SwiftUI
import WireUtilities

struct DeveloperFlagsView: View {

    // MARK: - Properties

    @StateObject var viewModel: DeveloperFlagsViewModel
    @State private var showRestartAlert = false

    // MARK: - Views

    var body: some View {
        List {
            ForEach(FlagSection.allCases, id: \.self) { section in
                Section {
                    ForEach(viewModel.flags.filter { FlagSection(flag: $0) == section }, id: \.self) { flag in
                        cell(for: flag)
                            .padding([.top, .bottom])
                    }
                } header: {
                    Text(section.rawValue)
                        .accessibilityLabel(section.rawValue)
                        .accessibilityIdentifier("developerFlags.section.\(section.rawValue)")
                }
            }
        }
        .alert("Restart required", isPresented: $showRestartAlert) {
            Button("Restart now", role: .destructive) { exit(0) }
        } message: {
            Text("This flag is read when the app launches. Restart the app for the change to take effect.")
        }
    }

    private func cell(for flag: DeveloperFlag) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(flag.rawValue, isOn: binding(for: flag))
            Text(flag.description)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private func binding(for flag: DeveloperFlag) -> Binding<Bool> {
        var mutableFlag = flag
        return Binding(
            get: { mutableFlag.isOn },
            set: { newValue in
                mutableFlag.isOn = newValue
                if viewModel.flagsRequiringRestart.contains(flag) {
                    showRestartAlert = true
                }
            }
        )
    }
}

private enum FlagSection: String, CaseIterable {
    case authentication = "Authentication"
    case conversations = "Conversations"
    case diagnostics = "Diagnostics"
    case drive = "Drive"
    case encryption = "Encryption"
    case notifications = "Notifications & extensions"
    case storage = "Storage & backups"
    case synchronization = "Synchronization & background activity"

    init(flag: DeveloperFlag) {
        switch flag {
        case .newRegistration, .useWireAuthentication:
            self = .authentication
        case .channelsHistory, .chatBubbles, .showUnreadConversationsFilter:
            self = .conversations
        case .shakeToReport, .unSafeLogsForPublic:
            self = .diagnostics
        case .enableDriveBulkActions, .simulateDriveOffline, .simulateAppTerminationInBackground:
            self = .drive
        case .enabledCCDebugLogs, .forceCRLExpiryAfterOneMinute, .lowKeyPackageCount,
             .showCreateMLSGroupToggle, .simulateUnestablishedMLSGroup, .skipMLSMessagesDecryption:
            self = .encryption
        case .consumableNotifications, .noAPNSTokenCache, .showNSEErrors, .simulateMainAppRequiredError:
            self = .notifications
        case .createLegacyBackups, .debugDuplicateObjects, .forceDatabaseLoadingFailure:
            self = .storage
        case .decryptAndStoreEventsSleep, .disablePushChannelBatching, .ignoreIncomingEvents,
             .useBackgroundActivityFactoryInAppBackgroundTaskExecuter:
            self = .synchronization
        }
    }
}

// MARK: - Previews

struct DeveloperFlagsView_Previews: PreviewProvider {

    static var previews: some View {
        NavigationView {
            DeveloperFlagsView(viewModel: DeveloperFlagsViewModel())
        }
    }

}
