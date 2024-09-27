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

// MARK: - MenuDotView

private final class MenuDotView: UIView {
    // MARK: Lifecycle

    init() {
        super.init(frame: .zero)

        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.size.width / 2
    }
}

// MARK: - AnimatedListMenuView

final class AnimatedListMenuView: UIView {
    // MARK: Lifecycle

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        for item in [leftDotView, centerDotView, rightDotView] {
            addSubview(item)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    /// Animation progress. Value from 0 to 1.0
    var progress: CGFloat = 0 {
        didSet {
            guard !(0 ... 1 ~= progress) else { return }
            progress = min(1, max(0, progress))
        }
    }

    func setProgress(_ progress: CGFloat, animated: Bool) {
        self.progress = progress

        centerToRightDistanceConstraint?.constant = centerToRightDistance(forProgress: self.progress)
        leftToCenterDistanceConstraint?.constant = leftToCenterDistance(forProgress: self.progress)

        if animated {
            setNeedsUpdateConstraints()

            UIView.animate(withDuration: 0.25, animations: {
                self.layoutIfNeeded()
            })
        }
    }

    override func updateConstraints() {
        if initialConstraintsCreated {
            super.updateConstraints()
            return
        }

        let dotWidth: CGFloat = 4

        let dotViews = [leftDotView, centerDotView, rightDotView]

        dotViews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        translatesAutoresizingMaskIntoConstraints = false

        centerToRightDistanceConstraint = centerDotView.rightAnchor.constraint(
            equalTo: rightDotView.leftAnchor,
            constant: centerToRightDistance(forProgress: progress)
        )

        leftToCenterDistanceConstraint = leftDotView.rightAnchor.constraint(
            equalTo: centerDotView.leftAnchor,
            constant: leftToCenterDistance(forProgress: progress)
        )

        let leftDotLeftConstraint = leftDotView.leftAnchor.constraint(equalTo: leftAnchor)

        for dotView in dotViews {
            dotView.widthAnchor.constraint(equalToConstant: dotWidth).isActive = true
            dotView.heightAnchor.constraint(equalToConstant: dotWidth).isActive = true
        }

        let subviewConstraints: [NSLayoutConstraint] = [
            leftDotView.centerYAnchor.constraint(equalTo: centerYAnchor),
            centerDotView.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightDotView.centerYAnchor.constraint(equalTo: centerYAnchor),

            rightDotView.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
            leftDotLeftConstraint,

            centerToRightDistanceConstraint!,
            leftToCenterDistanceConstraint!,
        ]
        NSLayoutConstraint.activate(subviewConstraints)

        initialConstraintsCreated = true

        super.updateConstraints()
    }

    func centerToRightDistance(forProgress progress: CGFloat) -> CGFloat {
        -(4 + (10 * (1 - progress)))
    }

    func leftToCenterDistance(forProgress progress: CGFloat) -> CGFloat {
        -(4 + (20 * (1 - progress)))
    }

    // MARK: Private

    private let leftDotView = MenuDotView()
    private let centerDotView = MenuDotView()
    private let rightDotView = MenuDotView()

    private var initialConstraintsCreated = false
    private var centerToRightDistanceConstraint: NSLayoutConstraint?
    private var leftToCenterDistanceConstraint: NSLayoutConstraint?
}
