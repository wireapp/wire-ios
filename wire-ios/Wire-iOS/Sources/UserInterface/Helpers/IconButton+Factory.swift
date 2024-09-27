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

extension IconButton {
    static let width: CGFloat = 64
    static let height: CGFloat = 64

    static func acceptCall() -> IconButton {
        .init(
            icon: .phone,
            accessibilityId: "AcceptButton",
            backgroundColor: [UIControl.State.normal.rawValue: SemanticColors.Button.backgroundPickUp],
            iconColor: [UIControl.State.normal.rawValue: .white],
            width: IconButton.width
        )
    }

    static func endCall() -> IconButton {
        .init(
            icon: .endCall,
            size: .small,
            accessibilityId: "LeaveCallButton",
            backgroundColor: [UIControl.State.normal.rawValue: SemanticColors.Button.backgroundHangUp],
            iconColor: [UIControl.State.normal.rawValue: .white],
            width: IconButton.width
        )
    }

    static func sendButton() -> IconButton {
        let sendButtonIconColor = SemanticColors.Icon.foregroundDefaultWhite

        return IconButton(
            icon: .send,
            accessibilityId: "sendButton",
            backgroundColor: [
                UIControl.State.normal.rawValue: UIColor.accent(),
                UIControl.State.highlighted.rawValue: UIColor.accentDarken,
                UIControl.State.disabled.rawValue: SemanticColors.Button.backgroundSendDisabled,
            ],
            iconColor: [
                UIControl.State.normal.rawValue: sendButtonIconColor,
                UIControl.State.highlighted.rawValue: sendButtonIconColor,
                UIControl.State.disabled.rawValue: sendButtonIconColor,
            ]
        )
    }

    private convenience init(
        icon: StyleKitIcon,
        size: StyleKitIcon.Size = .tiny,
        accessibilityId: String,
        backgroundColor: [UIControl.State.RawValue: UIColor],
        iconColor: [UIControl.State.RawValue: UIColor],
        width: CGFloat? = nil
    ) {
        self.init(fontSpec: .smallLightFont)
        circular = true
        setIcon(icon, size: size, for: .normal)
        accessibilityIdentifier = accessibilityId
        translatesAutoresizingMaskIntoConstraints = false

        for (state, color) in backgroundColor {
            setBackgroundImageColor(color, for: .init(rawValue: state))
        }

        for (state, color) in iconColor {
            setIconColor(color, for: .init(rawValue: state))
        }

        borderWidth = 0

        if let width {
            widthAnchor.constraint(equalToConstant: width).isActive = true
            heightAnchor.constraint(greaterThanOrEqualToConstant: width).isActive = true
        }
    }
}
