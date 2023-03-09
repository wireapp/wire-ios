//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

class DetailsCollectionViewCell: SeparatorCollectionViewCell, DynamicTypeCapable {

    // MARK: - Properties

    private let leftIconView = UIImageView()
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()

    private var titleStackView: UIStackView!
    var contentStackView: UIStackView!
    private var leftIconContainer: UIView!
    private var contentLeadingConstraint: NSLayoutConstraint!

    /// The leading offset of the content when `icon` is nil.
    var contentLeadingOffset: CGFloat = 24

    var titleBolded: Bool {
        get {
            return titleLabel.font == FontSpec.normalSemiboldFont.font
        }

        set {
            titleLabel.font = newValue ? FontSpec.normalSemiboldFont.font : FontSpec.normalLightFont.font
        }
    }

    var icon: UIImage? {
        get { return leftIconView.image }
        set { updateIcon(newValue) }
    }

    var iconColor: UIColor? {
        get { return leftIconView.tintColor }
        set { leftIconView.tintColor = newValue }
    }

    var title: String? {
        get { return titleLabel.text }
        set { updateTitle(newValue) }
    }

    var status: String? {
        get { return statusLabel.text }
        set { updateStatus(newValue) }
    }

    var disabled: Bool = false {
        didSet { }
    }

    override var accessibilityLabel: String? {
        get {
            guard let title = title,
                  let status = status else { return nil }
            return "\(title), \(status)"
        }

        set {
            super.accessibilityLabel = newValue
        }
    }

    // MARK: - Configuration - Override Methods

    override func setUp() {
        super.setUp()

        backgroundColor = SemanticColors.View.backgroundUserCell

        leftIconView.translatesAutoresizingMaskIntoConstraints = false
        leftIconView.contentMode = .scaleAspectFit
        leftIconView.setContentHuggingPriority(.required, for: .horizontal)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = FontSpec.bodyTwoSemibold.font!
        titleLabel.applyStyle(.primaryCellLabel)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = FontSpec.mediumRegularFont.font
        statusLabel.applyStyle(.secondaryCellLabel)

        leftIconContainer = UIView()
        leftIconContainer.addSubview(leftIconView)
        leftIconContainer.translatesAutoresizingMaskIntoConstraints = false
        leftIconContainer.widthAnchor.constraint(equalToConstant: 64).isActive = true
        leftIconContainer.heightAnchor.constraint(equalTo: leftIconView.heightAnchor).isActive = true
        leftIconContainer.centerXAnchor.constraint(equalTo: leftIconView.centerXAnchor).isActive = true
        leftIconContainer.centerYAnchor.constraint(equalTo: leftIconView.centerYAnchor).isActive = true

        let iconViewSpacer = UIView()
        iconViewSpacer.translatesAutoresizingMaskIntoConstraints = false
        iconViewSpacer.widthAnchor.constraint(equalToConstant: 8).isActive = true

        titleStackView = UIStackView(arrangedSubviews: [titleLabel, statusLabel])
        titleStackView.axis = .vertical
        titleStackView.distribution = .equalSpacing
        titleStackView.alignment = .leading
        titleStackView.translatesAutoresizingMaskIntoConstraints = false

        contentStackView = UIStackView(arrangedSubviews: [leftIconContainer, titleStackView, iconViewSpacer])
        contentStackView.axis = .horizontal
        contentStackView.distribution = .fill
        contentStackView.alignment = .center
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(contentStackView)
        contentLeadingConstraint = contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        contentLeadingConstraint.isActive = true

        contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true

        setupAccessibility()
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
            ? SemanticColors.View.backgroundUserCellHightLighted
            : SemanticColors.View.backgroundUserCell
        }
    }

    // MARK: - Layout

    private func updateIcon(_ newValue: UIImage?) {
        if let value = newValue {
            leftIconView.image = value
            leftIconView.isHidden = false
            leftIconContainer.isHidden = false

            contentLeadingConstraint.constant = 0
            separatorLeadingInset = 64
        } else {
            leftIconView.isHidden = true
            leftIconContainer.isHidden = true

            contentLeadingConstraint.constant = contentLeadingOffset
            separatorLeadingInset = contentLeadingOffset
        }
    }

    private func updateTitle(_ newValue: String?) {
        if let value = newValue {
            titleLabel.text = value
            titleLabel.isHidden = false
        } else {
            titleLabel.isHidden = true
        }
    }

    private func updateStatus(_ newValue: String?) {
        if let value = newValue {
            statusLabel.text = value
            statusLabel.isHidden = false
        } else {
            statusLabel.isHidden = true
        }
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    func redrawFont() {
        statusLabel.font = FontSpec.smallRegularFont.font

        titleLabel.font = titleBolded ? FontSpec.normalSemiboldFont.font : FontSpec.normalLightFont.font
    }

}
