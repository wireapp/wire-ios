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

import UIKit

class ReactionCollectionViewCell: UICollectionViewCell {

    private var reactionToggleButton = ReactionToggleButton()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureData(type: String, count: Int, isToggled: Bool) {
        reactionToggleButton.configureData(type: type, count: count, isToggled: isToggled)
    }

    func addViews() {
        backgroundColor = .clear
        addSubview(reactionToggleButton)

        reactionToggleButton.translatesAutoresizingMaskIntoConstraints = false

        reactionToggleButton.fitIn(view: self)
    }

}
