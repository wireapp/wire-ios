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

final class ConversationWarningSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {
    // MARK: Internal

    struct Configuration {
        let topText: String
        let bottomText: String
    }

    func configure(with object: Configuration, animated: Bool) {
        encryptionLabel.text = object.topText
        sensitiveInfoLabel.text = object.bottomText
    }

    override func configureSubviews() {
        super.configureSubviews()
        encryptionLabel.numberOfLines = 0
        encryptionLabel.translatesAutoresizingMaskIntoConstraints = false
        topContentView.addSubview(encryptionLabel)

        sensitiveInfoLabel.numberOfLines = 0
        sensitiveInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomContentView.addSubview(sensitiveInfoLabel)

        lineView.isHidden = true
        imageView.image = .init(resource: .attention)
        imageView.tintColor = IconColors.backgroundDefault
    }

    override func configureConstraints() {
        super.configureConstraints()
        encryptionLabel.fitIn(view: topContentView)
        sensitiveInfoLabel.fitIn(view: bottomContentView)
        NSLayoutConstraint.activate([
            imageContainer.topAnchor.constraint(equalTo: bottomContentView.topAnchor).withPriority(.required),
        ])
    }

    // MARK: Private

    private typealias LabelColors = SemanticColors.Label
    private typealias IconColors = SemanticColors.Icon

    private let encryptionLabel = DynamicFontLabel(
        fontSpec: .mediumRegularFont,
        color: LabelColors.textDefault
    )
    private let sensitiveInfoLabel = DynamicFontLabel(
        fontSpec: .mediumRegularFont,
        color: LabelColors.textDefault
    )
}
