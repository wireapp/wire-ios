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

class RoundedBadge: UIButton {
    let containedView: UIView
    private var trailingConstraint: NSLayoutConstraint!
    private var leadingConstraint: NSLayoutConstraint!
    var widthGreaterThanHeightConstraint: NSLayoutConstraint!
    private let contentInset: UIEdgeInsets

    init(view: UIView, contentInset: UIEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)) {
        self.contentInset = contentInset
        self.containedView = view
        super.init(frame: .zero)

        addSubview(containedView)

        createConstraints()

        updateCollapseConstraints(isCollapsed: true)

        layer.masksToBounds = true
        updateCornerRadius()
    }

    private func createConstraints() {
        containedView.translatesAutoresizingMaskIntoConstraints = false
        translatesAutoresizingMaskIntoConstraints = false

        leadingConstraint = containedView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInset.left)
        trailingConstraint = containedView.trailingAnchor.constraint(
            equalTo: trailingAnchor,
            constant: -contentInset.right
        )
        widthGreaterThanHeightConstraint = widthAnchor.constraint(greaterThanOrEqualTo: heightAnchor)

        NSLayoutConstraint.activate([
            leadingConstraint,
            trailingConstraint,
            widthGreaterThanHeightConstraint,

            containedView.topAnchor.constraint(equalTo: topAnchor, constant: contentInset.top),
            containedView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentInset.bottom),

        ])
    }

    func updateCollapseConstraints(isCollapsed: Bool) {
        if isCollapsed {
            widthGreaterThanHeightConstraint.isActive = false
            trailingConstraint.constant = 0
            leadingConstraint.constant = 0
        } else {
            widthGreaterThanHeightConstraint.isActive = true
            trailingConstraint.constant = -contentInset.right
            leadingConstraint.constant = contentInset.left
        }
    }

    func updateCornerRadius() {
        layer.cornerRadius = ceil(bounds.height / 2.0)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCornerRadius()
    }
}

final class RoundedTextBadge: RoundedBadge {
    var textLabel = UILabel()

    init(
        contentInset: UIEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4),
        font: UIFont = .smallSemiboldFont
    ) {
        super.init(view: textLabel, contentInset: contentInset)
        textLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        textLabel.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        textLabel.textAlignment = .center
        textLabel.textColor = .from(scheme: .background)
        textLabel.font = font
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
