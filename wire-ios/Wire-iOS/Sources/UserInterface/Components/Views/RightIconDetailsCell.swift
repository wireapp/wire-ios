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

class RightIconDetailsCell: DetailsCollectionViewCell {
    // MARK: Internal

    var accessory: UIImage? {
        get { accessoryIconView.image }
        set { updateAccessory(newValue) }
    }

    var accessoryColor: UIColor {
        get { accessoryIconView.tintColor }
        set { accessoryIconView.tintColor = newValue }
    }

    override func setUp() {
        super.setUp()

        accessoryIconView.translatesAutoresizingMaskIntoConstraints = false
        accessoryIconView.contentMode = .center

        contentStackView.insertArrangedSubview(accessoryIconView, at: contentStackView.arrangedSubviews.count)
    }

    // MARK: Private

    private let accessoryIconView = UIImageView()

    private func updateAccessory(_ newValue: UIImage?) {
        if let value = newValue {
            accessoryIconView.image = value
            accessoryIconView.isHidden = false
        } else {
            accessoryIconView.isHidden = true
        }
    }
}
