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

final class SearchGroupSelector: UIView, TabBarDelegate {

    var onGroupSelected: ((SearchGroup) -> Void)?

    var group: SearchGroup = .people {
        didSet {
            onGroupSelected?(group)
        }
    }

    // MARK: - Views

    private let tabBar: TabBar
    private let groups: [SearchGroup]

    // MARK: - Initialization

    init() {
        groups = SearchGroup.all

        let groupItems: [UITabBarItem] = groups.enumerated().map { index, group in
            UITabBarItem(title: group.name, image: nil, tag: index)
        }

        tabBar = TabBar(items: groupItems, selectedIndex: 0)
        super.init(frame: .zero)

        configureViews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        tabBar.delegate = self
        backgroundColor = SemanticColors.View.backgroundDefault
        addSubview(tabBar)
    }

    private func configureConstraints() {
        tabBar.fitIn(view: self)
    }

    // MARK: - Tab Bar Delegate

    func tabBar(_ tabBar: TabBar, didSelectItemAt index: Int) {
        group = groups[index]
    }
}
