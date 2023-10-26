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
import WireSyncEngine

struct ConversationMessageContext: Equatable {
    var isSameSenderAsPrevious: Bool = false
    var isTimeIntervalSinceLastMessageSignificant: Bool = false
    var isTimestampInSameMinuteAsPreviousMessage: Bool = false
    var isFirstMessageOfTheDay: Bool = false
    var isFirstUnreadMessage: Bool = false
    var isLastMessage: Bool = false
    var searchQueries: [String] = []
    var previousMessageIsKnock: Bool = false
    var spacing: Float = 0
}

protocol ConversationMessageSectionControllerDelegate: AnyObject {
    func messageSectionController(_ controller: ConversationMessageSectionController, didRequestRefreshForMessage message: ZMConversationMessage)
}

extension ZMConversationMessage {
    var isComposite: Bool {
        return (self as? ConversationCompositeMessage)?.isComposite == true
    }
}

/**
 * An object that provides an interface to build list sections for a single message.
 *
 * A message will be represented as a table/collection section, and the components that make
 * the view of the message (timestamp, reply, content...) will be displayed as individual cells,
 * to reduce the number of cells that are instanciated at a given time.
 *
 * To achieve this, each section controller is assigned a cell description, that is responsible for dequeing
 * the cells from the table or collection view and configuring them with a message.
 */

final class ConversationMessageSectionController: NSObject, ZMMessageObserver {

    /// The view descriptor of the section.
    var cellDescriptions: [AnyConversationMessageCellDescription] = []

    /// The view descriptors in the order in which the tableview displays them.
    var tableViewCellDescriptions: [AnyConversationMessageCellDescription] {
        return useInvertedIndices ? cellDescriptions.reversed() : cellDescriptions
    }

    var context: ConversationMessageContext

    /// Whether we need to use inverted indices. This is `true` when the table view is upside down.
    var useInvertedIndices = false

    /// The object that controls actions for the cell.
    var actionController: ConversationMessageActionController? {
        didSet {
            updateDelegates()
        }
    }

    /// The message that is being presented.
    var message: ConversationMessage {
        didSet {
            updateDelegates()
        }
    }

    /// The delegate for cells injected by the list adapter.
    weak var cellDelegate: ConversationMessageCellDelegate? {
        didSet {
            updateDelegates()
        }
    }

    /// The index of the first cell that is displaying the message
    var messageCellIndex: Int = 0

    /// The object that receives informations from the section.
    weak var sectionDelegate: ConversationMessageSectionControllerDelegate?

    /// Whether this section is selected
    private var selected: Bool

    /// Whether this section is collapsed
    private var isCollapsed: Bool

    private var changeObservers: [Any] = []

    let userSession: UserSession

    deinit {
        changeObservers.removeAll()
    }

    init(message: ConversationMessage, context: ConversationMessageContext, selected: Bool = false, userSession: UserSession) {
        self.message = message
        self.context = context
        self.selected = selected
        self.isCollapsed = true
        self.userSession = userSession

        super.init()

        createCellDescriptions(in: context)

        startObservingChanges(for: message)

        if let quotedMessage = message.textMessageData?.quoteMessage {
            startObservingChanges(for: quotedMessage)
        }
    }

    // MARK: - Content Types

