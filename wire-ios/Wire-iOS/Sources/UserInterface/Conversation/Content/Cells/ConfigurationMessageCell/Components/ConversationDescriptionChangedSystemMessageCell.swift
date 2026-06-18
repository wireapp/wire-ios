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
import WireCommonComponents
import WireDesign

final class ConversationDescriptionChangedSystemMessageCell: ConversationIconBasedCell<
    ConversationDescriptionChangedSystemMessageCellDescription
>,
    ConversationMessageCell {

    private typealias IconColors = SemanticColors.Icon

    struct Configuration {
        let attributedText: NSAttributedString
        let newDescription: NSAttributedString?
    }

    private let descriptionLabel = UILabel()

    override func configureSubviews() {
        super.configureSubviews()
        descriptionLabel.numberOfLines = 0
        imageView.setTemplateIcon(.pencil, size: 16)
        imageView.tintColor = IconColors.backgroundDefault
        bottomContentView.addSubview(descriptionLabel)
    }

    override func configureConstraints() {
        super.configureConstraints()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: bottomContentView.topAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: bottomContentView.bottomAnchor),
            descriptionLabel.leadingAnchor.constraint(equalTo: bottomContentView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: bottomContentView.trailingAnchor)
        ])
    }

    func configure(with object: Configuration, animated: Bool) {
        lineView.isHidden = false
        attributedText = object.attributedText
        descriptionLabel.attributedText = object.newDescription
        descriptionLabel.accessibilityLabel = object.newDescription?.string
        descriptionLabel.isHidden = object.newDescription == nil
    }

}
