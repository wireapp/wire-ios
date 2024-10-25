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

final class SearchGroupSelector: UIView {

    // MARK: - Properties

    var onGroupSelected: ((SearchGroup) -> Void)?

    var group: SearchGroup = .people {
        didSet {
            onGroupSelected?(group)
        }
    }

    private let segmentedControl: UISegmentedControl
    private let groups: [SearchGroup]

    // MARK: - Init

    init() {
        groups = SearchGroup.all

        let groupItems: [String] = groups.map { $0.name }

        segmentedControl = UISegmentedControl(items: groupItems)
        super.init(frame: .zero)

        configureViews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Configuration and constraints

    private func configureViews() {
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)

        backgroundColor = SemanticColors.View.backgroundDefault

        addSubview(segmentedControl)
    }

    private func configureConstraints() {
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            segmentedControl.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            segmentedControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
    }

    // MARK: - Actions

    @objc
    private func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        group = groups[sender.selectedSegmentIndex]
    }
}
