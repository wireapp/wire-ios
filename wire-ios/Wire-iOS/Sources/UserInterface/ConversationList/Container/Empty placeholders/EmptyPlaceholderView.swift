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

final class EmptyPlaceholderView: UIView {

    var titleLabel: DynamicFontLabel!
    var descriptionLabel: SubheadlineTextView!
    var stackView: UIStackView!

    let arrowView: UIImageView = {
        let arrow = UIImageView()
        arrow.image = UIImage(resource: .ConversationList.arrow)
        arrow.contentMode = .scaleToFill
        return arrow
    }()

    let connectWithPeopleButton: DynamicFontButton = {
        let button = DynamicFontButton(style: .body1)
        button.setTitleColor(ColorTheme.Base.primary, for: .normal)
        button.setBackgroundImageColor(ColorTheme.Backgrounds.background, for: .normal)
        button.layer.cornerRadius = 18
        button.layer.masksToBounds = true

        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        button.setTitle(L10n.Localizable.ConversationList.EmptyPlaceholder.Oneonone.button, for: .normal)
        button.accessibilityIdentifier = "connect-with-people.button"

        return button
    }()

    // MARK: - Init

    init(content: ConversationListViewController.EmptyPlaceholder, connectWithPeopleAction: UIAction) {
        super.init(frame: .zero)

        setup(content, connectWithPeopleAction: connectWithPeopleAction)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup(_ content: ConversationListViewController.EmptyPlaceholder, connectWithPeopleAction: UIAction) {
        backgroundColor = isIPadRegular() ? ColorTheme.Backgrounds.backgroundVariant : ColorTheme.Backgrounds.surfaceVariant
        titleLabel = DynamicFontLabel(
            text: content.headline,
            style: .h2,
            color: ColorTheme.Backgrounds.onSurfaceVariant)

        descriptionLabel = SubheadlineTextView(
            attributedText: content.subheadline,
            style: .body1,
            color: ColorTheme.Backgrounds.onSurfaceVariant)

        titleLabel.textAlignment = .center
        descriptionLabel.textAlignment = .center
        arrowView.isHidden = !content.showArrow

        stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.axis = .vertical
        stackView.spacing = 2

        connectWithPeopleButton.isHidden = !content.showButton
        connectWithPeopleButton.addAction(connectWithPeopleAction, for: .touchUpInside)

        [arrowView, stackView, connectWithPeopleButton].forEach(addSubview)
        createConstraints()
    }

    private func createConstraints() {
        arrowView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        connectWithPeopleButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.widthAnchor.constraint(lessThanOrEqualToConstant: 272),

            arrowView.topAnchor.constraint(equalTo: topAnchor),
            arrowView.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: -40),
            arrowView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            connectWithPeopleButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 10),
            connectWithPeopleButton.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    func configure(with content: ConversationListViewController.EmptyPlaceholder) {
        titleLabel.text = content.headline
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.font(for: .body1),
            .foregroundColor: SemanticColors.Label.textDefault,
            .paragraphStyle: paragraphStyle
        ]
        descriptionLabel.attributedText = content.subheadline && textAttributes
        arrowView.isHidden = !content.showArrow
        connectWithPeopleButton.isHidden = !content.showButton
    }

}
