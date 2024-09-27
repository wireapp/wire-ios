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

/// A view that lays out its subviews along rows horizontally
/// (up to its constrained width), adding new rows vertically
/// if needed.

final class GridLayoutView: UIView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    // MARK: - Properties

    var verticalSpacing: CGFloat = 4
    var horizontalSpacing: CGFloat = 4

    private(set) var views = [UIView]()

    var widthForCalculations: CGFloat = 0

    // MARK: - Layout

    func prepareForReuse() {
        stackView.removeArrangedSubviews()
        views.removeAll(keepingCapacity: true)
    }

    func configure(views: [UIView]) {
        prepareForReuse()
        self.views = views
        setNeedsLayout()
        layoutIfNeeded()
    }

    override func layoutSubviews() {
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

    // MARK: Private

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = verticalSpacing
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private func setUpViews() {
        addSubview(stackView)
        stackView.fitIn(view: self)
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
