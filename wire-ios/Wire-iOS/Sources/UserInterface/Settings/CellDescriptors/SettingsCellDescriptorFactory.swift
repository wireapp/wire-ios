//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import SafariServices
import WireSyncEngine
import avs

class SettingsCellDescriptorFactory {
    static let settingsDevicesCellIdentifier: String = "devices"
    let settingsPropertyFactory: SettingsPropertyFactory
    let userRightInterfaceType: UserRightInterface.Type

    init(settingsPropertyFactory: SettingsPropertyFactory,
         userRightInterfaceType: UserRightInterface.Type = UserRight.self) {
        self.settingsPropertyFactory = settingsPropertyFactory
        self.userRightInterfaceType = userRightInterfaceType
    }

    func rootGroup(isTeamMember: Bool) -> SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType {
        var rootElements: [SettingsCellDescriptorType] = []

        if ZMUser.selfUser().canManageTeam {
            rootElements.append(self.manageTeamCell())
        }

        rootElements.append(settingsGroup(isTeamMember: isTeamMember))
        #if MULTIPLE_ACCOUNTS_DISABLED
            // We skip "add account" cell
        #else
            rootElements.append(self.addAccountOrTeamCell())
        #endif
        let topSection = SettingsSectionDescriptor(cellDescriptors: rootElements)

        return SettingsGroupCellDescriptor(items: [topSection],
                                           title: L10n.Localizable.Self.profile,
                                           style: .plain,
                                           accessibilityBackButtonText: L10n.Accessibility.Settings.BackButton.description)
    }

