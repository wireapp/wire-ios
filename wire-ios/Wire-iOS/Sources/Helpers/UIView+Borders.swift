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

extension UIView {
    func addBorder(
        for anchor: Anchor,
        color: UIColor = SemanticColors.View.backgroundSeparatorCell,
        borderWidth: CGFloat = 1.0
    ) {
        let border = UIView()
        addSubview(border)
        border.addConstraintsForBorder(for: anchor, borderWidth: borderWidth, to: self)
        border.backgroundColor = color
    }

    func addConstraintsForBorder(for anchor: Anchor, borderWidth: CGFloat, to parentView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        switch anchor {
        case .top:
            NSLayoutConstraint.activate([
                topAnchor.constraint(equalTo: parentView.topAnchor),
                leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
                trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
                heightAnchor.constraint(equalToConstant: borderWidth),
            ])
        case .bottom:
            NSLayoutConstraint.activate([
                bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
                leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
                trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
                heightAnchor.constraint(equalToConstant: borderWidth),
            ])
        case .leading:
            NSLayoutConstraint.activate([
                leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
                topAnchor.constraint(equalTo: parentView.topAnchor),
                bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
                widthAnchor.constraint(equalToConstant: borderWidth),
            ])
        case .trailing:
            NSLayoutConstraint.activate([
                trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
                topAnchor.constraint(equalTo: parentView.topAnchor),
                bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
                widthAnchor.constraint(equalToConstant: borderWidth),
            ])
        }
    }
}
