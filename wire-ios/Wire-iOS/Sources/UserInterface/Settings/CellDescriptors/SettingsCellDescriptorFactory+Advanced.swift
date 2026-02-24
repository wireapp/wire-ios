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

import UIKit
import WireCommonComponents
import WireMainNavigationUI
import WireSyncEngine

extension SettingsCellDescriptorFactory {

    typealias SelfSettingsAdvancedLocale = L10n.Localizable.Self.Settings.Advanced

    // MARK: - Advanced group

    func advancedGroup(
        userSession: UserSession,
        mainCoordinator: any MainCoordinatorProtocol
    ) -> any SettingsCellDescriptorType {
        let items = [
            troubleshootingSection(userSession: userSession, mainCoordinator: mainCoordinator),
            debuggingToolsSection,
            pushSection
        ]

        return SettingsGroupCellDescriptor(
            items: items,
            title: SelfSettingsAdvancedLocale.title,
            icon: .settingsAdvanced,
            accessibilityBackButtonText: L10n.Accessibility.AdvancedSettings.BackButton.description,
            settingsTopLevelMenuItem: .advanced,
            settingsCoordinator: settingsCoordinator,
            userSession: userSession
        )
    }

    // MARK: - Sections

    private func troubleshootingSection(
        userSession: UserSession,
        mainCoordinator: any MainCoordinatorProtocol
    ) -> SettingsSectionDescriptor {
        let submitDebugButton = SettingsExternalScreenCellDescriptor(
            title: SelfSettingsAdvancedLocale.Troubleshooting.SubmitDebug.title,
            presentationAction: { () -> (UIViewController?) in
                let router = SettingsDebugReportRouter(mainCoordinator: mainCoordinator)
                let shareFile = ShareFileUseCase(contextProvider: userSession.contextProvider)
                let fetchShareableConversations = FetchShareableConversationsUseCase(
                    contextProvider: userSession
                        .contextProvider
                )
                let viewModel = SettingsDebugReportViewModel(
                    router: router,
                    shareFile: shareFile,
                    fetchShareableConversations: fetchShareableConversations,
                    fileMetaDataGenerator: FileMetaDataGenerator()
                )
                let viewController = SettingsDebugReportViewController(viewModel: viewModel)
                router.viewController = viewController
                return viewController
            }
        )

        return SettingsSectionDescriptor(
            cellDescriptors: [submitDebugButton],
            header: SelfSettingsAdvancedLocale.Troubleshooting.title,
            footer: SelfSettingsAdvancedLocale.Troubleshooting.SubmitDebug.subtitle
        )
    }

    private var pushSection: SettingsSectionDescriptor {
        let pushButton = SettingsExternalScreenCellDescriptor(
            title: SelfSettingsAdvancedLocale.ResetPushToken.title,
            isDestructive: false,
            presentationStyle: .modal,
            presentationAction: { [userSession] () -> (UIViewController?) in
                (userSession as? ZMUserSession)?.validatePushToken()
                return self.pushButtonAlertController
            }
        )

        return SettingsSectionDescriptor(
            cellDescriptors: [pushButton],
            header: .none,
            footer: SelfSettingsAdvancedLocale.ResetPushToken.subtitle,
            visibilityAction: { _ in
                true
            }
        )
    }

    private var debuggingToolsSection: SettingsSectionDescriptor {

        let findUnreadConversationSection = SettingsSectionDescriptor(cellDescriptors: [
            SettingsButtonCellDescriptor(
                title: SelfSettingsAdvancedLocale.DebuggingTools.FirstUnreadConversation.title,
                isDestructive: false,
                selectAction: { [userSession] _ in
                    guard let session = userSession as? ZMUserSession else { return }
                    DebugActions.findUnreadConversationContributingToBadgeCount(userSession: session)
                }
            ),
            SettingsButtonCellDescriptor(
                title: SelfSettingsAdvancedLocale.DebuggingTools.EnterDebugCommand.title,
                isDestructive: false,
                selectAction: { [userSession] _ in
                    guard let session = userSession as? ZMUserSession else { return }
                    DebugActions.enterDebugCommand(userSession: session)
                }
            )
        ])

        // Inner group
        let debuggingToolsGroup = SettingsGroupCellDescriptor(
            items: [findUnreadConversationSection],
            title: L10n.Localizable.Self.Settings.Advanced.DebuggingTools.title,
            accessibilityBackButtonText: L10n.Accessibility.AdvancedSettings.BackButton.description,
            settingsTopLevelMenuItem: nil,
            settingsCoordinator: settingsCoordinator,
            userSession: userSession
        )

        // Section
        return SettingsSectionDescriptor(cellDescriptors: [debuggingToolsGroup])
    }

    // MARK: - Helpers

    private var pushButtonAlertController: UIAlertController {
        let alert = UIAlertController(
            title: SelfSettingsAdvancedLocale.ResetPushTokenAlert.title,
            message: SelfSettingsAdvancedLocale.ResetPushTokenAlert.message,
            preferredStyle: .alert
        )

        let action = UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .default,
            handler: { [weak alert] _ in
                alert?.dismiss(animated: true, completion: nil)
            }
        )

        alert.addAction(action)

        return alert
    }
}
