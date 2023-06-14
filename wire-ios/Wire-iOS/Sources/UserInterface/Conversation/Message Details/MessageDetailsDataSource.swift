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

import Foundation
import WireDataModel
import WireSyncEngine

/// The way the details are displayed.
enum MessageDetailsDisplayMode: Int {
    case reactions, receipts, combined
}

/**
 * An object that observes changes in the message data source.
 */

protocol MessageDetailsDataSourceObserver: AnyObject {
    /// Called when the message details change.
    func dataSourceDidChange(_ dataSource: MessageDetailsDataSource)

    /// Called when the message subtitle changes.
    func detailsFooterDidChange(_ dataSource: MessageDetailsDataSource)
}

/**
 * The data source to present message details.
 */

final class MessageDetailsDataSource: NSObject, ZMMessageObserver, ZMUserObserver {

    typealias MessageDetails = L10n.Localizable.MessageDetails

    /// The presented message.
    let message: ZMConversationMessage

    /// The conversation where the message is
    let conversation: ZMConversation

    /// How to display the message details.
    let displayMode: MessageDetailsDisplayMode

    /// Whether read receipts are supported.
    let supportsReadReceipts: Bool

    /// The title of the message details.
    let title: String

    /// The subtitle of the message details.
    private(set) var subtitle: String!

    /// The subtitle of the message details for accessibility purposes.
    private(set) var accessibilitySubtitle: String!

    /// The list of likes.
    private(set) var reactions: [MessageDetailsSectionDescription]

    /// The list of read receipts with the associated date.
    private(set) var readReceipts: [MessageDetailsSectionDescription]

    /// The object that receives information when the message details changes.
    weak var observer: MessageDetailsDataSourceObserver?

    // MARK: - Initialization

    private var observationTokens: [Any] = []

    init(message: ZMConversationMessage) {
        self.message = message
        self.conversation = message.conversation!

        // Assign the initial data
        self.reactions = message.usersByReaction.map { reaction, users in
            MessageDetailsSectionDescription(
                headerText: "\(reaction.unicodeValue) \(reaction.displayValue) (\(users.count))",
                items: MessageDetailsCellDescription.makeReactionCells(users)
            )
        }.filter {
            !$0.items.isEmpty
        }

        self.readReceipts = [
            MessageDetailsSectionDescription(items: MessageDetailsCellDescription.makeReceiptCell(message.sortedReadReceipts))
        ].filter {
            !$0.items.isEmpty
        }

        // Compute the title and display mode
        let showLikesTab = message.canAddReaction
        let showReceiptsTab = message.areReadReceiptsDetailsAvailable
        supportsReadReceipts = message.needsReadConfirmation

        switch (showLikesTab, showReceiptsTab) {
        case (true, true):
            self.displayMode = .combined
            self.title = MessageDetails.combinedTitle.capitalized
        case (false, true):
            self.displayMode = .receipts
            self.title = MessageDetails.receiptsTitle.capitalized
        case (true, false):
            self.displayMode = .reactions
            self.title = MessageDetails.reactionsTitle.capitalized
        default:
            fatal("Trying to display a message that does not support reactions or receipts.")
        }

        super.init()

        updateSubtitle()
        setupObservers()
    }

    // MARK: - Interface Properties

    private func updateSubtitle() {
        guard let sentDate = message.formattedReceivedDate() else {
            return
        }

        let sentString = MessageDetails.subtitleSendDate(sentDate)

        var subtitle = sentString

        if let editedDate = message.formattedEditedDate() {
            let editedString = MessageDetails.subtitleEditDate(editedDate)
            subtitle += "\n" + editedString
        }

        self.subtitle = subtitle
        self.accessibilitySubtitle = message.formattedAccessibleMessageDetails()
        self.observer?.detailsFooterDidChange(self)
    }

    // MARK: - Changes

    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        // Detect changes in likes
        if changeInfo.reactionsChanged {
            performChanges {
                self.reactions = message.usersByReaction.map { reaction, users in
                    MessageDetailsSectionDescription(
                        headerText: reaction.unicodeValue,
                        items: MessageDetailsCellDescription.makeReactionCells(users)
                    )
                }.filter {
                    !$0.items.isEmpty
                }
            }
        }

        // Detect changes in read receipts
        if changeInfo.confirmationsChanged {
            performChanges {
                self.readReceipts = [
                    MessageDetailsSectionDescription(items: MessageDetailsCellDescription.makeReceiptCell(message.sortedReadReceipts))
                ].filter {
                    !$0.items.isEmpty
                }
            }
        }

        // Detect message edits
        if message.updatedAt != nil {
            updateSubtitle()
        }
    }

    func userDidChange(_ changeInfo: UserChangeInfo) {
        performChanges {
            self.reactions = message.usersByReaction.map { reaction, users in
                MessageDetailsSectionDescription(
                    headerText: "\(reaction.unicodeValue) \(reaction.displayValue) (\(users.count))",
                    items: MessageDetailsCellDescription.makeReactionCells(users)
                )
            }.filter {
                !$0.items.isEmpty
            }

            self.readReceipts = [
                MessageDetailsSectionDescription(items: MessageDetailsCellDescription.makeReceiptCell(message.sortedReadReceipts))
            ]
        }
    }

    private func setupObservers() {
        if let userSession = ZMUserSession.shared() {
            let messageObserver = MessageChangeInfo.add(observer: self, for: message, userSession: userSession)
            let userObserver = UserChangeInfo.add(userObserver: self, in: userSession)
            observationTokens = [messageObserver, userObserver]
        }
    }

    /// Commits changes to the data source and notifies the observer.
    private func performChanges(_ block: () -> Void) {
        block()
        observer?.dataSourceDidChange(self)
    }

}
