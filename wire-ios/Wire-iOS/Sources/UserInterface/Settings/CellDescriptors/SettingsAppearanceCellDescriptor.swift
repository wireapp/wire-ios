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

import MobileCoreServices
import UIKit
import WireSettingsUI
import WireSyncEngine

class SettingsAppearanceCellDescriptor: SettingsCellDescriptorType, SettingsExternalScreenCellDescriptorType {
    static let cellType: SettingsTableCellProtocol.Type = SettingsAppearanceCell.self

    private var text: String
    private let presentationStyle: PresentationStyle

    weak var viewController: UIViewController?
    let presentationAction: () -> (UIViewController?)

    var identifier: String?
    weak var group: SettingsGroupCellDescriptorType?
    var previewGenerator: PreviewGeneratorType?

    let settingsCoordinator: AnySettingsCoordinator

    var visible: Bool {
        return true
    }

    var title: String {
        return text
    }

    init(
        text: String,
        previewGenerator: PreviewGeneratorType? = .none,
        presentationStyle: PresentationStyle,
        presentationAction: @escaping () -> (UIViewController?),
        settingsCoordinator: AnySettingsCoordinator
    ) {
        self.text = text
        self.previewGenerator = previewGenerator
        self.presentationStyle = presentationStyle
        self.presentationAction = presentationAction
        self.settingsCoordinator = settingsCoordinator
    }

    // MARK: - Configuration

    func featureCell(_ cell: SettingsCellType) {
        if let tableCell = cell as? SettingsAppearanceCell {
            tableCell.configure(with: .appearance(title: text))

            if let previewGenerator = self.previewGenerator {
                tableCell.type = previewGenerator(self)
            }
            switch self.presentationStyle {
            case .modal, .alert:
                tableCell.isAccessoryIconHidden = false
                tableCell.hideDisclosureIndicator()
            case .navigation:
                tableCell.isAccessoryIconHidden = true
                tableCell.showDisclosureIndicator()
            }
        }
    }

    // MARK: - SettingsCellDescriptorType

    func select(_ value: SettingsPropertyValue, sender: UIView) {
        guard let controllerToShow = generateViewController() else { return }

        switch presentationStyle {
        case .alert:
            if let popoverPresentationController = controllerToShow.popoverPresentationController {
                popoverPresentationController.sourceView = sender.superview
                popoverPresentationController.sourceRect = sender.frame
            }
            viewController?.present(controllerToShow, animated: true)
        case .navigation:
            viewController?.navigationController?.pushViewController(controllerToShow, animated: true)
        case .modal:
            break
        }
    }

    func generateViewController() -> UIViewController? {
        presentationAction()
    }
}