    private func addContent(context: ConversationMessageContext, isSenderVisible: Bool) {

        messageCellIndex = cellDescriptions.count

        let contentCellDescriptions: [AnyConversationMessageCellDescription]

        if message.isKnock {
            contentCellDescriptions = addPingMessageCells()
        } else if message.isComposite {
            contentCellDescriptions = addCompositeMessageCells
        } else if message.isText {
            contentCellDescriptions = ConversationTextMessageCellDescription.cells(for: message, searchQueries: context.searchQueries)
        } else if message.isImage {
            contentCellDescriptions = [AnyConversationMessageCellDescription(ConversationImageMessageCellDescription(message: message, image: message.imageMessageData!))]
        } else if message.isLocation {
            contentCellDescriptions = addLocationMessageCells()
        } else if message.isAudio {
            contentCellDescriptions = [AnyConversationMessageCellDescription(ConversationAudioMessageCellDescription(message: message))]
        } else if message.isVideo {
            contentCellDescriptions = [AnyConversationMessageCellDescription(ConversationVideoMessageCellDescription(message: message))]
        } else if message.isFile {
            contentCellDescriptions = [AnyConversationMessageCellDescription(ConversationFileMessageCellDescription(message: message))]
        } else if message.isSystem {
            contentCellDescriptions = ConversationSystemMessageCellDescription.cells(for: message,
                                                                                     isCollapsed: isCollapsed,
                                                                                     buttonAction: buttonAction)
        } else {
            contentCellDescriptions = [AnyConversationMessageCellDescription(UnknownMessageCellDescription())]
        }

        if let topContentCellDescription = contentCellDescriptions.first {
            topContentCellDescription.showEphemeralTimer = message.isEphemeral && !message.isObfuscated

            if isSenderVisible && topContentCellDescription.baseType == ConversationTextMessageCellDescription.self {
                topContentCellDescription.topMargin = 0 // We only do this for text content since the text label already contains the spacing
            }
        }

        cellDescriptions.append(contentsOf: contentCellDescriptions)
    }

    private func buttonAction() {
        self.isCollapsed = !self.isCollapsed
        self.cellDelegate?.conversationMessageShouldUpdate()
    }

    // MARK: - Content Cells

    private func addPingMessageCells() -> [AnyConversationMessageCellDescription] {
        guard let sender = message.senderUser else {
            return []
        }

        return [AnyConversationMessageCellDescription(ConversationPingCellDescription(message: message, sender: sender))]
    }

    private func addLocationMessageCells() -> [AnyConversationMessageCellDescription] {
        guard let locationMessageData = message.locationMessageData else {
            return []
        }

        let locationCell = ConversationLocationMessageCellDescription(message: message, location: locationMessageData)
        return [AnyConversationMessageCellDescription(locationCell)]
    }

    private var addCompositeMessageCells: [AnyConversationMessageCellDescription] {
        guard let compositeMessage = message as? ConversationCompositeMessage else { return [] }

        var cells: [AnyConversationMessageCellDescription] = []

        compositeMessage.compositeMessageData?.items.forEach { item in
            switch item {
            case .text(let data):
                let textCells = ConversationTextMessageCellDescription.cells(textMessageData: data, message: message, searchQueries: context.searchQueries)

                cells += textCells
            case .button(let data):

                let button = AnyConversationMessageCellDescription(ConversationButtonMessageCellDescription(text: data.title,
                                                                                                            state: data.state,
                                                                                                            hasError: data.isExpired,
                                                                                                            buttonAction: {
                    data.touchAction()
                }))
                cells.append(button)
            }
        }

        return cells
    }

    // MARK: - Composition

    /**
     * Adds a cell description to the section.
     * - parameter description: The cell to add to the message section.
     */

    func add<T: ConversationMessageCellDescription>(description: T) {
        cellDescriptions.append(AnyConversationMessageCellDescription(description))
    }

    func didSelect() {
        selected = true
    }

    func didDeselect() {
        selected = false
    }

    private func createCellDescriptions(in context: ConversationMessageContext) {
        cellDescriptions.removeAll()

        let isSenderVisible = self.shouldShowSenderDetails(in: context)

        if isBurstTimestampVisible(in: context) {
            add(description: BurstTimestampSenderMessageCellDescription(message: message, context: context, accentColor: userSession.selfUser.accentColor))
        }

        if isSenderVisible, let sender = message.senderUser, let timestamp = message.formattedReceivedDate() {
            add(description: ConversationSenderMessageCellDescription(sender: sender, message: message, timestamp: timestamp))
        }

        addContent(context: context, isSenderVisible: isSenderVisible)

        if isToolboxVisible(in: context) {
            add(description: ConversationMessageToolboxCellDescription(message: message))
        }

        if !message.isSystem, !message.isEphemeral, message.hasReactions() {
            add(description: MessageReactionsCellDescription(message: message))
        }

        if isFailedRecipientsVisible(in: context) {
            let cellDescription = ConversationMessageFailedRecipientsCellDescription(failedUsers: message.failedToSendUsers,
                                                                                     isCollapsed: isCollapsed,
                                                                                     buttonAction: { self.buttonAction() })
            add(description: cellDescription)
        }

        if let topCelldescription = cellDescriptions.first {
            topCelldescription.topMargin = context.spacing
        }
    }

