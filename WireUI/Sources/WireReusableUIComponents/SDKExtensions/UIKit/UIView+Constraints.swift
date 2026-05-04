//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

public extension UIView {

    /// Fits `self` within a specified container view with optional insets.
    /// - Parameters:
    ///   - view: The container view in which to fit `self`.
    ///   - insets: Insets to apply on each side of `self` relative to the container.
    @discardableResult
    func pin(to view: UIView, insets: UIEdgeInsets = .zero) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right),
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom)
        ])
        return self
    }

    func constraintToSize(_ size: CGSize) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size.width),
            heightAnchor.constraint(equalToConstant: size.height)
        ])
    }

    func constraintToSquare(sideLength: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: sideLength),
            heightAnchor.constraint(equalToConstant: sideLength)
        ])
    }

    func center(in view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @discardableResult
    func widthConstraint(_ value: CGFloat) -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: value).isActive = true
        return self
    }

    @discardableResult
    func heightConstraint(_ value: CGFloat) -> Self {
        translatesAutoresizingMaskIntoConstraints = false

        heightAnchor.constraint(equalToConstant: value).isActive = true
        return self
    }

    @discardableResult
    func minHeightConstraint(_ value: CGFloat) -> Self {
        translatesAutoresizingMaskIntoConstraints = false

        heightAnchor.constraint(greaterThanOrEqualToConstant: 38).isActive = true
        return self
    }

    @discardableResult
    func setTranslatesAutoresizingMaskIntoConstraints(_ value: Bool) -> Self {
        translatesAutoresizingMaskIntoConstraints = value
        return self
    }

    @discardableResult
    func setIsUserInteractionEnabled(_ value: Bool) -> Self {
        isUserInteractionEnabled = value
        return self
    }

    @discardableResult
    func setIsHidden(_ value: Bool) -> Self {
        isHidden = value
        return self
    }
}

public extension UIView {

    func wrapInView(
        topInset: CGFloat = 0,
        leadingInset: CGFloat = 0,
        bottomInset: CGFloat = 0,
        trailingInset: CGFloat = 0
    ) -> UIView {
        let view = UIView()
        view.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        var constraints = [NSLayoutConstraint]()
        constraints.append(leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leadingInset))
        constraints.append(view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: trailingInset))
        constraints.append(topAnchor.constraint(equalTo: view.topAnchor, constant: topInset))
        constraints.append(view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: bottomInset))

        NSLayoutConstraint.activate(constraints)

        return view
    }

    /// Returns a container view which is specifically useful not to stretch its content.
    func wrapInViewWithFlexibleTopAndBottom() -> UIView {
        let view = UIView()
        view.clipsToBounds = false
        translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self)

        let bottomConstraint = view.bottomAnchor.constraint(equalTo: bottomAnchor)
        bottomConstraint.priority = .defaultLow

        let topConstraint = view.topAnchor.constraint(equalTo: topAnchor)
        topConstraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            topConstraint,
            bottomConstraint
        ])

        return view
    }

}
