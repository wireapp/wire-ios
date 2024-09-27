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

class CreateSecureGuestLinkPasswordValidatorHelper {
    // MARK: Internal

    // MARK: - Properties

    typealias LabelColors = SemanticColors.Label

    /// Displays the elements such as text fields and/or labels on their error state
    /// - Parameters:
    ///   - textFields: Array of TextFields
    ///   - labels: Array of Labels
    func displayPasswordErrorState(for textFields: [UITextField], for labels: [UILabel]) {
        for textField in textFields {
            textField.textColor = validationErrorTextColor
            textField.layer.borderColor = validationErrorTextColor.cgColor
        }

        for label in labels {
            label.textColor = validationErrorTextColor
        }
    }

    /// Resets the elements such as text fields and/or labels to their default state
    /// - Parameters:
    ///   - textFields: Array of TextFields
    ///   - labels: Array of Labels
    func resetPasswordDefaultState(for textFields: [UITextField], for labels: [UILabel]) {
        for textField in textFields {
            textField.applyStyle(.default)
        }

        for label in labels {
            label.textColor = defaultTextColor
        }
    }

    // MARK: Private

    private var validationErrorTextColor: UIColor = LabelColors.textErrorDefault
    private var defaultTextColor: UIColor = LabelColors.textFieldFloatingLabel
}