    func manageTeamCell() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(title: "self.settings.manage_team.title".localized,
                                                    isDestructive: false,
                                                    presentationStyle: PresentationStyle.modal,
                                                    identifier: nil,
                                                    presentationAction: { () -> (UIViewController?) in
                                                        return BrowserViewController(url: URL.manageTeam(source: .settings))
                                                    },
                                                    previewGenerator: nil,
                                                    icon: .team,
                                                    accessoryViewMode: .alwaysHide)
    }

    func addAccountOrTeamCell() -> SettingsCellDescriptorType {

        let presentationAction: () -> UIViewController? = {

            if SessionManager.shared?.accountManager.accounts.count < SessionManager.shared?.maxNumberAccounts {
                SessionManager.shared?.addAccount()
            } else {
                if let controller = UIApplication.shared.topmostViewController(onlyFullScreen: false) {
                    let alert = UIAlertController(
                        title: "self.settings.add_account.error.title".localized,
                        message: "self.settings.add_account.error.message".localized,
                        alertAction: .ok(style: .cancel))
                    controller.present(alert, animated: true, completion: nil)
                }
            }

            return nil
        }

        return SettingsExternalScreenCellDescriptor(title: "self.settings.add_team_or_account.title".localized,
                                                    isDestructive: false,
                                                    presentationStyle: PresentationStyle.modal,
                                                    identifier: nil,
                                                    presentationAction: presentationAction,
                                                    previewGenerator: nil,
                                                    icon: .plus,
                                                    accessoryViewMode: .alwaysHide)
    }

    func settingsGroup(isTeamMember: Bool) -> SettingsControllerGeneratorType & SettingsInternalGroupCellDescriptorType {
        var topLevelElements = [accountGroup(isTeamMember: isTeamMember),
                                devicesCell(),
                                optionsGroup,
                                advancedGroup,
                                helpSection(),
                                aboutSection()]

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
        return SettingsExternalScreenCellDescriptor(title: "self.settings.privacy_analytics_menu.devices.title".localized,
            isDestructive: false,
            presentationStyle: PresentationStyle.navigation,
            identifier: type(of: self).settingsDevicesCellIdentifier,
            presentationAction: { () -> (UIViewController?) in
                return ClientListViewController(clientsList: .none,
                                                credentials: .none,
                                                detailedView: true)
            },
            previewGenerator: { _ -> SettingsCellPreview in
                return SettingsCellPreview.badge(ZMUser.selfUser().clients.count)
            },
           icon: .devices)
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

        let section = SettingsSectionDescriptor(cellDescriptors: cells.map { $0 as SettingsCellDescriptorType }, header: "self.settings.sound_menu.ringtones.title".localized)

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

        let supportButton = SettingsExternalScreenCellDescriptor(title: "self.help_center.support_website".localized, isDestructive: false, presentationStyle: .modal, presentationAction: {
            return BrowserViewController(url: URL.wr_support.appendingLocaleParameter)
        }, previewGenerator: .none)

        let contactButton = SettingsExternalScreenCellDescriptor(title: "self.help_center.contact_support".localized, isDestructive: false, presentationStyle: .modal, presentationAction: {
            return BrowserViewController(url: URL.wr_askSupport.appendingLocaleParameter)
        }, previewGenerator: .none)

        let helpSection = SettingsSectionDescriptor(cellDescriptors: [supportButton, contactButton])

        let reportButton = SettingsExternalScreenCellDescriptor(title: "self.report_abuse".localized, isDestructive: false, presentationStyle: .modal, presentationAction: {
            return BrowserViewController(url: URL.wr_reportAbuse.appendingLocaleParameter)
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

        let privacyPolicyButton = SettingsExternalScreenCellDescriptor(title: "about.privacy.title".localized, isDestructive: false, presentationStyle: .modal, presentationAction: {
            return BrowserViewController(url: URL.wr_privacyPolicy.appendingLocaleParameter)
        }, previewGenerator: .none)
        let tosButton = SettingsExternalScreenCellDescriptor(title: "about.tos.title".localized, isDestructive: false, presentationStyle: .modal, presentationAction: {
            let url = URL.wr_termsOfServicesURL.appendingLocaleParameter
            return BrowserViewController(url: url)
        }, previewGenerator: .none)

        let shortVersion = Bundle.main.shortVersionString ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? "Unknown"

        var currentYear = NSCalendar.current.component(.year, from: Date())
        if currentYear < 2014 {
            currentYear = 2014
        }

        let version = String(format: "Version %@ (%@)", shortVersion, buildNumber)
        let copyrightInfo = String(format: "about.copyright.title".localized, currentYear)

        let linksSection = SettingsSectionDescriptor(
            cellDescriptors: [tosButton, privacyPolicyButton, licensesSection()],
            header: nil,
            footer: "\n" + version + "\n" + copyrightInfo
        )

        let websiteButton = SettingsExternalScreenCellDescriptor(title: "about.website.title".localized, isDestructive: false, presentationStyle: .modal, presentationAction: {
            return BrowserViewController(url: URL.wr_website.appendingLocaleParameter)
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

    func licensesSection() -> SettingsCellDescriptorType {
        guard let licenses = LicensesLoader.shared.loadLicenses() else {
            return webLicensesSection()
        }

        let childItems: [SettingsGroupCellDescriptor] = licenses.map { item in
            let projectCell = SettingsExternalScreenCellDescriptor(title: "about.license.open_project_button".localized, isDestructive: false, presentationStyle: .modal, presentationAction: {
                return BrowserViewController(url: item.projectURL)
            }, previewGenerator: .none)
            let detailsSection = SettingsSectionDescriptor(cellDescriptors: [projectCell], header: "about.license.project_header".localized, footer: nil)

            let licenseCell = SettingsStaticTextCellDescriptor(text: item.licenseText)
            let licenseSection = SettingsSectionDescriptor(cellDescriptors: [licenseCell], header: "about.license.license_header".localized, footer: nil)

            return SettingsGroupCellDescriptor(items: [detailsSection, licenseSection],
                                               title: item.name,
                                               style: .grouped,
                                               accessibilityBackButtonText: L10n.Accessibility.LicenseDetailsSettings.BackButton.description)
        }

        let licensesSection = SettingsSectionDescriptor(cellDescriptors: childItems)
        return SettingsGroupCellDescriptor(items: [licensesSection],
                                           title: L10n.Localizable.About.License.title,
                                           style: .plain,
                                           accessibilityBackButtonText: L10n.Accessibility.LicenseInformationSettings.BackButton.description)

    }

    func webLicensesSection() -> SettingsCellDescriptorType {
        return SettingsExternalScreenCellDescriptor(title: "about.license.title".localized, isDestructive: false, presentationStyle: .modal, presentationAction: {
            let url = URL.wr_licenseInformation.appendingLocaleParameter
            return BrowserViewController(url: url)
        }, previewGenerator: .none)
    }
}
