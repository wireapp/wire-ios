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

final class ConversationRenamedSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {
    // MARK: Internal

    struct Configuration {
        let attributedText: NSAttributedString
        let newConversationName: NSAttributedString
    }

    override func configureSubviews() {
        super.configureSubviews()
        nameLabel.numberOfLines = 0
        imageView.setTemplateIcon(.pencil, size: 16)
        imageView.tintColor = IconColors.backgroundDefault
        bottomContentView.addSubview(nameLabel)
    }

    override func configureConstraints() {
        super.configureConstraints()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: bottomContentView.topAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: bottomContentView.bottomAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: bottomContentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: bottomContentView.trailingAnchor),
        ])
    }

    // MARK: - Configuration

    func configure(with object: Configuration, animated: Bool) {
        lineView.isHidden = false
        attributedText = object.attributedText
        nameLabel.attributedText = object.newConversationName
        nameLabel.accessibilityLabel = nameLabel.attributedText?.string
    }

    // MARK: Private

    private typealias IconColors = SemanticColors.Icon

    private let nameLabel = UILabel()
}
