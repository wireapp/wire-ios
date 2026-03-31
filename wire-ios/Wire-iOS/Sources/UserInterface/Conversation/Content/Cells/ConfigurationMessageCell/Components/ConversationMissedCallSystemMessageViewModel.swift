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

import UIKit
import WireCommonComponents
import WireDataModel
import WireDesign

struct ConversationMissedCallSystemMessageViewModel {

    let icon: StyleKitIcon
    let iconColor: UIColor?
    let systemMessageType: ZMSystemMessageType
    let font: UIFont?
    let textColor: UIColor?
    let message: ZMConversationMessage

    func image() -> UIImage? {
        iconColor.map { icon.makeImage(size: .tiny, color: $0) }
    }

    func attributedTitle() -> NSAttributedString? {
        guard
            let systemMessageData = message.systemMessageData,
            systemMessageData.systemMessageType == systemMessageType,
            let sender = message.senderUser,
            let labelFont = font,
            let labelTextColor = textColor
        else {
            return nil
        }

        let numberOfCalls = systemMessageData.childMessages.count + 1
        typealias Call = L10n.Localizable.Content.System.Call

        let isGroup = message.conversationLike?.conversationType == .group
        let senderName = sender.name ?? ""

        let counterSuffix = numberOfCalls > 1 ? " (\(numberOfCalls))" : ""
        let finalText = (isGroup ? Call.MissedCall.groups(numberOfCalls, senderName) : Call.missedCall(numberOfCalls)) +
            counterSuffix

        return NSAttributedString(
            string: finalText,
            attributes: [
                .font: labelFont,
                .foregroundColor: labelTextColor
            ]
        )
    }
}
