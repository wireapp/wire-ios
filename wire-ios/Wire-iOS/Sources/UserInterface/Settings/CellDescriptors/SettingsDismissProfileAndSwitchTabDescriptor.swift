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

import UIKit
import WireDesign
import WireMainNavigation

final class SettingsDismissProfileAndSwitchTabDescriptor: SettingsExternalScreenCellDescriptorType {

    static let cellType: SettingsTableCellProtocol.Type = SettingsTableCell.self

    var visible: Bool = true
    let title: String
    let identifier: String?
    let icon: StyleKitIcon?
    let targetTab: MainTabBarController<UIViewController, UIViewController, UIViewController, UIViewController>.Tab

    weak var group: SettingsGroupCellDescriptorType?
    weak var viewController: UIViewController?

    let presentationAction: () -> (UIViewController?) = { nil }

    init(
        title: String,
        identifier: String?,
        icon: StyleKitIcon? = nil,
        targetTab: MainTabBarController<UIViewController, UIViewController, UIViewController, UIViewController>.Tab
    ) {
        self.title = title
        self.identifier = identifier
        self.icon = icon
        self.targetTab = targetTab
    }

    func select(_ value: SettingsPropertyValue, sender: UIView) {

        // dismiss the profile and switch to the settings tab

        guard
            let presenter = viewController?.presentingViewController as? UIViewController, // TODO: something got merged wrong here
            let zClientViewController = presenter.children.compactMap({ $0 as? ZClientViewController }).first,
            let tabBarController = zClientViewController.mainTabBarController
        else { return assertionFailure("Wrong assumptions about the VC presentation") }

        presenter.dismiss(animated: true) {
            tabBarController.selectedIndex = self.targetTab.rawValue
        }
    }

    func featureCell(_ cell: SettingsCellType) {

        cell.titleText = title
        cell.icon = icon

        if let cell = cell as? SettingsTableCell {
            cell.valueLabel.accessibilityIdentifier = title + "Field"
            cell.valueLabel.isAccessibilityElement = true
            cell.hideDisclosureIndicator()
        }
    }
}
