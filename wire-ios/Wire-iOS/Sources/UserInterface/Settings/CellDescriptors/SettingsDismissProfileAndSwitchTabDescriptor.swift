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
import WireCommonComponents

final class SettingsDismissProfileAndSwitchTabDescriptor_: SettingsExternalScreenCellDescriptorType /*SettingsControllerGeneratorType*/ {
    static let cellType: SettingsTableCellProtocol.Type = SettingsTableCell.self
    var visible: Bool = true
    let title: String
    let destructive: Bool
    let presentationStyle: PresentationStyle
    let identifier: String?
    let icon: StyleKitIcon?
    var copiableText: String?

    private let accessoryViewMode: AccessoryViewMode

    weak var group: SettingsGroupCellDescriptorType?
    weak var viewController: UIViewController?

    let previewGenerator: PreviewGeneratorType?

    let presentationAction: () -> (UIViewController?)

    convenience init(title: String, presentationAction: @escaping () -> (UIViewController?)) {
        self.init(
            title: title,
            isDestructive: false,
            presentationStyle: .navigation,
            identifier: nil,
            presentationAction: presentationAction,
            previewGenerator: nil,
            icon: .none,
            copiableText: nil
        )
    }

    convenience init(title: String,
                     isDestructive: Bool,
                     presentationStyle: PresentationStyle,
                     presentationAction: @escaping () -> (UIViewController?),
                     previewGenerator: PreviewGeneratorType? = .none,
                     icon: StyleKitIcon? = nil,
                     accessoryViewMode: AccessoryViewMode = .default,
                     copiableText: String? = nil) {
        self.init(
            title: title,
            isDestructive: isDestructive,
            presentationStyle: presentationStyle,
            identifier: nil,
            presentationAction: presentationAction,
            previewGenerator: previewGenerator,
            icon: icon,
            accessoryViewMode: accessoryViewMode,
            copiableText: copiableText
        )
    }

    init(title: String,
         isDestructive: Bool,
         presentationStyle: PresentationStyle,
         identifier: String?,
         presentationAction: @escaping () -> (UIViewController?),
         previewGenerator: PreviewGeneratorType? = .none,
         icon: StyleKitIcon? = nil,
         accessoryViewMode: AccessoryViewMode = .default,
         copiableText: String?) {

        self.title = title
        self.destructive = isDestructive
        self.presentationStyle = presentationStyle
        self.presentationAction = presentationAction
        self.identifier = identifier
        self.previewGenerator = previewGenerator
        self.icon = icon
        self.accessoryViewMode = accessoryViewMode
        self.copiableText = copiableText
    }

    func select(_ value: SettingsPropertyValue?) {

        // dismiss the profile and switch to the settings tab

        guard
            let presenter = viewController?.presentingViewController as? RootViewController,
            let zClientViewController = presenter.children.compactMap({ $0 as? ZClientViewController }).first,
            let tabBarController = zClientViewController.mainTabBarController
        else { return assertionFailure("Wrong assumptions about the VC presentation") }

        presenter.dismiss(animated: true) {
            tabBarController.selectedIndex = MainTabBarControllerTab.settings.rawValue
        }
    }

    func featureCell(_ cell: SettingsCellType) {
        cell.titleText = title
        cell.icon = icon

        guard let cell = cell as? SettingsTableCell else { return }

        cell.valueLabel.accessibilityIdentifier = title + "Field"
        cell.valueLabel.isAccessibilityElement = true
        cell.hideDisclosureIndicator()
    }
}

final class SettingsDismissProfileAndSwitchTabDescriptor: SettingsCellDescriptorType {
    static let cellType: SettingsTableCellProtocol.Type = SettingsLinkTableCell.self

    // MARK: - Configuration

    func featureCell(_ cell: SettingsCellType) {
        guard let cell = cell as? SettingsLinkTableCell else { return assertionFailure() }

        // cell.linkText = link && .lineSpacing(8)
        cell.titleText = title

//        cell.titleText = self.title
//
//        if let tableCell = cell as? SettingsTableCell {
//            tableCell.valueLabel.accessibilityIdentifier = title + "Field"
//            tableCell.valueLabel.isAccessibilityElement = true
//        }
//
//        if let previewGenerator = self.previewGenerator {
//            let preview = previewGenerator(self)
//            cell.preview = preview
//        }
//        cell.icon = self.icon
//        if let groupCell = cell as? SettingsTableCell {
//            switch accessoryViewMode {
//            case .default:
//                if self.presentationStyle == .modal {
//                    groupCell.hideDisclosureIndicator()
//                } else {
//                    groupCell.showDisclosureIndicator()
//                }
//            case .alwaysHide:
//                groupCell.hideDisclosureIndicator()
//            case .alwaysShow:
//                groupCell.showDisclosureIndicator()
//            }
//        }
    }

    // MARK: - SettingsCellDescriptorType

    var visible: Bool {
        return true
    }

    var title: String {
        return L10n.Localizable.Self.settings
    }

    var identifier: String?
    weak var group: SettingsGroupCellDescriptorType?
    var previewGenerator: PreviewGeneratorType?

    func select(_ value: SettingsPropertyValue?) {
        // no-op
    }
}
