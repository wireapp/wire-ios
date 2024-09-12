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
import SafariServices
import WireSyncEngine

struct SettingsCellDescriptorFactory {

    static let settingsDevicesCellIdentifier: String = "devices"

    var settingsPropertyFactory: SettingsPropertyFactory
    var userRightInterfaceType: UserRightInterface.Type

    func rootGroup(isPublicDomain: Bool, userSession: UserSession) -> SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType {
        var rootElements: [SettingsCellDescriptorType] = []

        if ZMUser.selfUser()?.canManageTeam == true {
            rootElements.append(manageTeamCell())
        }

        rootElements.append(settingsGroup(isPublicDomain: isPublicDomain, userSession: userSession))
        #if MULTIPLE_ACCOUNTS_DISABLED
            // We skip "add account" cell
        #else
            rootElements.append(addAccountOrTeamCell())
        #endif
        let topSection = SettingsSectionDescriptor(cellDescriptors: rootElements)

        return SettingsGroupCellDescriptor(items: [topSection],
                                           title: L10n.Localizable.Self.profile,
                                           style: .plain,
                                           accessibilityBackButtonText: L10n.Accessibility.Settings.BackButton.description)
    }

    func manageTeamCell() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(title: L10n.Localizable.Self.Settings.ManageTeam.title,
                                                    isDestructive: false,
                                                    presentationStyle: PresentationStyle.modal,
                                                    identifier: nil,
                                                    presentationAction: { () -> (UIViewController?) in
                                                        return BrowserViewController(url: URL.manageTeam(source: .settings))
                                                    },
                                                    previewGenerator: nil,
                                                    icon: .team,
                                                    accessoryViewMode: .alwaysHide,
                                                    copiableText: nil)
    }

    func addAccountOrTeamCell() -> SettingsCellDescriptorType {

        let sessionManager = SessionManager.shared

        let presentationAction: () -> UIViewController? = {
            if
                let count = sessionManager?.accountManager.accounts.count,
                let maxNumberAccounts = sessionManager?.maxNumberAccounts,
                count < maxNumberAccounts {
                sessionManager?.addAccount()
            } else {
                if let controller = UIApplication.shared.topmostViewController(onlyFullScreen: false) {
                    let alert = UIAlertController(
                        title: L10n.Localizable.Self.Settings.AddAccount.Error.title,
                        message: L10n.Localizable.Self.Settings.AddAccount.Error.message,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(
                        title: L10n.Localizable.General.ok,
                        style: .cancel
                    ))

                    controller.present(alert, animated: true, completion: nil)
                }
            }

            return nil
        }

        return SettingsExternalScreenCellDescriptor(title: L10n.Localizable.Self.Settings.AddTeamOrAccount.title,
                                                    isDestructive: false,
                                                    presentationStyle: PresentationStyle.modal,
                                                    identifier: nil,
                                                    presentationAction: presentationAction,
                                                    previewGenerator: nil,
                                                    icon: .plus,
                                                    accessoryViewMode: .alwaysHide,
                                                    copiableText: nil)
    }

    func settingsGroup(isPublicDomain: Bool, userSession: UserSession) -> SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType {
        var topLevelElements = [
            accountGroup(
                isPublicDomain: isPublicDomain,
                userSession: userSession
            ),
            devicesCell(),
            optionsGroup,
            advancedGroup(userSession: userSession),
            helpSection(),
            aboutSection()
        ]

        if Bundle.developerModeEnabled {
            topLevelElements.append(developerGroup)
        }

        let topSection = SettingsSectionDescriptor(cellDescriptors: topLevelElements)

        return SettingsGroupCellDescriptor(items: [topSection],
                                           title: L10n.Localizable.Self.settings,
                                           style: .plain,
                                           previewGenerator: .none,
                                           icon: .gear,
                                           accessibilityBackButtonText: L10n.Accessibility.Settings.BackButton.description)
    }

    func devicesCell() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(title: L10n.Localizable.Self.Settings.PrivacyAnalyticsMenu.Devices.title,
            isDestructive: false,
            presentationStyle: PresentationStyle.navigation,
            identifier: type(of: self).settingsDevicesCellIdentifier,
            presentationAction: { () -> (UIViewController?) in
                return ClientListViewController(clientsList: .none,
                                                credentials: .none,
                                                detailedView: true)
            },
            previewGenerator: { _ -> SettingsCellPreview in
                return SettingsCellPreview.badge(ZMUser.selfUser()?.clients.count ?? 0)
            },
           icon: .devices, copiableText: nil)
    }

    func soundGroupForSetting(_ settingsProperty: SettingsProperty, title: String, customSounds: [ZMSound], defaultSound: ZMSound) -> SettingsCellDescriptorType {
        let items: [ZMSound] = [ZMSound.None, defaultSound] + customSounds
        let previewPlayer: SoundPreviewPlayer = SoundPreviewPlayer(mediaManager: AVSMediaManager.sharedInstance())

        let cells: [SettingsPropertySelectValueCellDescriptor] = items.map { item in
            let playSoundAction: SettingsPropertySelectValueCellDescriptor.SelectActionType = { _ in

                switch settingsProperty.propertyName {
                case .callSoundName:
                    previewPlayer.playPreview(.ringingFromThemSound)
                case .pingSoundName:
                    previewPlayer.playPreview(.incomingKnockSound)
                case .messageSoundName:
                    previewPlayer.playPreview(.messageReceivedSound)
                default:
                    break
                }
            }

            let propertyValue = item == defaultSound ? SettingsPropertyValue.none : SettingsPropertyValue.string(value: item.rawValue)
            return SettingsPropertySelectValueCellDescriptor(settingsProperty: settingsProperty, value: propertyValue, title: item.descriptionLocalizationKey.localized, identifier: .none, selectAction: playSoundAction)
        }

        let section = SettingsSectionDescriptor(cellDescriptors: cells.map { $0 as SettingsCellDescriptorType }, header: L10n.Localizable.Self.Settings.SoundMenu.Ringtones.title)

        let previewGenerator: PreviewGeneratorType = { _ in
            let value = settingsProperty.value()

            if let stringValue = value.value() as? String,
                let enumValue = ZMSound(rawValue: stringValue) {
                return .text(enumValue.descriptionLocalizationKey.localized)
            } else {
                return .text(defaultSound.descriptionLocalizationKey.localized)
            }
        }

        return SettingsGroupCellDescriptor(items: [section],
                                           title: title,
                                           identifier: .none,
                                           previewGenerator: previewGenerator,
                                           accessibilityBackButtonText: L10n.Accessibility.OptionsSettings.BackButton.description)
    }

    func helpSection() -> SettingsCellDescriptorType {
        let supportButton = SettingsExternalScreenCellDescriptor(title: L10n.Localizable.Self.HelpCenter.supportWebsite, isDestructive: false, presentationStyle: .modal, presentationAction: {
            return BrowserViewController(url: WireURLs.shared.support)
        }, previewGenerator: .none)

        let contactButton = SettingsExternalScreenCellDescriptor(title: L10n.Localizable.Self.HelpCenter.contactSupport, isDestructive: false, presentationStyle: .modal, presentationAction: {
            return BrowserViewController(url: WireURLs.shared.askSupportArticle)
        }, previewGenerator: .none)

        let helpSection = SettingsSectionDescriptor(cellDescriptors: [supportButton, contactButton])

        let reportButton = SettingsExternalScreenCellDescriptor(title: L10n.Localizable.Self.reportAbuse, isDestructive: false, presentationStyle: .modal, presentationAction: {
            return BrowserViewController(url: WireURLs.shared.reportAbuse)
        }, previewGenerator: .none)

        let reportSection = SettingsSectionDescriptor(cellDescriptors: [reportButton])

        return SettingsGroupCellDescriptor(items: [helpSection, reportSection],
                                           title: L10n.Localizable.Self.helpCenter,
                                           style: .grouped, identifier: .none,
                                           previewGenerator: .none,
                                           icon: .settingsSupport,
                                           accessibilityBackButtonText: L10n.Accessibility.SupportSettings.BackButton.description)
    }

    func aboutSection() -> SettingsCellDescriptorType {

        let legalButton = SettingsExternalScreenCellDescriptor(
            title: L10n.Localizable.About.Legal.title,
            isDestructive: false,
            presentationStyle: .modal,
            presentationAction: {
                BrowserViewController(url: WireURLs.shared.legal)
            },
            previewGenerator: .none
        )

        let shortVersion = Bundle.main.shortVersionString ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? "Unknown"

        var currentYear = NSCalendar.current.component(.year, from: Date())
        if currentYear < 2014 {
            currentYear = 2014
        }

        let version = String(format: "Version %@ (%@)", shortVersion, buildNumber)
        let copyrightInfo = String(format: L10n.Localizable.About.Copyright.title, currentYear)

        let linksSection = SettingsSectionDescriptor(
            cellDescriptors: [legalButton],
            header: nil,
            footer: "\n" + version + "\n" + copyrightInfo
        )
        let websiteButton = SettingsExternalScreenCellDescriptor(title: L10n.Localizable.About.Website.title, isDestructive: false, presentationStyle: .modal, presentationAction: {
            return BrowserViewController(url: WireURLs.shared.website)
        }, previewGenerator: .none)

        let websiteSection = SettingsSectionDescriptor(cellDescriptors: [websiteButton])

        return SettingsGroupCellDescriptor(
            items: [websiteSection, linksSection],
            title: L10n.Localizable.Self.about,
            style: .grouped,
            identifier: .none,
            previewGenerator: .none,
            icon: .about,
            accessibilityBackButtonText: L10n.Accessibility.AboutSettings.BackButton.description
        )
    }
}
