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

public protocol Anchorable {
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
}

extension UIView: Anchorable { }
extension UILayoutGuide: Anchorable { }

public extension UIView {

    /// Fits `self` within a specified container view with optional insets.
    /// - Parameters:
    ///   - view: The container view in which to fit `self`.
    ///   - insets: Insets to apply on each side of `self` relative to the container.
    @discardableResult
    func pin(to view: any Anchorable, insets: UIEdgeInsets = .zero) -> Self {
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
    func setTranslatesAutoresizingMaskIntoConstraints(_ value: Bool) -> Self {
        translatesAutoresizingMaskIntoConstraints = value
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
}

extension UIStackView {
    
    public static func horizontal(
        views: [UIView] = [],
        spacing: CGFloat = 0,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill
    ) -> UIStackView {
        return UIStackView.make(views: views, spacing: spacing, axis: .horizontal, alignment: alignment, distribution: distribution)
    }
    
    public static func vertical(
        views: [UIView] = [],
        spacing: CGFloat = 0,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill) -> UIStackView {
            return UIStackView.make(views: views, spacing: spacing, axis: .vertical, alignment: alignment, distribution: distribution)
        }
}

