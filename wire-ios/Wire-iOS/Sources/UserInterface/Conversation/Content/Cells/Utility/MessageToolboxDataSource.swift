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

/// The different contents that can be displayed inside the message toolbox.
enum MessageToolboxContent: Equatable {
    /// Display buttons to let the user resend the message.
    case sendFailure(String)

    /// Display list of calls
    case callList(String)

    /// Display the message details (timestamp and/or status and/or countdown).
    case details(timestamp: String, status: MessageToolboxState?, countdown: String)
}

extension MessageToolboxContent: Comparable {

    /// Returns whether one content is located above or below the other.
    /// This is used to determine from which direction to slide, so that we can keep
    /// the animations logical.
    static func < (lhs: MessageToolboxContent, rhs: MessageToolboxContent) -> Bool {
        switch (lhs, rhs) {
        case (.sendFailure, _):
            true
        case (.details, _):
            true
        default:
            false
        }
    }

}

enum MessageToolboxState: Equatable {
    case sending
    case sent
    case delivered
    case seen
    case seenByMultiple(Int)
}

// MARK: - Data Source

/// An object that determines what content to display for the given message.

typealias ConversationMessage = SwiftConversationMessage & ZMConversationMessage

final class MessageToolboxDataSource {

    typealias ContentSystem = L10n.Localizable.Content.System

    /// The displayed message.
    let message: ConversationMessage

    var editedString: String? {
        guard message.updatedAt != nil else { return nil }

        return L10n.Localizable.Content.Message.edited
    }

    /// The content to display for the message.
    private(set) var content: MessageToolboxContent

    // MARK: - Formatting Properties

    private static let ephemeralTimeFormatter = EphemeralTimeoutFormatter()

    // MARK: - Initialization

    /// Creates a toolbox data source for the given message.
    init(message: ConversationMessage) {
        self.message = message
        self.content = .details(timestamp: "", status: nil, countdown: "")
    }

    // MARK: - Content

    /// Updates the contents of the message toolbox.
    /// - parameter widthConstraint: The width available to rend the toolbox contents.
    /// - Returns: A boolean to either update the content of the message toolbox or not
    func shouldUpdateContent(widthConstraint: CGFloat) -> Bool {
        // Compute the state
        let previousContent = content

        // Determine the content by priority

        // [WPB-6988] removed performed call
        if message.systemMessageData?.systemMessageType == .performedCall {
            return false
        }
        // 1b) Call list for missed calls
        else if message.systemMessageData?.systemMessageType == .missedCall {
            content = .callList(makeCallList())
        }
        // 2) Failed to send
        else if let errorMessage = MessageErrorHelper.errorMessage(message) {
            content = .sendFailure(errorMessage)
        }

        // 3) Timestamp
        else {
            let (timestamp, status, countdown) = makeDetailsString()
            content = .details(timestamp: timestamp, status: status, countdown: countdown)
        }

        // Only perform the changes if the content did change.
        guard previousContent != content else {
            return false
        }

        return true
    }

    // MARK: - Details Text

    /// Creates a label that display the status of the message.
    private func makeDetailsString() -> (
        String,
        MessageToolboxState?,
        String
    ) {
        let countdownStatus = makeEphemeralCountdown()
        let deliveryState = message.shouldShowDeliveryState ? selfMessageState(for: message) : nil
        let isTimestampVisible = message.isSent && message.deliveryState != .failedToSend
        let timestampString = isTimestampVisible ? message.formattedReceivedTime() ?? "" : ""
        return (timestampString, deliveryState, countdownStatus)
    }

    private func makeEphemeralCountdown() -> String {
        let showDestructionTimer = message.isEphemeral &&
            !message.isObfuscated &&
            message.destructionDate != nil &&
            message.deliveryState != .pending

        guard let destructionDate = message.destructionDate, showDestructionTimer else { return "" }

        // We need to add one second to start with the correct value
        let remaining = destructionDate.timeIntervalSinceNow + 1

        if remaining > 0 {
            if let string = MessageToolboxDataSource.ephemeralTimeFormatter.string(from: remaining) {
                return string
            }
        } else if message.isAudio {
            // do nothing, audio messages are allowed to extend the timer
            // past the destruction date.
        }
        return ""
    }

    // MARK: - message delivery state

    /// Returns the status for the sender of the message.
    private func selfMessageState(for message: ZMConversationMessage) -> MessageToolboxState? {
        guard let sender = message.senderUser, sender.isSelfUser else {
            return nil
        }

        switch message.deliveryState {
        case .pending:
            return .sending
        case .read where message.conversationLike?.conversationType == .group:
            return .seenByMultiple(message.readReceipts.count)
        case .read where message.conversationLike?.conversationType == .oneOnOne:
            return .seen
        case .delivered:
            return .delivered
        case .sent:
            return .sent
        default:
            return nil
        }
    }

    /// Creates the status for the read receipts.
    private func readDeliveryStateAttributedString(for message: ZMConversationMessage) -> MessageToolboxState? {
        guard let conversationType = message.conversationLike?.conversationType else { return nil }

        switch conversationType {
        case .group:
            return .seenByMultiple(message.readReceipts.count)

        case .oneOnOne:
            return .seen

        default:
            return nil
        }
    }

    // MARK: - Call List

    /// Create a timestamp list for all calls associated with a call system message
    private func makeCallList() -> String {
        guard let childMessages = message.systemMessageData?.childMessages, !childMessages.isEmpty,
              let timestamp = timestampString(message) else {
            return timestampString(message) ?? ""
        }

        let childrenTimestamps = childMessages
            .compactMap { $0 as? ZMConversationMessage }
            .sortedAscendingPrependingNil(by: \.serverTimestamp)
            .compactMap(timestampString)

        return childrenTimestamps.reduce(timestamp) { text, current in
            "\(text)\n\(current)"
        }
    }

    /// Creates the timestamp text.
    private func timestampString(_ message: ZMConversationMessage) -> String? {
        var timestampString: String?

        if let editedTimeString = message.formattedEditedDate() {
            timestampString = ContentSystem.editedMessagePrefixTimestamp(editedTimeString)
        } else if let dateTimeString = message.formattedReceivedDateTime(),
                  let systemMessage = message as? ZMSystemMessage,
                  systemMessage.systemMessageType == .messageDeletedForEveryone {
            timestampString = ContentSystem.deletedMessagePrefixTimestamp(dateTimeString)
        }

        return timestampString
    }

}
