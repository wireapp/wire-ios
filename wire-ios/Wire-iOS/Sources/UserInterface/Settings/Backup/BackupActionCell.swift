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

final class BackupActionCell: UITableViewCell {
    let actionTitleLabel: DynamicFontLabel = {
        let text = L10n.Localizable.Self.Settings.HistoryBackup.action
        let label = DynamicFontLabel(text: text,
                                     style: .body2,
                                     color: SemanticColors.Label.textDefault)
        label.textAlignment = .left
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = SemanticColors.View.backgroundUserCell
        accessibilityTraits = .button
        contentView.backgroundColor = .clear

        actionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actionTitleLabel)
        NSLayoutConstraint.activate([
            actionTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            actionTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            actionTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            actionTitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
        ])
        actionTitleLabel.heightAnchor.constraint(equalToConstant: 44).isActive = true
        addBorder(for: .bottom)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
