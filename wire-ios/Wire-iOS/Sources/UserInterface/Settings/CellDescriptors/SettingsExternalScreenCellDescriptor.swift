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
import WireDesign
import WireSettingsUI

class SettingsExternalScreenCellDescriptor: SettingsGroupCellDescriptorType, SettingsControllerGeneratorType {
    static let cellType: SettingsTableCellProtocol.Type = SettingsTableCell.self
    var visible: Bool = true
    let title: String
    let destructive: Bool
    let presentationStyle: PresentationStyle
    let identifier: String?
    let icon: StyleKitIcon?
    var copiableText: String?

    let settingsTopLevelMenuItem: SettingsTopLevelMenuItem?

    private let accessoryView: AccessoryView?

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
            copiableText: nil,
            settingsTopLevelMenuItem: nil
        )
    }

    convenience init(
        title: String,
        isDestructive: Bool,
        presentationStyle: PresentationStyle,
        presentationAction: @escaping () -> (UIViewController?),
        previewGenerator: PreviewGeneratorType? = .none,
        icon: StyleKitIcon? = nil,
        accessoryView: AccessoryView? = .automatic,
        copiableText: String? = nil
    ) {
        self.init(
            title: title,
            isDestructive: isDestructive,
            presentationStyle: presentationStyle,
            identifier: nil,
            presentationAction: presentationAction,
            previewGenerator: previewGenerator,
            icon: icon,
            accessoryView: accessoryView,
            copiableText: copiableText,
            settingsTopLevelMenuItem: nil
        )
    }

    init(
        title: String,
        isDestructive: Bool,
        presentationStyle: PresentationStyle,
        identifier: String?,
        presentationAction: @escaping () -> (UIViewController?),
        previewGenerator: PreviewGeneratorType? = .none,
        icon: StyleKitIcon? = nil,
        accessoryView: AccessoryView? = .automatic,
        copiableText: String?,
        settingsTopLevelMenuItem: SettingsTopLevelMenuItem?
    ) {
        self.title = title
        self.destructive = isDestructive
        self.presentationStyle = presentationStyle
        self.presentationAction = presentationAction
        self.identifier = identifier
        self.previewGenerator = previewGenerator
        self.icon = icon
        self.accessoryView = accessoryView
        self.copiableText = copiableText
        self.settingsTopLevelMenuItem = settingsTopLevelMenuItem
    }

    func select(_ value: SettingsPropertyValue, sender: UIView) {
        guard let controllerToShow = generateViewController() else {
            return
        }

        switch presentationStyle {
        case .modal:
            if controllerToShow.modalPresentationStyle == .popover,
               let sourceView = viewController?.view,
               let popoverPresentation = controllerToShow.popoverPresentationController {
                popoverPresentation.sourceView = sourceView
                popoverPresentation.sourceRect = sourceView.bounds
            }

            controllerToShow.modalPresentationCapturesStatusBarAppearance = true
            viewController?.present(controllerToShow, animated: true, completion: .none)
        case .navigation:
            controllerToShow.hidesBottomBarWhenPushed = true
            viewController?.navigationController?.pushViewController(controllerToShow, animated: true)
        case .alert:
            break
        }
    }

    func featureCell(_ cell: SettingsCellType) {
        cell.titleText = title

        if let tableCell = cell as? SettingsTableCell {
            tableCell.valueLabel.accessibilityIdentifier = title + "Field"
            tableCell.valueLabel.isAccessibilityElement = true
        }

        if let previewGenerator {
            let preview = previewGenerator(self)
            cell.preview = preview
        }
        cell.icon = icon
        if let groupCell = cell as? SettingsTableCell {
            switch accessoryView {
            case .automatic:
                if presentationStyle == .modal {
                    groupCell.hideAccessoryView()
                } else {
                    groupCell.showDisclosureIndicatorAccessoryView()
                }
            case .disclosureIndicator:
                groupCell.showDisclosureIndicatorAccessoryView()
            case .externalLink:
                groupCell.showExternalLinkAccessoryView()
            case .none:
                groupCell.hideAccessoryView()
            }
        }
    }

    func generateViewController() -> UIViewController? {
        presentationAction()
    }

}
