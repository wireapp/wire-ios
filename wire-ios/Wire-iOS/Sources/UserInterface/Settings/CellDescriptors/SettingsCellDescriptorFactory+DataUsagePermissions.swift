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

extension SettingsCellDescriptorFactory {
    func dataUsagePermissionsGroup(isTeamMember: Bool) -> SettingsCellDescriptorType {

        var items: [SettingsSectionDescriptor] = []

        // show analytics toggle for team members only
        if isTeamMember {
            let sendAnalyticsData = SettingsPropertyToggleCellDescriptor(settingsProperty: settingsPropertyFactory.property(.disableAnalyticsSharing), inverse: true)
            let sendAnalyticsDataSection = SettingsSectionDescriptor(cellDescriptors: [sendAnalyticsData], footer: L10n.Localizable.Self.Settings.PrivacyAnalyticsMenu.Description.title)

            items.append(sendAnalyticsDataSection)
        }

        return SettingsGroupCellDescriptor(
            items: items,
            title: L10n.Localizable.Self.Settings.Account.DataUsagePermissions.title,
            accessibilityBackButtonText: L10n.Accessibility.AccountSettings.BackButton.description
        )
    }
}
