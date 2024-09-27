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

import Down
import UIKit
import WireCommonComponents
import WireDesign

// MARK: - UserBlockingReasonCell

final class UserBlockingReasonCell: UITableViewCell {
    // MARK: - Properties

    private let titleLabel = WebLinkTextView()

    // MARK: - Life cycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        configureLabel()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helpers

    private func setupViews() {
        backgroundColor = .clear
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.linkTextAttributes = [
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle().rawValue as NSNumber,
            NSAttributedString.Key.foregroundColor: SelfUser.provider?.providedSelfUser.accentColor ?? UIColor.accent(),
        ]
        contentView.addSubview(titleLabel)
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    private func configureLabel() {
        titleLabel.accessibilityIdentifier = "blocking_reason.label.title"
        let markdownTitle = L10n.Localizable.Profile.Details
            .blockingReason(WireURLs.shared.legalHoldInfo.absoluteString)
        titleLabel.attributedText = .markdown(
            from: markdownTitle,
            style: .labelStyle
        )
    }
}

extension DownStyle {
    fileprivate static var labelStyle: DownStyle {
        let style = DownStyle()
        style.baseFont = UIFont.systemFont(ofSize: 14)
        style.baseFontColor = SemanticColors.Label.textDefault
        style.baseParagraphStyle = NSParagraphStyle.default

        return style
    }
}
