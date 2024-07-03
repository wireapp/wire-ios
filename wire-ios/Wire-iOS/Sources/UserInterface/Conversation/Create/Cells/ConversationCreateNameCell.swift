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
import WireDesign

final class ConversationCreateNameCell: UICollectionViewCell {

    private let stackView = UIStackView()
    private let groupNameLabel = DynamicFontLabel(
        text: "Group name",
        style: .h4,
        color: SemanticColors.Label.textUserPropertyCellName
    )

    let textField = WireTextField()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    private func setup() {
        setupStackView()
        setupGroupNameLabel()
        setupTextField()
        setupConstraints()
    }

    private func setupStackView() {
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
    }

    private func setupGroupNameLabel() {
        stackView.addArrangedSubview(groupNameLabel)
    }

    private func setupTextField() {
        textField.borderStyle = .roundedRect
        textField.layer.borderColor = SemanticColors.SearchBar.borderInputView.cgColor
        textField.font = .font(for: .body1)
        textField.delegate = self
        stackView.addArrangedSubview(textField)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),

            textField.heightAnchor.constraint(equalToConstant: 46)
        ])
    }
    }

extension ConversationCreateNameCell: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        groupNameLabel.textColor = UIColor.accent()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        groupNameLabel.textColor = SemanticColors.Label.textUserPropertyCellName
    }
}
