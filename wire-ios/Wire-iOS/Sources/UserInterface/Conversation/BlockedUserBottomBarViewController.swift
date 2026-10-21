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

/// Replaces the input bar in a one-on-one conversation when the self user has blocked the other
/// user, indicating that messages can no longer be sent. See `ConversationViewController`.
final class BlockedUserBottomBarViewController: UIViewController {

    private static let verticalInset: CGFloat = 12

    private lazy var separator = UIView()
    private lazy var iconImageView = UIImageView()
    private lazy var label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        createConstraints()
    }

    private func setupViews() {
        view.backgroundColor = ColorTheme.Backgrounds.surface

        separator.backgroundColor = ColorTheme.Strokes.dividersOutlineVariant

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.setContentHuggingPriority(.required, for: .horizontal)
        iconImageView.image = StyleKitIcon.about.makeImage(size: .tiny, color: ColorTheme.Base.secondaryText)

        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.attributedText = Self.makeAttributedText()
        label.accessibilityIdentifier = "BlockedUserBottomBar.label"

        [separator, iconImageView, label].forEach(view.addSubview)
    }

    private func createConstraints() {
        [separator, iconImageView, label].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separator.topAnchor.constraint(equalTo: view.topAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),

            iconImageView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: label.centerYAnchor),

            label.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(lessThanOrEqualTo: safeArea.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: Self.verticalInset),
            label.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -Self.verticalInset)
        ])
    }

    /// Builds "You blocked this user" with the leading subject word emphasised (darker, semibold)
    /// and the remainder in the secondary text colour, mirroring the design on the other platforms.
    private static func makeAttributedText() -> NSAttributedString {
        let text = L10n.Localizable.Conversation.InputBar.blockedUser

        let metrics = UIFontMetrics(forTextStyle: .subheadline)
        let regularFont = metrics.scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
        let emphasizedFont = metrics.scaledFont(for: .systemFont(ofSize: 15, weight: .semibold))

        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: regularFont,
                .foregroundColor: ColorTheme.Base.secondaryText
            ]
        )

        if let subjectRange = text.range(of: "^\\S+", options: .regularExpression) {
            attributedText.addAttributes(
                [
                    .font: emphasizedFont,
                    .foregroundColor: ColorTheme.Backgrounds.onSurface
                ],
                range: NSRange(subjectRange, in: text)
            )
        }

        return attributedText
    }

}
