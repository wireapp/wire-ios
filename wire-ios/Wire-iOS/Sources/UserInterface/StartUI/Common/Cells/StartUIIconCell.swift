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

class StartUIIconCell: UICollectionViewCell {

    // MARK: - Properties

    typealias CellColors = SemanticColors.View
    typealias PeoplePicker = L10n.Localizable.Peoplepicker

    let iconView = UIImageView()
    let titleLabel = DynamicFontLabel(
        fontSpec: .bodyTwoSemibold,
        color: SemanticColors.Label.textDefault
    )

    let separator = UIView()

    var icon: StyleKitIcon? {
        didSet {
            iconView.image = icon?.makeImage(size: .tiny, color: SemanticColors.Icon.foregroundDefault).withRenderingMode(.alwaysTemplate)
            iconView.tintColor = SemanticColors.Icon.foregroundDefault
        }
    }

    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    // MARK: - Override Properties

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? CellColors.backgroundUserCellHightLighted : CellColors.backgroundUserCell
        }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Set up UI

    func setupViews() {
        iconView.contentMode = .center
        separator.backgroundColor = CellColors.backgroundSeparatorCell
        backgroundColor = CellColors.backgroundUserCell
        [
            iconView,
            titleLabel,
            separator
        ].forEach(contentView.addSubview)
    }

    func createConstraints() {
        let iconSize: CGFloat = 32.0

        [
            iconView,
            titleLabel,
            separator
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: iconSize),
            iconView.heightAnchor.constraint(equalToConstant: iconSize),
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 64),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            separator.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: .hairline)
        ])
    }

}
