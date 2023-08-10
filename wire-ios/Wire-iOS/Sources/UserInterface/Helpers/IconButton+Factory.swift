//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

extension IconButton {

    static let width: CGFloat = 64
    static let height: CGFloat = 64

    static func acceptCall() -> IconButton {
        return .init(
            icon: .phone,
            accessibilityId: "AcceptButton",
            backgroundColor: [.normal: SemanticColors.Button.backgroundPickUp],
            iconColor: [.normal: .white],
            width: IconButton.width
        )
    }

    static func endCall() -> IconButton {
        return .init(
            icon: .endCall,
            size: .small,
            accessibilityId: "LeaveCallButton",
            backgroundColor: [.normal: SemanticColors.Button.backgroundHangUp],
            iconColor: [.normal: .white],
            width: IconButton.width
        )
    }

    static func sendButton() -> IconButton {

        let sendButtonIconColor = SemanticColors.Icon.foregroundDefaultWhite

        let sendButton = IconButton(
            icon: .send,
            accessibilityId: "sendButton",
            backgroundColor: [.normal: UIColor.accent(),
                              .highlighted: UIColor.accentDarken,
                              .disabled: SemanticColors.Button.backgroundSendDisabled],
            iconColor: [.normal: sendButtonIconColor,
                        .highlighted: sendButtonIconColor,
                        .disabled: sendButtonIconColor]
        )

        return sendButton
    }

    fileprivate convenience init(
        icon: StyleKitIcon,
        size: StyleKitIcon.Size = .tiny,
        accessibilityId: String,
        backgroundColor: [UIControl.State: UIColor],
        iconColor: [UIControl.State: UIColor],
        width: CGFloat? = nil
    ) {
        self.init(fontSpec: .smallLightFont)
        circular = true
        setIcon(icon, size: size, for: .normal)
        accessibilityIdentifier = accessibilityId
        translatesAutoresizingMaskIntoConstraints = false

        for (state, color) in backgroundColor {
            setBackgroundImageColor(color, for: state)
        }

        for (state, color) in iconColor {
            setIconColor(color, for: state)
        }

        borderWidth = 0

        if let width = width {
            widthAnchor.constraint(equalToConstant: width).isActive = true
            heightAnchor.constraint(greaterThanOrEqualToConstant: width).isActive = true
        }
    }

}

extension UIControl.State: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
}
