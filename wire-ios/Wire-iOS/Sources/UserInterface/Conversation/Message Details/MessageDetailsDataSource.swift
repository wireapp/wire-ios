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

import Foundation
import WireDataModel
import WireSyncEngine

/// The way the details are displayed.
enum MessageDetailsDisplayMode: Int {
    case reactions, receipts, combined
}

/// An object that observes changes in the message data source.

protocol MessageDetailsDataSourceObserver: AnyObject {
    /// Called when the message details change.
    func dataSourceDidChange(_ dataSource: MessageDetailsDataSource)

    /// Called when the message subtitle changes.
    func detailsFooterDidChange(_ dataSource: MessageDetailsDataSource)
}

/// The data source to present message details.

final class MessageDetailsDataSource: NSObject, ZMMessageObserver, UserObserving {
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

    /// The list of reactions.
    private(set) var reactions: [MessageDetailsSectionDescription] = []

    /// The list of read receipts with the associated date.
    private(set) var readReceipts: [MessageDetailsSectionDescription] = []

    /// The object that receives information when the message details changes.
    weak var observer: MessageDetailsDataSourceObserver?

    private let emojiRepository: EmojiRepositoryInterface

    // MARK: - Initialization

    private var observationTokens: [Any] = []

    init(
        message: ZMConversationMessage,
        emojiRepository: EmojiRepositoryInterface = EmojiRepository()
    ) {
        self.message = message
        self.emojiRepository = emojiRepository
        self.conversation = message.conversation!

        // Compute the title and display mode
        let showLikesTab = message.canAddReaction
        let showReceiptsTab = message.areReadReceiptsDetailsAvailable
        self.supportsReadReceipts = message.needsReadConfirmation

        switch (showLikesTab, showReceiptsTab) {
        case (true, true):
            self.displayMode = .combined
            self.title = MessageDetails.combinedTitle

        case (false, true):
            self.displayMode = .receipts
            self.title = MessageDetails.receiptsTitle

        case (true, false):
            self.displayMode = .reactions
            self.title = MessageDetails.reactionsTitle

        default:
            fatal("Trying to display a message that does not support reactions or receipts.")
        }

        super.init()

        // Assign the initial data
        setupReactions()
        setupReadReceipts()

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
        accessibilitySubtitle = message.formattedAccessibleMessageDetails()
        observer?.detailsFooterDidChange(self)
    }

    // MARK: - Changes

    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        // Detect changes in reactions
        if changeInfo.reactionsChanged {
            performChanges {
                setupReactions()
            }
        }

        // Detect changes in read receipts
        if changeInfo.confirmationsChanged {
            performChanges {
                setupReadReceipts()
            }
        }

        // Detect message edits
        if message.updatedAt != nil {
            updateSubtitle()
        }
    }

    func userDidChange(_: UserChangeInfo) {
        performChanges {
            setupReactions()
            setupReadReceipts()
        }
    }

    private func setupReactions() {
        reactions = message.usersReaction.lazy
            .compactMap { reaction, users in
                guard let emoji = self.emojiRepository.emoji(for: reaction) else { return nil }
                let name = emoji.localizedName ?? emoji.name
                return MessageDetailsSectionDescription(
                    headerText: "\(emoji.value) \(name.capitalized) (\(users.count))",
                    items: MessageDetailsCellDescription.makeReactionCells(users)
                )
            }
            .filter { !$0.items.isEmpty }
            .sorted { $0.items.count > $1.items.count }
    }

    func setupReadReceipts() {
        readReceipts = [
            MessageDetailsSectionDescription(
                items: MessageDetailsCellDescription
                    .makeReceiptCell(message.sortedReadReceipts)
            ),
        ].filter {
            !$0.items.isEmpty
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
