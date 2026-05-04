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
import WireSystem

private let zmLog = ZMSLog(tag: "UI")

/// @abstract Generates the cell that displays toggle control

final class SettingsPropertyToggleCellDescriptor: SettingsPropertyCellDescriptorType {

    static let cellType: SettingsTableCellProtocol.Type = SettingsToggleCell.self

    let inverse: Bool
    var title: String {
        settingsProperty.propertyName.settingsPropertyLabelText
    }

    let identifier: String?
    var visible: Bool = true
    weak var group: (any SettingsGroupCellDescriptorType)?
    var settingsProperty: SettingsProperty

    init(settingsProperty: SettingsProperty, inverse: Bool = false, identifier: String? = .none) {
        self.settingsProperty = settingsProperty
        self.inverse = inverse
        self.identifier = identifier
    }

    func featureCell(_ cell: SettingsCellType) {
        cell.titleText = title
        if let toggleCell = cell as? SettingsToggleCell {
            var boolValue = false
            if let value = settingsProperty.value().value() as? NSNumber {
                boolValue = value.boolValue
            } else {
                boolValue = false
            }

            if inverse {
                boolValue = !boolValue
            }

            toggleCell.switchView.isOn = boolValue
            toggleCell.switchView.accessibilityLabel = identifier
            toggleCell.switchView.isEnabled = settingsProperty.enabled
            if #available(iOS 17.0, *) {
                toggleCell.accessibilityTraits = .toggleButton
            } else {
                toggleCell.accessibilityTraits = .button
            }
        }
    }

    func select(_ value: SettingsPropertyValue, sender: UIView) {
        var valueToSet = false

        if let value = value.value() {
            switch value {
            case let numberValue as NSNumber:
                valueToSet = numberValue.boolValue
            case let intValue as Int:
                valueToSet = intValue > 0
            case let boolValue as Bool:
                valueToSet = boolValue
            default:
                fatal("Unknown type: \(type(of: value))")
            }
        }

        if inverse {
            valueToSet = !valueToSet
        }

        do {
            try settingsProperty.set(newValue: SettingsPropertyValue(valueToSet)) { result in
                if case .failure = result {
                    // Workaround: the toggle needs to be undone because of an async result in the logic code.
                    if let toggleCell = sender as? UISwitch {
                        toggleCell.isOn.toggle()
                    }
                }
            }
        } catch {
            zmLog.error("Cannot set property: \(error)")
        }
    }
}