    private func updateDelegates() {
        cellDescriptions.forEach({
            $0.message = message
            $0.actionController = actionController
            $0.delegate = cellDelegate
        })
    }

    public func recreateCellDescriptions(in context: ConversationMessageContext) {
        self.context = context
        createCellDescriptions(in: context)
        updateDelegates()
    }

    func isBurstTimestampVisible(in context: ConversationMessageContext) -> Bool {
        return context.isTimeIntervalSinceLastMessageSignificant ||  context.isFirstUnreadMessage || context.isFirstMessageOfTheDay
    }

    func isToolboxVisible(in context: ConversationMessageContext) -> Bool {
        guard !message.isSystem || message.isPerformedCall || message.isMissedCall else {
            return false
        }

        return message.deliveryState == .failedToSend || message.isSentBySelfUser
    }

    func shouldShowSenderDetails(in context: ConversationMessageContext) -> Bool {
        guard message.senderUser != nil else {
            return false
        }

        if message.isKnock || message.isSystem {
            return false
        }

        // A new sender, show the sender details.
        if !context.isSameSenderAsPrevious {
            return true
        }

        // Show sender details again if the last message was a knock.
        if context.previousMessageIsKnock {
            return true
        }

        // The message was edited.
        if message.updatedAt != nil {
            return true
        }

        // We see the self deleting countdown.
        if isBurstTimestampVisible(in: context) {
            return true
        }

        // This message is from the same sender but in a different minute.
        if context.isSameSenderAsPrevious && !context.isTimestampInSameMinuteAsPreviousMessage {
            return true
        }

        return false
    }

    func isFailedRecipientsVisible(in context: ConversationMessageContext) -> Bool {
        guard message.isNormal,
              !message.isKnock else {
            return false
        }

        return !message.failedToSendUsers.isEmpty
    }

    // MARK: - Highlight

    @objc func highlight(in tableView: UITableView, sectionIndex: Int) {
        let cellDescriptions = tableViewCellDescriptions

        let highlightableCells: [HighlightableView] = cellDescriptions.indices.compactMap {
            guard cellDescriptions[$0].containsHighlightableContent else {
                return nil
            }

            let index = IndexPath(row: $0, section: sectionIndex)
            return tableView.cellForRow(at: index) as? HighlightableView
        }

        let highlight = {
            for container in highlightableCells {
                container.highlightContainer.backgroundColor = UIColor.accentDimmedFlat
            }
        }

        let unhighlight = {
            for container in highlightableCells {
                container.highlightContainer.backgroundColor = .clear
            }
        }

        let animationOptions: UIView.AnimationOptions = [.curveEaseIn, .allowUserInteraction]

        UIView.animate(withDuration: 0.2, delay: 0, options: animationOptions, animations: highlight) { _ in
            UIView.animate(withDuration: 1, delay: 0.55, options: animationOptions, animations: unhighlight)
        }
    }

    // MARK: - Changes

    private func startObservingChanges(for message: ZMConversationMessage) {
        if let userSession = ZMUserSession.shared() {
            let observer = MessageChangeInfo.add(observer: self, for: message, userSession: userSession)
            changeObservers.append(observer)

            if let sender = message.senderUser {
                let observer = UserChangeInfo.add(observer: self, for: sender, in: userSession)!
                changeObservers.append(observer)
            }

            if let users = message.systemMessageData?.users {
                for user in users where user.remoteIdentifier != (message.senderUser as? ZMUser)?.remoteIdentifier {
                    if let observer = UserChangeInfo.add(observer: self, for: user, in: userSession) {
                        changeObservers.append(observer)
                    } else {
                        assertionFailure("Failed to add observer for user \(user)")
                    }
                }
            }
        }
    }

    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        guard !changeInfo.message.hasBeenDeleted else {
            return // Deletions are handled by the window observer
        }

        sectionDelegate?.messageSectionController(self, didRequestRefreshForMessage: self.message)
    }
}

extension ConversationMessageSectionController: ZMUserObserver {
    func userDidChange(_ changeInfo: UserChangeInfo) {
        sectionDelegate?.messageSectionController(self, didRequestRefreshForMessage: self.message)
    }
}
