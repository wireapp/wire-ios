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

public extension UIStackView {

    static func horizontal(
        spacing: CGFloat = 0,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill
    ) -> UIStackView {
        UIStackView.make(spacing: spacing, axis: .horizontal, alignment: alignment, distribution: distribution)
    }

    static func vertical(
        spacing: CGFloat = 0,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill
    ) -> UIStackView {
        UIStackView.make(spacing: spacing, axis: .vertical, alignment: alignment, distribution: distribution)
    }
    
    static func make(
        views: [UIView] = [],
        spacing: CGFloat,
        axis: NSLayoutConstraint.Axis,
        alignment: UIStackView.Alignment,
        distribution: UIStackView.Distribution
    ) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.alignment = alignment
        stackView.distribution = distribution
        stackView.spacing = spacing
        stackView.axis = axis
        return stackView
    }
}


extension Array where Element: UIView {
    
    @MainActor
    public func horizontalStack(
        spacing: CGFloat = 0,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill) -> UIStackView {
            UIStackView.make(views: self, spacing: spacing, axis: .horizontal, alignment: alignment, distribution: distribution)
        }
    
    @MainActor
    public func verticalStack(
        spacing: CGFloat = 0,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill
    ) -> UIStackView {
        UIStackView.make(views: self, spacing: spacing, axis: .vertical, alignment: alignment, distribution: distribution)
    }
}
