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

import WireCommonComponents
import WireLocators

extension SettingsCellDescriptorFactory {

    var notificationSoundGroup: any SettingsCellDescriptorType {
        let property = settingsPropertyFactory.property(.notificationSound)

        let cells = MessageNotificationSound.allCases.map { option in
            SettingsPropertySelectValueCellDescriptor(
                settingsProperty: property,
                value: .string(value: option.rawValue),
                title: option.title,
                identifier: option.accessibilityIdentifier
            )
        }

        let section = SettingsSectionDescriptor(
            cellDescriptors: cells.map { $0 as any SettingsCellDescriptorType }
        )

        return SettingsGroupCellDescriptor(
            items: [section],
            title: L10n.Localizable.Self.Settings.Notifications.Sound.title,
            identifier: Locators.OptionsOnSettingsPage.notificationSoundCell.rawValue,
            previewGenerator: { _ in
                guard
                    let rawValue = property.value().value() as? String,
                    let option = MessageNotificationSound(rawValue: rawValue)
                else {
                    return .text(MessageNotificationSound.wire.title)
                }

                return .text(option.title)
            },
            accessibilityBackButtonText: L10n.Accessibility.OptionsSettings.BackButton.description,
            settingsTopLevelMenuItem: nil,
            settingsCoordinator: settingsCoordinator,
            userSession: userSession
        )
    }
}

private extension MessageNotificationSound {
    var title: String {
        switch self {
        case .wire:
            L10n.Localizable.Self.Settings.Notifications.Sound.wire
        case .wireOld:
            L10n.Localizable.Self.Settings.Notifications.Sound.wireOld
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .wire:
            Locators.NotificationSoundSettingsPage.wireOption.rawValue
        case .wireOld:
            Locators.NotificationSoundSettingsPage.wireOldOption.rawValue
        }
    }
}
