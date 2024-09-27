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

final class SecureLinkHeaderCell: UITableViewCell, CellConfigurationConfigurable {
    // MARK: Lifecycle

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    func configure(with configuration: CellConfiguration) {
        styleViews()
    }

    // MARK: Private

    // MARK: - Properties

    private let topSeparator = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private func setupViews() {
        contentView.addSubview(topSeparator)
        [iconImageView, titleLabel, subtitleLabel].forEach(contentView.addSubview)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.image = UIImage(resource: .secureGuestLinkShield)
        iconImageView.tintColor = SemanticColors.Icon.foregroundDefaultBlack

        titleLabel.font = UIFont.font(for: .h5)
        titleLabel.text = L10n.Localizable.GuestRoom.SecureLink.Header.title

        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = UIFont.font(for: .subline1)
        subtitleLabel.text = L10n.Localizable.GuestRoom.SecureLink.Header.subtitle
    }

    private func createConstraints() {
        [topSeparator, iconImageView, titleLabel, subtitleLabel]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            topSeparator.topAnchor.constraint(equalTo: contentView.topAnchor),
            topSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            topSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            topSeparator.heightAnchor.constraint(equalToConstant: .hairline),

            iconImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: topSeparator.leadingAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16),

            titleLabel.topAnchor.constraint(equalTo: topSeparator.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: topSeparator.trailingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: iconImageView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: topSeparator.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ])
    }

    private func styleViews() {
        topSeparator.backgroundColor = .clear
        titleLabel.textColor = SemanticColors.Label.textLinkHeaderCellTitle
        subtitleLabel.textColor = SemanticColors.Label.textSectionFooter
        backgroundColor = .clear
    }
}
