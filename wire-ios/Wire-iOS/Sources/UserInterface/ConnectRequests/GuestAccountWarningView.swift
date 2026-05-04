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
import WireDesign

final class GuestAccountWarningView: UIView {

    private let stackView = UIStackView(axis: .vertical)

    private let titleLabel = DynamicFontLabel(
        style: .h3,
        color: SemanticColors.Label.textSecurityEnabled
    )
    private let messageLabel = DynamicFontLabel(
        style: .subline1,
        color: SemanticColors.Label.textDefault
    )
    private let linkLabel = UILabel()
    private var linkURL: URL?
    private let imageView = UIImageView(
        image: {
            var image = UIImage(systemName: "shield.righthalf.filled")
            image = image?.resizeMaintainingAspectRatio(targetSize: .init(width: 18, height: 18))
            return image?
                .withRenderingMode(.alwaysOriginal)
                .withTintColor(SemanticColors.Label.textSecurityEnabled)
        }()
    )

    // MARK: - Setup

    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        addSubview(imageView)

        stackView.alignment = .fill
        stackView.spacing = 16

        let title = L10n.Localizable.Conversation.ConnectionView.Welcome.Title.wire

        titleLabel.numberOfLines = 0
        titleLabel.text = title
        titleLabel.isAccessibilityElement = true

        stackView.addArrangedSubview(titleLabel)

        messageLabel.numberOfLines = 0
        messageLabel.text = L10n.Localizable.Conversation.ConnectionView.Welcome.Message.wireOneOnOne
        messageLabel.isAccessibilityElement = true

        stackView.addArrangedSubview(messageLabel)

        let linkText = L10n.Localizable.Conversation.ConnectionView.Welcome.learnMore
        let linkUrl = URL(string: "https://support.wire.com/hc/articles/10898523878173")!
        linkURL = linkUrl

        let linkAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.mediumSemiboldFont,
            .foregroundColor: SemanticColors.Label.textDefault,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: SemanticColors.Label.textDefault
        ]

        linkLabel.attributedText = .init(string: linkText, attributes: linkAttributes)
        linkLabel.numberOfLines = 0
        linkLabel.isUserInteractionEnabled = true
        linkLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(learnMoreTapped)))

        stackView.addArrangedSubview(linkLabel)
    }

    @objc private func learnMoreTapped() {
        guard let url = linkURL else { return }
        UIApplication.shared.open(url)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12.0),

            imageView.widthAnchor.constraint(equalToConstant: 18.0),
            imageView.heightAnchor.constraint(equalToConstant: 18.0),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor, constant: 2)
        ])
    }
}
