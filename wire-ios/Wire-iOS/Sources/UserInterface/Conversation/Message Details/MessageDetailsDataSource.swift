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

import Foundation
import WireDataModel
import WireSyncEngine

/// The way the details are displayed.
enum MessageDetailsDisplayMode: Int {
    case reactions
    case receipts
    case combined
}

struct MessageDetailsFooterViewModel {
    let subtitle: String?
    let accessibilitySubtitle: String?
}

/// Pure display state for the message details screen.
struct MessageDetailsViewModel {

    typealias MessageDetails = L10n.Localizable.MessageDetails

    let conversation: ZMConversation
    let displayMode: MessageDetailsDisplayMode
    let supportsReadReceipts: Bool
    let title: String
    let footer: MessageDetailsFooterViewModel
    let reactions: [MessageDetailsSectionDescription]
    let readReceipts: [MessageDetailsSectionDescription]

    init(
        message: ZMConversationMessage,
        emojiRepository: EmojiRepositoryInterface
    ) {
        self.conversation = message.conversation!

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

        self.footer = Self.makeFooter(for: message)
        self.reactions = Self.makeReactionSections(
            usersReaction: message.usersReaction,
            emojiRepository: emojiRepository
        )
        self.readReceipts = Self.makeReadReceiptSections(message.sortedReadReceipts)
    }

    func selectedTabIndex(preferredDisplayMode: MessageDetailsDisplayMode) -> Int? {
        guard displayMode == .combined else { return nil }
        return preferredDisplayMode == .reactions ? 1 : 0
    }

    private static func makeFooter(for message: ZMConversationMessage) -> MessageDetailsFooterViewModel {
        guard let sentDate = message.formattedReceivedDateTime() else {
            return MessageDetailsFooterViewModel(
                subtitle: nil,
                accessibilitySubtitle: message.formattedAccessibleMessageDetails()
            )
        }

        let sentString = MessageDetails.subtitleSendDate(sentDate)
        var subtitle = sentString

        if let editedDate = message.formattedEditedDate() {
            let editedString = MessageDetails.subtitleEditDate(editedDate)
            subtitle += "\n" + editedString
        }

        return MessageDetailsFooterViewModel(
            subtitle: subtitle,
            accessibilitySubtitle: message.formattedAccessibleMessageDetails()
        )
    }

    private static func makeReactionSections(
        usersReaction: [String: [UserType]],
        emojiRepository: EmojiRepositoryInterface
    ) -> [MessageDetailsSectionDescription] {
        usersReaction.lazy
            .compactMap { reaction, users in
                guard let emoji = emojiRepository.emoji(for: reaction) else { return nil }
                let name = emoji.localizedName ?? emoji.name
                return MessageDetailsSectionDescription(
                    headerText: "\(emoji.value) \(name.capitalized) (\(users.count))",
                    items: MessageDetailsCellDescription.makeReactionCells(users)
                )
            }
            .filter { !$0.items.isEmpty }
            .sorted { $0.items.count > $1.items.count }
    }

    private static func makeReadReceiptSections(_ readReceipts: [ReadReceipt]) -> [MessageDetailsSectionDescription] {
        [
            MessageDetailsSectionDescription(
                items: MessageDetailsCellDescription
                    .makeReceiptCell(readReceipts)
            )
        ].filter {
            !$0.items.isEmpty
        }
    }

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
    var conversation: ZMConversation {
        viewModel.conversation
    }

    /// How to display the message details.
    var displayMode: MessageDetailsDisplayMode {
        viewModel.displayMode
    }

    /// Whether read receipts are supported.
    var supportsReadReceipts: Bool {
        viewModel.supportsReadReceipts
    }

    /// The title of the message details.
    var title: String {
        viewModel.title
    }

    /// The subtitle of the message details.
    var subtitle: String? {
        viewModel.footer.subtitle
    }

    /// The subtitle of the message details for accessibility purposes.
    var accessibilitySubtitle: String? {
        viewModel.footer.accessibilitySubtitle
    }

    /// The list of reactions.
    var reactions: [MessageDetailsSectionDescription] {
        viewModel.reactions
    }

    /// The list of read receipts with the associated date.
    var readReceipts: [MessageDetailsSectionDescription] {
        viewModel.readReceipts
    }

    /// The full display state of the message details screen.
    private(set) var viewModel: MessageDetailsViewModel

    /// The object that receives information when the message details changes.
    weak var observer: MessageDetailsDataSourceObserver?

    private let emojiRepository: EmojiRepositoryInterface
    private let userSession: UserSession

    // MARK: - Initialization

    private var observationTokens: [Any] = []

    init(
        message: ZMConversationMessage,
        userSession: UserSession,
        emojiRepository: EmojiRepositoryInterface = EmojiRepository()
    ) {
        self.message = message
        self.userSession = userSession
        self.emojiRepository = emojiRepository
        self.viewModel = MessageDetailsViewModel(
            message: message,
            emojiRepository: emojiRepository
        )

        super.init()

        setupObservers()
    }

    // MARK: - Interface Properties

    private func updateSubtitle() {
        viewModel = MessageDetailsViewModel(
            message: message,
            emojiRepository: emojiRepository
        )
        observer?.detailsFooterDidChange(self)
    }

    // MARK: - Changes

    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        // Detect changes in reactions
        if changeInfo.reactionsChanged {
            performChanges {
                updateViewModel()
            }
        }

        // Detect changes in read receipts
        if changeInfo.confirmationsChanged {
            performChanges {
                updateViewModel()
            }
        }

        // Detect message edits
        if message.updatedAt != nil {
            updateSubtitle()
        }
    }

    func userDidChange(_ changeInfo: UserChangeInfo) {
        performChanges {
            updateViewModel()
        }
    }

    private func updateViewModel() {
        viewModel = MessageDetailsViewModel(
            message: message,
            emojiRepository: emojiRepository
        )
    }

    private func setupObservers() {
        if let userSession = userSession as? ZMUserSession {
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
