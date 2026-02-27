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
import SwiftUI
import WireSyncEngine

extension SettingsCellDescriptorFactory {

    var developerGroup: any SettingsCellDescriptorType {
        typealias ExternalScreen = SettingsExternalScreenCellDescriptor
        typealias Toggle = SettingsPropertyToggleCellDescriptor
        typealias Button = SettingsButtonCellDescriptor

        var developerCellDescriptors: [any SettingsCellDescriptorType] = []

        developerCellDescriptors.append(
            Toggle(settingsProperty: settingsPropertyFactory.property(.enableBatchCollections))
        )

        developerCellDescriptors.append(
            Button(
                title: "Send broken message",
                isDestructive: true,
                selectAction: { [weak userSession] _ in
                    guard let session = userSession as? ZMUserSession else { return }
                    DebugActions.sendBrokenMessage(userSession: session)
                }
            )
        )

        developerCellDescriptors.append(
            Button(
                title: "First unread conversation (badge count)",
                isDestructive: false,
                selectAction: { [weak userSession] _ in
                    guard let session = userSession as? ZMUserSession else { return }
                    DebugActions.findUnreadConversationContributingToBadgeCount(userSession: session)
                }
            )
        )

        developerCellDescriptors.append(
            Button(
                title: "First unread conversation (back arrow count)",
                isDestructive: false,
                selectAction: { [weak userSession] _ in
                    guard let session = userSession as? ZMUserSession else { return }
                    DebugActions.findUnreadConversationContributingToBackArrowDot(userSession: session)
                }
            )
        )

        developerCellDescriptors.append(
            Button(
                title: "Delete invalid conversations",
                isDestructive: false,
                selectAction: { [weak userSession] _ in
                    guard let session = userSession as? ZMUserSession else { return }
                    DebugActions.deleteInvalidConversations(userSession: session)
                }
            )
        )

        developerCellDescriptors.append(SettingsShareDatabaseCellDescriptor(userSession: userSession))

        developerCellDescriptors.append(
            Button(
                title: "Reload user interface",
                isDestructive: false,
                selectAction: DebugActions.reloadUserInterface
            )
        )

        developerCellDescriptors.append(
            Button(
                title: "Re-calculate badge count",
                isDestructive: false,
                selectAction: { [weak userSession] _ in
                    guard let session = userSession as? ZMUserSession else { return }
                    DebugActions.recalculateBadgeCount(userSession: session)
                }
            )
        )

        developerCellDescriptors.append(
            Button(title: "Append N messages to the top conv (not sending)", isDestructive: true) { [weak userSession] _ in
                guard let session = userSession as? ZMUserSession else { return }
                DebugActions.askNumber(title: "Enter count of messages") { count in
                    DebugActions.appendMessagesInBatches(count: count, userSession: session)
                }
            }
        )

        developerCellDescriptors.append(
            Button(title: "Spam the top conv", isDestructive: true) { [weak userSession] _ in
                guard let session = userSession as? ZMUserSession else { return }
                DebugActions.askNumber(title: "Enter count of messages") { count in
                    DebugActions.spamWithMessages(amount: count, userSession: session)
                }
            }
        )

        developerCellDescriptors.append(
            ExternalScreen(
                title: "Show database statistics",
                isDestructive: false,
                presentationStyle: .navigation,
                presentationAction: { [weak userSession] in
                    guard let userSession = userSession else { return nil }
                    return DatabaseStatisticsController(userSession: userSession)
                }
            )
        )

        developerCellDescriptors.append(
            Button(
                title: "Reset call quality survey",
                isDestructive: false,
                selectAction: DebugActions.resetCallQualitySurveyMuteFilter
            )
        )

        developerCellDescriptors.append(
            Button(
                title: "Trigger slow sync",
                isDestructive: false,
                selectAction: { [weak userSession] _ in
                    guard let session = userSession as? ZMUserSession else { return }
                    DebugActions.triggerSlowSync(userSession: session)
                }
            )
        )

        developerCellDescriptors.append(
            Button(
                title: "Trigger resyncResources",
                isDestructive: false,
                selectAction: { [weak userSession] _ in
                    guard let session = userSession as? ZMUserSession else { return }
                    DebugActions.triggerResyncResources(userSession: session)
                }
            )
        )

        return SettingsGroupCellDescriptor(
            items: [SettingsSectionDescriptor(cellDescriptors: developerCellDescriptors)],
            title: L10n.Localizable.Self.Settings.DeveloperOptions.title,
            icon: .robot,
            accessibilityBackButtonText: L10n.Accessibility.DeveloperOptionsSettings.BackButton.description,
            settingsTopLevelMenuItem: .developerOptions,
            settingsCoordinator: settingsCoordinator,
            userSession: userSession
        )
    }

}
