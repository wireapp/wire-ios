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
import WireSyncEngine
import WireCommonComponents

class PickerCell: UITableViewCell {

    private struct Constants {
        static let colorViewSize: CGFloat = 28
        static let colorViewCornerRadius: CGFloat = 14
        static let leftPadding: CGFloat = 16
        static let rightPadding: CGFloat = 20
        static let labelLeftPadding: CGFloat = 64
    }

    private let checkmarkView = UIImageView()
    private let colorView = UIView()
    private let colorNameLabel: UILabel = {
        let label = UILabel()
        label.font = .normalLightFont
        label.textColor = SemanticColors.Label.textDefault
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var color: AccentColor? {
        didSet {
            if let color = color {
                colorView.backgroundColor = UIColor(for: color)
            }
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        checkmarkView.isHidden = !selected
        colorNameLabel.font = selected ? .normalSemiboldFont : .normalLightFont
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        colorView.backgroundColor = UIColor.clear
        checkmarkView.isHidden = true
    }

    func setColorName(_ name: String) {
        colorNameLabel.text = name
    }

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = SemanticColors.View.backgroundUserCell
        addBorder(for: .bottom)

        setupColorView()
        setupCheckmarkView()
        setupColorNameLabel()
    }

    private func setupColorView() {
        contentView.addSubview(colorView)
        colorView.layer.cornerRadius = Constants.colorViewCornerRadius
    }

    private func setupCheckmarkView() {
        contentView.addSubview(checkmarkView)
        checkmarkView.setTemplateIcon(.checkmark, size: .small)
        checkmarkView.tintColor = SemanticColors.Label.textDefault
        checkmarkView.isHidden = true
    }

    private func setupColorNameLabel() {
        contentView.addSubview(colorNameLabel)
    }

    private func createConstraints() {
        [checkmarkView, colorView, colorNameLabel].prepareForLayout()
        NSLayoutConstraint.activate([
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: Constants.leftPadding),
            colorView.heightAnchor.constraint(equalToConstant: Constants.colorViewSize),
            colorView.widthAnchor.constraint(equalToConstant: Constants.colorViewSize),

            colorNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorNameLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: Constants.labelLeftPadding),

            checkmarkView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -Constants.rightPadding),
            checkmarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
