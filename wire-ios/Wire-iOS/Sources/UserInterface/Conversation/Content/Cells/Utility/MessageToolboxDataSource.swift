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
import WireDataModel
import WireDesign

/// The different contents that can be displayed inside the message toolbox.
enum MessageToolboxContent: Equatable {
    /// Display buttons to let the user resend the message.
    case sendFailure(NSAttributedString)

    /// Display list of calls
    case callList(NSAttributedString)

    /// Display the message details (timestamp and/or status and/or countdown).
    case details(timestamp: NSAttributedString?, status: NSAttributedString?, countdown: NSAttributedString?)
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

// MARK: - Data Source

/// An object that determines what content to display for the given message.

typealias ConversationMessage = SwiftConversationMessage & ZMConversationMessage

final class MessageToolboxDataSource {
    typealias ContentSystem = L10n.Localizable.Content.System

    /// The displayed message.
    let message: ConversationMessage

    /// The content to display for the message.
    private(set) var content: MessageToolboxContent

    // MARK: - Formatting Properties

    private let statusTextColor = SemanticColors.Label.textMessageDetails
    private let statusFont = FontSpec.smallRegularFont.font!
    private static let ephemeralTimeFormatter = EphemeralTimeoutFormatter()

    private var attributes: [NSAttributedString.Key: AnyObject] {
        [.font: statusFont, .foregroundColor: statusTextColor]
    }

    // MARK: - Initialization

    /// Creates a toolbox data source for the given message.
    init(message: ConversationMessage) {
        self.message = message
        self.content = .details(timestamp: nil, status: nil, countdown: nil)
    }

    // MARK: - Content

    /// Updates the contents of the message toolbox.
    /// - parameter widthConstraint: The width available to rend the toolbox contents.
    /// - Returns: A boolean to either update the content of the message toolbox or not
    func shouldUpdateContent(widthConstraint: CGFloat) -> Bool {
        typealias FailedToSendMessage = L10n.Localizable.Content.System.FailedtosendMessage

        // Compute the state
        let isSentBySelfUser = message.senderUser?.isSelfUser == true
        let failedToSend = message.deliveryState == .failedToSend && isSentBySelfUser
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
        else if failedToSend, isSentBySelfUser {
            var detailsString: String = switch message.failedToSendReason {
            case .unknown, .none:
                FailedToSendMessage.generalReason
            case .federationRemoteError:
                FailedToSendMessage.federationRemoteErrorReason(
                    message.conversationLike?.domain ?? "",
                    WireURLs.shared.unreachableBackendInfo.absoluteString
                )
            }

            content = .sendFailure(detailsString && attributes)
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

    /// Create a timestamp list for all calls associated with a call system message
    private func makeCallList() -> NSAttributedString {
        if let childMessages = message.systemMessageData?.childMessages, !childMessages.isEmpty,
           let timestamp = timestampString(message) {
            let childrenTimestamps = childMessages
                .compactMap { $0 as? ZMConversationMessage }
                .sortedAscendingPrependingNil(by: \.serverTimestamp)
                .compactMap(timestampString)

            let finalText = childrenTimestamps.reduce(timestamp) { text, current in
                "\(text)\n\(current)"
            }

            return finalText && attributes
        } else {
            return timestampString(message) ?? "-" && attributes
        }
    }

    /// Creates a label that display the status of the message.
    private func makeDetailsString() -> (NSAttributedString?, NSAttributedString?, NSAttributedString?) {
        let countdownStatus = makeEphemeralCountdown()

        let deliveryStateString = selfMessageStatus(for: message)

        if let timestampString = timestampString(message), message.isSent {
            if let deliveryStateString, message.shouldShowDeliveryState {
                return (timestampString && attributes, deliveryStateString, countdownStatus)
            } else {
                return (timestampString && attributes, nil, countdownStatus)
            }
        } else {
            return (nil, deliveryStateString, countdownStatus)
        }
    }

    private func makeEphemeralCountdown() -> NSAttributedString? {
        let showDestructionTimer = message.isEphemeral &&
            !message.isObfuscated &&
            message.destructionDate != nil &&
            message.deliveryState != .pending

        if let destructionDate = message.destructionDate, showDestructionTimer {
            let remaining = destructionDate
                .timeIntervalSinceNow + 1 // We need to add one second to start with the correct value

            if remaining > 0 {
                if let string = MessageToolboxDataSource.ephemeralTimeFormatter.string(from: remaining) {
                    return string && attributes
                }
            } else if message.isAudio {
                // do nothing, audio messages are allowed to extend the timer
                // past the destruction date.
            }
        }

        return nil
    }

    /// Returns the status for the sender of the message.
    private func selfMessageStatus(for message: ZMConversationMessage) -> NSAttributedString? {
        guard let sender = message.senderUser, sender.isSelfUser else {
            return nil
        }

        var deliveryStateString: String

        switch message.deliveryState {
        case .pending:
            deliveryStateString = ContentSystem.pendingMessageTimestamp
        case .read:
            return selfStatusForReadDeliveryState(for: message)
        case .delivered:
            deliveryStateString = ContentSystem.messageDeliveredTimestamp
        case .sent:
            deliveryStateString = ContentSystem.messageSentTimestamp
        case .invalid, .failedToSend:
            return nil
        }

        return NSAttributedString(string: deliveryStateString) && attributes
    }

    private func seenTextAttachment() -> NSTextAttachment {
        let imageIcon = NSTextAttachment.textAttachment(for: .eye, with: statusTextColor, verticalCorrection: -1)
        imageIcon.accessibilityLabel = "seen"
        return imageIcon
    }

    /// Creates the status for the read receipts.
    private func selfStatusForReadDeliveryState(for message: ZMConversationMessage) -> NSAttributedString? {
        guard let conversationType = message.conversationLike?.conversationType else { return nil }

        switch conversationType {
        case .group:
            let attributes: [NSAttributedString.Key: AnyObject] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: statusTextColor,
            ]

            let imageIcon = seenTextAttachment()
            let attributedString = NSAttributedString(attachment: imageIcon) + " \(message.readReceipts.count)" &&
                attributes
            attributedString
                .accessibilityLabel = (imageIcon.accessibilityLabel ?? "") + " \(message.readReceipts.count)"
            return attributedString

        case .oneOnOne:
            guard let timestamp = message.readReceipts.first?.serverTimestamp else {
                return nil
            }

            let imageIcon = seenTextAttachment()

            let timestampString = message.formattedDate(timestamp)
            let attributedString = NSAttributedString(attachment: imageIcon) + " " + timestampString && attributes
            attributedString.accessibilityLabel = (imageIcon.accessibilityLabel ?? "") + " " + timestampString
            return attributedString

        default:
            return nil
        }
    }

    /// Creates the timestamp text.
    private func timestampString(_ message: ZMConversationMessage) -> String? {
        var timestampString: String?

        if let editedTimeString = message.formattedEditedDate() {
            timestampString = ContentSystem.editedMessagePrefixTimestamp(editedTimeString)
        } else if let dateTimeString = message.formattedReceivedDate(),
                  let systemMessage = message as? ZMSystemMessage,
                  systemMessage.systemMessageType == .messageDeletedForEveryone {
            timestampString = ContentSystem.deletedMessagePrefixTimestamp(dateTimeString)
        }

        return timestampString
    }
}
