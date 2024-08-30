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

// TODO: remove file

final class NoConversationPlaceholderView: UIView {

    // MARK: - Properties
    var shieldImageView: UIImageView!

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = ColorTheme.Backgrounds.backgroundVariant
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    // MARK: Configure Subviews and layout
    private func configureSubviews() {
        let image = WireStyleKit.imageOfShield()
            .withRenderingMode(.alwaysTemplate)

        shieldImageView = UIImageView(image: image)
        shieldImageView.alpha = 0.24
        shieldImageView.tintColor = SemanticColors.Label.textDefault
        shieldImageView.contentMode = .scaleAspectFit
        addSubview(shieldImageView)
    }

    private func configureConstraints() {
        shieldImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            shieldImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            shieldImageView.centerYAnchor.constraint(equalTo: centerYAnchor),


        ])
    }

}
