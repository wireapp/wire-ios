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

final class ReactionCategoryButton: UIButton {
    // MARK: Lifecycle

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override var isSelected: Bool {
        didSet {
            selectionIndicator.isHidden = !isSelected
            imageView?.tintColor = isSelected ? selectedTintColor : defaultTintColor
        }
    }

    // MARK: Private

    private var selectionIndicator = UIView()
    private let selectedTintColor = SemanticColors.Icon.emojiCategorySelected
    private let defaultTintColor = SemanticColors.Icon.emojiCategoryDefault

    private func setupViews() {
        selectionIndicator.backgroundColor = UIColor.accent()
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        selectionIndicator.isHidden = true
        addSubview(selectionIndicator)

        NSLayoutConstraint.activate([
            selectionIndicator.bottomAnchor.constraint(equalTo: bottomAnchor),
            selectionIndicator.leadingAnchor.constraint(equalTo: leadingAnchor),
            selectionIndicator.trailingAnchor.constraint(equalTo: trailingAnchor),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 4.0),
        ])
    }
}
