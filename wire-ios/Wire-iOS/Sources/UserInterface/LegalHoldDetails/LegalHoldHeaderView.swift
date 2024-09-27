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
import WireDataModel
import WireDesign

final class LegalHoldHeaderView: UIView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        let stackView = UIStackView(arrangedSubviews: [iconView, titleLabel, descriptionLabel])

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 32

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    typealias LegalHoldHeader = L10n.Localizable.Legalhold.Header
    typealias LabelColors = SemanticColors.Label

    let iconView: UIImageView = {
        let imageView = UIImageView()

        imageView.setTemplateIcon(.legalholdactive, size: .large)
        imageView.tintColor = SemanticColors.Icon.foregroundDefaultRed

        return imageView
    }()

    let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)

        label.text = LegalHoldHeader.title
        label.font = FontSpec.largeSemiboldFont.font!
        label.textColor = LabelColors.textDefault

        return label
    }()

    let descriptionLabel: UILabel = {
        let user = SelfUser.provider?.providedSelfUser

        let label = UILabel(frame: .zero)
        let text = user?.isUnderLegalHold == true ? LegalHoldHeader.selfDescription : LegalHoldHeader.otherDescription

        label.attributedText = text && .paragraphSpacing(8)
        label.font = FontSpec.normalFont.font!
        label.numberOfLines = 0
        label.textColor = LabelColors.textDefault

        return label
    }()
}
