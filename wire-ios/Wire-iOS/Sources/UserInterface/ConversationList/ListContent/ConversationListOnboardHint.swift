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

final class ConversationListOnboardingHint: UIView {

    let messageLabel = DynamicFontLabel(fontSpec: .largeLightFont, color: SemanticColors.Label.textDefault)
    let arrowView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        arrowView.setTemplateIcon(.longDownArrow, size: .large)
        arrowView.tintColor = SemanticColors.Label.textDefault

        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .right
        messageLabel.text = L10n.Localizable.ConversationList.Empty.NoContacts.message

        [arrowView, messageLabel].forEach(addSubview)
        arrowView.transform = .init(rotationAngle: .pi)

        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func createConstraints() {

        arrowView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        let margin: CGFloat = 24
        NSLayoutConstraint.activate([

            arrowView.topAnchor.constraint(equalTo: topAnchor, constant: margin),
            trailingAnchor.constraint(equalTo: arrowView.trailingAnchor, constant: 4),

            messageLabel.topAnchor.constraint(equalTo: arrowView.bottomAnchor, constant: margin),
            messageLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 2),
            trailingAnchor.constraint(equalToSystemSpacingAfter: messageLabel.trailingAnchor, multiplier: 2),
            bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor)])
    }
}
