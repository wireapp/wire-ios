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
import WireUtilities

private let zmLog = ZMSLog(tag: "UI")

// MARK: - SettingsPropertyTextValueCellDescriptor

final class SettingsPropertyTextValueCellDescriptor: SettingsPropertyCellDescriptorType {
    // MARK: Lifecycle

    init(settingsProperty: SettingsProperty, identifier: String? = .none) {
        self.settingsProperty = settingsProperty
        self.identifier = identifier
    }

    // MARK: Internal

    static let cellType: SettingsTableCellProtocol.Type = SettingsTextCell.self

    var visible = true
    let identifier: String?
    weak var group: SettingsGroupCellDescriptorType?
    var settingsProperty: SettingsProperty

    var title: String {
        settingsProperty.propertyName.settingsPropertyLabelText
    }

    func featureCell(_ cell: SettingsCellType) {
        cell.titleText = title
        guard let textCell = cell as? SettingsTextCell else {
            return
        }

        if let stringValue = settingsProperty.rawValue() as? String {
            textCell.textInput.text = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if settingsProperty.enabled {
            textCell.textInput.accessibilityTraits.remove(.staticText)
            textCell.textInput.accessibilityIdentifier = title + "Field"
        } else {
            textCell.textInput.accessibilityTraits.insert(.staticText)
            textCell.textInput.accessibilityIdentifier = title + "FieldDisabled"
        }

        textCell.textInput.isEnabled = settingsProperty.enabled
        textCell.textInput.isAccessibilityElement = true
    }

    func select(_ value: SettingsPropertyValue, sender: UIView) {
        if let stringValue = value.value() as? String {
            do {
                try settingsProperty << SettingsPropertyValue.string(value: stringValue)
            } catch let error as NSError {
                // specific error message for name string is too short
                if error.domain == ZMObjectValidationErrorDomain,
                   error.code == ZMManagedObjectValidationErrorCode.tooShort.rawValue {
                    let alert = UIAlertController(
                        title: nil,
                        message: L10n.Localizable.Name.Guidance.tooshort,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(
                        title: L10n.Localizable.General.ok,
                        style: .cancel
                    ))

                    UIApplication.shared.topmostViewController(onlyFullScreen: false)?.present(alert, animated: true)

                } else {
                    UIApplication.shared.topmostViewController(onlyFullScreen: false)?.showAlert(for: error)
                }

            } catch let generalError {
                zmLog.error("Error setting property: \(generalError)")
            }
        }
    }
}
