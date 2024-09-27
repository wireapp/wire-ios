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

final class TwoLineTitleView: UIView {
    // MARK: Lifecycle

    init(first: NSAttributedString, second: NSAttributedString?) {
        super.init(frame: CGRect.zero)
        isAccessibilityElement = true

        titleLabel.textAlignment = .center
        subtitleLabel.textAlignment = .center

        titleLabel.attributedText = first
        subtitleLabel.attributedText = second

        addSubview(titleLabel)
        addSubview(subtitleLabel)

        [self, titleLabel, subtitleLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let titleLabel = DynamicFontLabel(
        fontSpec: .headerSemiboldFont,
        color: SemanticColors.Label.textDefault
    )

    let subtitleLabel = DynamicFontLabel(
        fontSpec: .mediumRegularFont,
        color: SemanticColors.Label.textDefault
    )
}
