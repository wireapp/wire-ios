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

private let verifiedShieldImage = WireStyleKit.imageOfShieldverified

final class ShareDestinationCell<D: ShareDestination>: UITableViewCell {
    let checkmarkSize: CGFloat = 24
    let avatarSize: CGFloat = 32
    let shieldSize: CGFloat = 20
    let margin: CGFloat = 16

    let stackView = UIStackView(axis: .horizontal)
    let titleLabel = UILabel()
    let checkImageView = UIImageView()
    let avatarViewContainer = UIView()
    var avatarView: UIView?
    private let shieldView: UIImageView = {
        let imageView = UIImageView(image: verifiedShieldImage)
        imageView.accessibilityIdentifier = "verifiedShield"
        imageView.isAccessibilityElement = true

        return imageView
    }()

    private let guestUserIcon: UIImageView = {
        let guestUserIconColor = SemanticColors.Icon.foregroundDefault
        let imageView = UIImageView()
        imageView.setTemplateIcon(.guest, size: .tiny)
        imageView.tintColor = guestUserIconColor
        imageView.accessibilityIdentifier = "guestUserIcon"
        imageView.isAccessibilityElement = true

        return imageView
    }()

    private let legalHoldIcon: UIImageView = {
        let legalHoldActiveIconColor = SemanticColors.Icon.backgroundMissedPhoneCall
        let imageView = UIImageView()
        imageView.setTemplateIcon(.legalholdactive, size: .tiny)
        imageView.tintColor = legalHoldActiveIconColor
        imageView.accessibilityIdentifier = "legalHoldIcon"
        imageView.isAccessibilityElement = true

        return imageView
    }()

    var allowsMultipleSelection: Bool = true {
        didSet {
            checkImageView.isHidden = !allowsMultipleSelection
        }
    }

    var destination: D? {
        didSet {

            guard let destination else { return }

            titleLabel.text = destination.displayNameWithFallback
            shieldView.isHidden = destination.securityLevel != .secure
            guestUserIcon.isHidden = !destination.showsGuestIcon
            legalHoldIcon.isHidden = !destination.isUnderLegalHold

            if let avatarView = destination.avatarView {
                avatarView.frame = CGRect(x: 0, y: 0, width: avatarSize, height: avatarSize)
                avatarViewContainer.addSubview(avatarView)
                self.avatarView = avatarView
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        UIView.performWithoutAnimation {
            avatarView?.removeFromSuperview()
            guestUserIcon.isHidden = true
            legalHoldIcon.isHidden = true
            shieldView.isHidden = true
            checkImageView.isHidden = true
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        selectionStyle = .none
        contentView.backgroundColor = .clear
        stackView.backgroundColor = .clear
        stackView.spacing = margin
        stackView.alignment = .center
        backgroundView = UIView()
        selectedBackgroundView = UIView()

        contentView.addSubview(stackView)

        stackView.addArrangedSubview(avatarViewContainer)

        [avatarViewContainer, shieldView, guestUserIcon, legalHoldIcon, stackView, titleLabel, checkImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        titleLabel.backgroundColor = .clear
        titleLabel.textColor = SemanticColors.Label.textDefault
        titleLabel.font = .normalLightFont
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)

        [titleLabel, shieldView, guestUserIcon, legalHoldIcon, checkImageView].forEach {
            stackView.addArrangedSubview($0)
        }

        checkImageView.layer.borderColor = SemanticColors.Icon.borderCheckMark.cgColor
        checkImageView.layer.borderWidth = 2
        checkImageView.contentMode = .center
        checkImageView.layer.cornerRadius = checkmarkSize / 2.0

        NSLayoutConstraint.activate([
            avatarViewContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarViewContainer.widthAnchor.constraint(equalToConstant: avatarSize),
            avatarViewContainer.heightAnchor.constraint(equalToConstant: avatarSize),
            shieldView.widthAnchor.constraint(equalToConstant: shieldSize),
            shieldView.heightAnchor.constraint(equalToConstant: shieldSize),

            guestUserIcon.widthAnchor.constraint(equalToConstant: shieldSize),
            guestUserIcon.heightAnchor.constraint(equalToConstant: shieldSize),
            legalHoldIcon.widthAnchor.constraint(equalToConstant: shieldSize),
            legalHoldIcon.heightAnchor.constraint(equalToConstant: shieldSize),
            stackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin),
            stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            titleLabel.heightAnchor.constraint(equalToConstant: 44),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            checkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkImageView.widthAnchor.constraint(equalToConstant: checkmarkSize),
            checkImageView.heightAnchor.constraint(equalToConstant: checkmarkSize)
        ])

    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        //  Border colors are not dynamically updating for Dark Mode
        //  When you use adaptive colors with CALayers you’ll notice that these colors,
        // are not updating when switching appearance live in the app.
        // That's why we use the traitCollectionDidChange(_:) method.
        checkImageView.layer.borderColor = SemanticColors.Icon.borderCheckMark.cgColor
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        checkImageView.image = selected ? StyleKitIcon.checkmark.makeImage(size: 12, color: .white).withRenderingMode(.alwaysTemplate) : nil
        checkImageView.tintColor = selected ? SemanticColors.Icon.foregroundCheckMarkSelected : .clear
        checkImageView.backgroundColor = selected ? SemanticColors.Icon.backgroundCheckMarkSelected : SemanticColors.Icon.backgroundCheckMark
        checkImageView.layer.borderColor = selected ? UIColor.clear.cgColor : SemanticColors.Icon.borderCheckMark.cgColor
    }
}
