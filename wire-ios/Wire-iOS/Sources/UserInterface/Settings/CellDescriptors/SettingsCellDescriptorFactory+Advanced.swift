//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import UIKit
import WireSyncEngine

extension SettingsCellDescriptorFactory {

    typealias SelfSettingsAdvancedLocale = L10n.Localizable.Self.Settings.Advanced

    // MARK: - Advanced group
    func advancedGroup(userSession: UserSession) -> SettingsCellDescriptorType {
        let items = [
            troubleshootingSection(userSession: userSession),
            debuggingToolsSection,
            pushSection,
            versionSection
        ]

        return SettingsGroupCellDescriptor(
            items: items,
            title: SelfSettingsAdvancedLocale.title,
            icon: .settingsAdvanced,
            accessibilityBackButtonText: L10n.Accessibility.AdvancedSettings.BackButton.description
        )
    }

    // MARK: - Sections
    private func troubleshootingSection(userSession: UserSession) -> SettingsSectionDescriptor {
        let submitDebugButton = SettingsExternalScreenCellDescriptor(
            title: SelfSettingsAdvancedLocale.Troubleshooting.SubmitDebug.title,
            presentationAction: { () -> (UIViewController?) in
                let router = SettingsDebugReportRouter()
                let shareFile = ShareFileUseCase(contextProvider: userSession.contextProvider)
                let fetchShareableConversations = FetchShareableConversationsUseCase(contextProvider: userSession.contextProvider)
                let viewModel = SettingsDebugReportViewModel(
                    router: router,
                    shareFile: shareFile,
                    fetchShareableConversations: fetchShareableConversations
                )
                let viewController = SettingsDebugReportViewController(viewModel: viewModel)
                router.viewController = viewController
                return viewController
        })

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
            presentationStyle: PresentationStyle.modal,
            presentationAction: { () -> (UIViewController?) in
                ZMUserSession.shared()?.validatePushToken()
                return self.pushButtonAlertController
        })

        return SettingsSectionDescriptor(
            cellDescriptors: [pushButton],
            header: .none,
            footer: SelfSettingsAdvancedLocale.ResetPushToken.subtitle,
            visibilityAction: { _ in
                return true
        })
    }

    private var versionSection: SettingsSectionDescriptor {
        let versionCell = SettingsButtonCellDescriptor(
            title: SelfSettingsAdvancedLocale.VersionTechnicalDetails.title,
            isDestructive: false,
            selectAction: presentVersionAction
        )

        return SettingsSectionDescriptor(cellDescriptors: [versionCell])
    }

    private var debuggingToolsSection: SettingsSectionDescriptor {

        let findUnreadConversationSection = SettingsSectionDescriptor(cellDescriptors: [
            SettingsButtonCellDescriptor(
                title: SelfSettingsAdvancedLocale.DebuggingTools.FirstUnreadConversation.title,
                isDestructive: false,
                selectAction: DebugActions.findUnreadConversationContributingToBadgeCount
            ),
            SettingsButtonCellDescriptor(
                title: SelfSettingsAdvancedLocale.DebuggingTools.ShowUserId.title,
                isDestructive: false,
                selectAction: DebugActions.showUserId
            ),
            SettingsButtonCellDescriptor(
                title: SelfSettingsAdvancedLocale.DebuggingTools.EnterDebugCommand.title,
                isDestructive: false,
                selectAction: DebugActions.enterDebugCommand
            )
        ])

        // Inner group
        let debuggingToolsGroup = SettingsGroupCellDescriptor(
            items: [findUnreadConversationSection],
            title: L10n.Localizable.Self.Settings.Advanced.DebuggingTools.title,
            accessibilityBackButtonText: L10n.Accessibility.AdvancedSettings.BackButton.description
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

    private var presentVersionAction: (SettingsCellDescriptorType) -> Void {
        return { _ in
            let versionInfoViewController = VersionInfoViewController()
            var superViewController = UIApplication.shared.firstKeyWindow?.rootViewController

            if let presentedViewController = superViewController?.presentedViewController {
                superViewController = presentedViewController
                versionInfoViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                versionInfoViewController.navigationController?.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            }

            superViewController?.present(versionInfoViewController, animated: true, completion: .none)
        }
    }
}
