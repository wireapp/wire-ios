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

extension UIView {

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
}

// TODO: until merged in
public extension UIView {
 
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
    
    func pinOptionally(to view: UIView,
                       topInset: CGFloat? = nil,
                       bottomInset: CGFloat? = nil,
                       leadingInset: CGFloat? = nil,
                       trailingInset: CGFloat? = nil) {
        translatesAutoresizingMaskIntoConstraints = false
        var constraints = [NSLayoutConstraint]()
        if let leadingInset {
            constraints.append(leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leadingInset))
        }
        if let trailingInset {
            constraints.append(view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: trailingInset))
        }
        
        if let topInset {
            constraints.append(topAnchor.constraint(equalTo: view.topAnchor, constant: topInset))
        }
        if let bottomInset {
            constraints.append(view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: bottomInset))
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
}

extension UIStackView {
    
    public static func horizontal(views: [UIView] = [],
                                  spacing: CGFloat = 0,
                                  alignment: UIStackView.Alignment = .fill,
                                  distribution: UIStackView.Distribution = .fill) -> UIStackView {
        return UIStackView.make(views: views, spacing: spacing, axis: .horizontal, alignment: alignment, distribution: distribution)
    }
    
    public static func vertical(views: [UIView] = [],
                                spacing: CGFloat = 0,
                                alignment: UIStackView.Alignment = .fill,
                                distribution: UIStackView.Distribution = .fill) -> UIStackView {
        return UIStackView.make(views: views, spacing: spacing, axis: .vertical, alignment: alignment, distribution: distribution)
    }
    
    public func add(subviews: UIView...) {
        for view in subviews {
            addArrangedSubview(view)
        }
    }
    
    public static func make(views: [UIView],
                            spacing: CGFloat,
                            axis: NSLayoutConstraint.Axis,
                            alignment: UIStackView.Alignment,
                            distribution: UIStackView.Distribution) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.alignment = alignment
        stackView.distribution = distribution
        stackView.spacing = spacing
        stackView.axis = axis
        return stackView
    }
}

extension Array where Element: UIView {
    
    public func hStack(spacing: CGFloat = 0,
                       alignment: UIStackView.Alignment = .fill,
                       distribution: UIStackView.Distribution = .fill) -> UIStackView {
        return UIStackView.make(views: self, spacing: spacing, axis: .horizontal, alignment: alignment, distribution: distribution)
    }
    
    public func vStack(spacing: CGFloat = 0,
                       alignment: UIStackView.Alignment = .fill,
                       distribution: UIStackView.Distribution = .fill) -> UIStackView {
        return UIStackView.make(views: self, spacing: spacing, axis: .vertical, alignment: alignment, distribution: distribution)
    }
}

