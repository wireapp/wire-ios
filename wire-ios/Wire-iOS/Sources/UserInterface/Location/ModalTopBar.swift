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

protocol ModalTopBarDelegate: AnyObject {
    func modelTopBarWantsToBeDismissed(_ topBar: ModalTopBar)
}

final class ModalTopBar: UIView {
    let dismissButton = IconButton()
    typealias ViewColors = SemanticColors.View

    let titleLabel: DynamicFontLabel = {
        let textColor = SemanticColors.Label.textDefault
        let label = DynamicFontLabel(
            fontSpec: .headerSemiboldFont,
            color: textColor
        )
        label.textAlignment = .center
        label.accessibilityIdentifier = "Title"

        return label
    }()

    let subtitleLabel: DynamicFontLabel = {
        let textColor = SemanticColors.Label.textDefault
        let label = DynamicFontLabel(
            fontSpec: .smallSemiboldFont,
            color: textColor
        )
        label.textAlignment = .center
        label.accessibilityIdentifier = "Subtitle"

        return label
    }()

    let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = ViewColors.backgroundSeparatorCell
        return view
    }()

    let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.axis = .vertical

        return stack
    }()

    weak var delegate: ModalTopBarDelegate?
    private var contentTopConstraint: NSLayoutConstraint?

    private var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.isHidden = title == nil
            titleLabel.accessibilityLabel = title
            titleLabel.accessibilityValue = title
            titleLabel.accessibilityTraits.insert(.header)
        }
    }

    private var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle?.capitalized
            subtitleLabel.isHidden = subtitle == nil
            subtitleLabel.accessibilityLabel = subtitle
            subtitleLabel.accessibilityValue = subtitle
        }
    }

    private var sepeatorHeight: NSLayoutConstraint!

    var needsSeparator = true {
        didSet {
            sepeatorHeight.constant = needsSeparator ? 1 : 0
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, subtitle: String?, topAnchor: NSLayoutYAxisAnchor) {
        if let topConstraint = contentTopConstraint {
            contentStackView.removeConstraint(topConstraint)
        }

        contentTopConstraint = contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: 4)
        contentTopConstraint?.isActive = true

        self.title = title
        self.subtitle = subtitle
    }

    private func configureViews() {
        backgroundColor = ViewColors.backgroundDefault
        titleLabel.isHidden = true
        subtitleLabel.isHidden = true
        [titleLabel, subtitleLabel].forEach(contentStackView.addArrangedSubview)
        [contentStackView, dismissButton, separatorView].forEach(addSubview)

        dismissButton.accessibilityIdentifier = "Close"
        dismissButton.accessibilityLabel = L10n.Localizable.General.close

        dismissButton.setIcon(.cross, size: .tiny, for: [])
        dismissButton.setIconColor(SemanticColors.Icon.foregroundDefault, for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        dismissButton.hitAreaPadding = CGSize(width: 20, height: 20)
    }

    private func createConstraints() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false

        sepeatorHeight = separatorView.heightAnchor.constraint(equalToConstant: 1)

        NSLayoutConstraint.activate([
            // contentStackView
            contentStackView.leadingAnchor.constraint(greaterThanOrEqualTo: safeLeadingAnchor, constant: 48),
            contentStackView.centerXAnchor.constraint(equalTo: safeCenterXAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            contentStackView.trailingAnchor.constraint(lessThanOrEqualTo: dismissButton.leadingAnchor, constant: -12),
            contentStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),

            // dismissButton
            dismissButton.trailingAnchor.constraint(equalTo: safeTrailingAnchor, constant: -16),
            dismissButton.centerYAnchor.constraint(equalTo: contentStackView.centerYAnchor),

            // separator
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            sepeatorHeight,
        ])

        dismissButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 750), for: .horizontal)
        subtitleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 750), for: .horizontal)
    }

    @objc
    private func dismissButtonTapped(_: IconButton) {
        delegate?.modelTopBarWantsToBeDismissed(self)
    }
}
