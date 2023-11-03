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

/// A view that lays out its subviews along rows horizontally
/// (up to its constrained width), adding new rows vertically
/// if needed.

public final class GridLayoutView: UIView {

    // MARK: - Properties

    var verticalSpacing: CGFloat = 4
    var horizontalSpacing: CGFloat = 4

    private(set) var views = [UIView]()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = verticalSpacing
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // MARK: - Life cycle

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        addSubview(stackView)
        stackView.fitIn(view: self)
    }

    // MARK: - Layout
    public func prepareForReuse() {
        stackView.removeArrangedSubviews()
        views.removeAll(keepingCapacity: true)
    }

    public func configure(views: [UIView]) {
        prepareForReuse()
        self.views = views
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    public var widthForCalculations: CGFloat = 0
    
    public override func layoutSubviews() {
        super.layoutSubviews()

        guard !views.isEmpty else { return }

        stackView.removeArrangedSubviews()

        var lineWidth: CGFloat = 0

        var currentLineStackView = createNewRow()
        stackView.addArrangedSubview(currentLineStackView)

        for view in views {
            let viewSize = view.systemLayoutSizeFitting(currentLineStackView.bounds.size)

            if lineWidth + viewSize.width > widthForCalculations {
                currentLineStackView = createNewRow()
                stackView.addArrangedSubview(currentLineStackView)
                lineWidth = 0
            }

            currentLineStackView.addArrangedSubview(view)
            lineWidth += viewSize.width + horizontalSpacing
        }
    }

    private func createNewRow() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = horizontalSpacing
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }

}
