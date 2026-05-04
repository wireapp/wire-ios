//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

package import UIKit
package import WireMessagingDomain

package class ConversationChannelIconUIKit: UIView {
    private enum Constants {
        static let padlockSize: CGFloat = 14
        static let padlockOverhang: CGFloat = 4
    }

    private let iconView: UIImageView
    private let padlockView: UIImageView?

    package init(asset: ConversationChannelIconAsset, isPrivateChannel: Bool) {
        self.iconView = UIImageView(image: asset.uiKitImage)
        self.padlockView = isPrivateChannel ? Self.makePadlockView() : nil

        super.init(frame: .zero)

        addSubview(iconView)
        padlockView.map { addSubview($0) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    package override func layoutSubviews() {
        super.layoutSubviews()

        iconView.frame = bounds
        padlockView?.frame = CGRect(
            x: bounds.maxX - Constants.padlockSize + Constants.padlockOverhang,
            y: bounds.maxY - Constants.padlockSize + Constants.padlockOverhang,
            width: Constants.padlockSize,
            height: Constants.padlockSize
        )
    }

    // MARK: - Private

    private static func makePadlockView() -> UIImageView {
        UIImageView(image: UIImage(named: "lock", in: .resources, with: nil))
    }

}
