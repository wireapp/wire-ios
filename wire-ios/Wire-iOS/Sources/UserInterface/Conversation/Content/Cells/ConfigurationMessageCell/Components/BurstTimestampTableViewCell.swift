//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireConversationUI

final class BurstTimestampSenderMessageCellDescription: ConversationMessageCellDescription {
    typealias View = BurstTimestampSenderMessageCell

    var conversationCellModel: ConversationCellModel? {

        let text = if configuration.isFirstMessageOfTheDay {
            configuration.date.olderThanOneWeekdateFormatter.string(from: configuration.date)
        } else {
            configuration.date.formattedDate
        }

        let model = TimeDividerModel(text: text, isUnreadIndicatorVisible: configuration.showUnreadDot)
        return .timeDivider(model)

    }

    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer = false
    var topMargin = CGFloat()

    let containsHighlightableContent = false

    let accessibilityIdentifier = String?.none
    let accessibilityLabel = String?.none

    init(
        message: ZMConversationMessage,
        context: ConversationMessageContext,
        accentColor: UIColor
    ) {
        self.configuration = View.Configuration(
            date: message.serverTimestamp ?? Date(),
            isFirstMessageOfTheDay: context.isFirstMessageOfTheDay,
            showUnreadDot: context.isFirstUnreadMessage,
            accentColor: accentColor
        )
    }

}

final class BurstTimestampSenderMessageCell: UIView, ConversationMessageCell {

    struct Configuration {
        let date: Date
        let isFirstMessageOfTheDay: Bool
        let showUnreadDot: Bool
        let accentColor: UIColor
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    weak var actionController: ConversationMessageActionController?

    var isSelected: Bool = false

    func willDisplay() {}
    func didEndDisplaying() {}

    func configure(with object: Configuration, animated: Bool) {}

}
