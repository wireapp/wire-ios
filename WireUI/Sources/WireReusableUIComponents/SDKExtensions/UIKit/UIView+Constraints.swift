//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
    func fitIn(view: UIView, insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right),
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom)
        ])
    }

    func constraintToSize(_ size: CGSize) {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: size.width),
            heightAnchor.constraint(equalToConstant: size.height)
        ])
    }

    func constraintToSquare(sideLength: CGFloat) {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: sideLength),
            heightAnchor.constraint(equalToConstant: sideLength)
        ])
    }

    func center(in view: UIView) {
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
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
}
