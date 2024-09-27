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
import WireCommonComponents
import WireDesign

// MARK: - Constants

enum Constants {
    static var teamAccountViewImageInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
}

// MARK: - Float.ConversationButtonMessageCell

extension Float {
    enum ConversationButtonMessageCell {
        static let verticalInset: Float = 8
    }
}

// MARK: - StyleKitIcon.Size.CreatePasscode

extension StyleKitIcon.Size {
    enum CreatePasscode {
        static let iconSize: StyleKitIcon.Size = .custom(11)
        static let errorIconSize: StyleKitIcon.Size = .custom(13)
    }
}

extension CGFloat {
    enum iPhone4Inch {
        static let width: CGFloat = 320
        static let height: CGFloat = 568
    }

    enum iPhone4_7Inch {
        static let width: CGFloat = 375
        static let height: CGFloat = 667
    }

    enum WipeCompletion {
        static let buttonHeight: CGFloat = 48
    }

    enum PasscodeUnlock {
        static let textFieldHeight: CGFloat = 40
        static let buttonHeight: CGFloat = 40
        static let buttonPadding: CGFloat = 24
    }

    enum AccessoryTextField {
        static let horizonalInset: CGFloat = 16
    }

    enum SpinnerButton {
        static let contentInset: CGFloat = 16
        static let iconSize: CGFloat = StyleKitIcon.Size.tiny.rawValue
        static let spinnerBackgroundAlpha: CGFloat = 0.93
    }

    enum MessageCell {
        static var paragraphSpacing: CGFloat = 8
    }

    enum IconCell {
        static let IconWidth: CGFloat = 64
        static let IconSpacing: CGFloat = 16
    }

    enum StartUI {
        static let CellHeight: CGFloat = 56
    }

    enum SplitView {
        static let LeftViewWidth: CGFloat = 336

        /// on iPad 9.7 inch 2/3 mode, right view's width is  396pt, use the compact mode's narrower margin
        /// when the window is small then or equal to (396 + LeftViewWidth = 732), use compact mode margin
        static let IPadMarginLimit: CGFloat = 732
    }

    enum ConversationList {
        static let horizontalMargin: CGFloat = 16
    }

    enum ConversationListHeader {
        static let iconWidth: CGFloat = 32
        /// 75% of ConversationAvatarView.iconWidth + TeamAccountView.imageInset * 2 = 24 + 2 * 2
        static let avatarSize: CGFloat = 24 + Constants.teamAccountViewImageInsets.left + Constants
            .teamAccountViewImageInsets.right

        static let barHeight: CGFloat = 44
    }

    enum ConversationListSectionHeader {
        static let height: CGFloat = 51
    }

    enum ConversationAvatarView {
        static let iconSize: CGFloat = 32
    }

    enum AccountView {
        static let iconWidth: CGFloat = 32
    }
}
