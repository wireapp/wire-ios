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
import WireDataModel
import WireSyncEngine

final class BurstTimestampSenderMessageCellDescription: ConversationMessageCellDescription {
    typealias View = BurstTimestampSenderMessageCell

    var conversationCellModel: ConversationCellModel? {
        let text: String
        if configuration.includeDayOfWeek {
            text = configuration.date.olderThanOneWeekdateFormatter.string(from: configuration.date)
        } else {
            text = configuration.date.formattedDate
        }
        return .timeDivider(
            text: text,
            isUnread: configuration.showUnreadDot
        )
    }

    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: CGFloat = 0

    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(
        message: ZMConversationMessage,
        context: ConversationMessageContext,
        accentColor: UIColor
    ) {

        self.configuration = View.Configuration(
            date: message.serverTimestamp ?? Date(),
            includeDayOfWeek: context.isFirstMessageOfTheDay,
            showUnreadDot: context.isFirstUnreadMessage,
            accentColor: accentColor
        )
        self.actionController = nil
    }

    init(configuration: View.Configuration) {
        self.configuration = configuration
    }

}

final class BurstTimestampSenderMessageCell: UIView, ConversationMessageCell {

    struct Configuration {
        let date: Date
        let includeDayOfWeek: Bool
        let showUnreadDot: Bool
        let accentColor: UIColor
    }

    private var timer: Timer?

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    weak var actionController: ConversationMessageActionController?

    func willDisplay() {
        startTimer()
    }

    func didEndDisplaying() {
        stopTimer()
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
//            self?.reconfigure()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Cell

    var isSelected: Bool = false

    func configure(with object: Configuration, animated: Bool) {}

}
