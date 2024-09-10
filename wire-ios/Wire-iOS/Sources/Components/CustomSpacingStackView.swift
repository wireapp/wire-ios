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

final class CustomSpacingStackView: UIView {
    private var stackView: UIStackView

    /**
     This initializer must be used if you intend to call wr_addCustomSpacing.
     */
    init(customSpacedArrangedSubviews subviews: [UIView]) {
        stackView = UIStackView(arrangedSubviews: subviews)

        super.init(frame: .zero)

        addSubview(stackView)
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     Add a custom spacing after a view.

     This is a approximation of the addCustomSpacing method only available since iOS 11. This method
     has several constraints:

     - The stackview must be initialized with customSpacedArrangedSubviews
     - spacing dosesn't update if views are hidden after this method is called
     - custom spacing can't be smaller than 2x the minimum spacing

     On iOS 11, it uses the default system implementation.
     */
    func wr_addCustomSpacing(_ customSpacing: CGFloat, after view: UIView) {
        stackView.setCustomSpacing(customSpacing, after: view)
    }

    private func createConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.fitIn(view: self)
    }

    var alignment: UIStackView.Alignment {
        get { stackView.alignment }
        set { stackView.alignment = newValue }
    }

    var distribution: UIStackView.Distribution {
        get { stackView.distribution }
        set { stackView.distribution = newValue }
    }

    var axis: NSLayoutConstraint.Axis {
        get { stackView.axis }
        set { stackView.axis = newValue }
    }

    var spacing: CGFloat {
        get { stackView.spacing }
        set { stackView.spacing = newValue }
    }
}

final class SpacingView: UIView {
    var size: CGFloat

    init(_ size: CGFloat) {
        self.size = size

        super.init(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: size, height: size)))

        isAccessibilityElement = false
        accessibilityElementsHidden = true
        setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .vertical)
        setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: size, height: size)
    }
}

/**
 * A view that can contain a label with additional content insets.
 */

final class ContentInsetView: UIView {
    let view: UIView

    init(_ view: UIView, inset: UIEdgeInsets) {
        self.view = view
        super.init(frame: .zero)

        setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .vertical)
        setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .horizontal)

        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor, constant: inset.top),
            view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: inset.bottom),
            view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset.left),
            view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset.right),
        ])
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        view.intrinsicContentSize
    }
}
