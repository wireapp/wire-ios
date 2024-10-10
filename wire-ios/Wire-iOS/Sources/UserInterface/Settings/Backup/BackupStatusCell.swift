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

final class BackupStatusCell: UITableViewCell {

    let descriptionLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(style: .body2,
                                     color: SemanticColors.Label.textDefault)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    let iconView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        iconView.setTemplateIcon(.restore, size: .large)
        iconView.tintColor = SemanticColors.Label.textDefault
        iconView.contentMode = .center
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 48),
            descriptionLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])

        let description = L10n.Localizable.Self.Settings.HistoryBackup.description
        descriptionLabel.attributedText = description && .paragraphSpacing(2)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
