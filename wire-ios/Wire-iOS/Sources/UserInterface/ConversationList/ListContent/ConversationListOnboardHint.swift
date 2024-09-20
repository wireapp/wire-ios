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

    let messageLabel: UILabel = DynamicFontLabel(fontSpec: .largeLightFont, color: SemanticColors.Label.textDefault)
    let arrowView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        arrowView.setTemplateIcon(.longDownArrow, size: .large)
        arrowView.tintColor = SemanticColors.Label.textDefault

        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .left
        messageLabel.text = L10n.Localizable.ConversationList.Empty.NoContacts.message

        [arrowView, messageLabel].forEach(addSubview)

        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createConstraints() {
        [arrowView, messageLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let margin: CGFloat = 24

        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            arrowView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: margin),
            arrowView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margin)])
    }
}
