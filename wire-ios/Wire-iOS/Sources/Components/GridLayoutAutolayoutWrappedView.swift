//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

import Foundation
import UIKit

/// A wrapper view for GridLayoutView that defines its
/// intrinsic content size.

// TODO: check is this even needed?
public final class GridLayoutAutoLayoutWrappedView: UIView {

    // MARK: - Properties

    private lazy var gridLayoutView = GridLayoutView()

    public override var intrinsicContentSize: CGSize {
        let firstViewMinY = gridLayoutView.views.first?.frame.minY ?? .zero
        let lastViewMaxY = gridLayoutView.views.last?.frame.maxY ?? .zero
        let constraintHeight = lastViewMaxY - firstViewMinY

        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: constraintHeight
        )
    }

    // MARK: - Life cycle

    public init() {
        super.init(frame: .zero)
        addSubview(gridLayoutView)
        gridLayoutView.translatesAutoresizingMaskIntoConstraints = false
        gridLayoutView.fitIn(view: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    public func prepareForReuse() {
        gridLayoutView.prepareForReuse()
    }

    public func configure(views: [UIView]) {
        gridLayoutView.configure(views: views)
        invalidateIntrinsicContentSize()
    }
}
