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

/**
 * A cell to show a value validation in the settings.
 */

final class ValueValidationCell: UITableViewCell {

    let label: UILabel = {
        let label = UILabel()
        label.font = AuthenticationStepController.errorMessageFont
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    /// The initial validation to use.
    let initialValidation: ValueValidation

    // MARK: - Initialization

    /// Creates the cell with the default validation to display.
    init(initialValidation: ValueValidation) {
        self.initialValidation = initialValidation
        super.init(style: .default, reuseIdentifier: nil)
        setupViews()
        createConstraints()
        updateValidation(initialValidation)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(label)
    }

    private func createConstraints() {
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 36),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -36),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])
    }

    // MARK: - Content

    /// Updates the label for the displayed validation.
    func updateValidation(_ validation: ValueValidation?) {
        switch validation {
        case .info(let infoText)?:
            label.accessibilityIdentifier = "validation-rules"
            label.text = infoText
            label.textColor = SemanticColors.Label.textSectionFooter

        case .error(let error, let showVisualFeedback)?:
            if !showVisualFeedback {
                // If we do not want to show an error (eg if all the text was deleted,
                // use the initial info
                return updateValidation(initialValidation)
            }

            label.accessibilityIdentifier = "validation-failure"
            label.text = error.errorDescription
            label.textColor = SemanticColors.Label.textErrorDefault

        case nil:
            updateValidation(initialValidation)
        }
    }

}
