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

import Foundation
import WireFoundation
import WireSyncEngine

struct ConversationMessageContext: Equatable {
    var isSameSenderAsPrevious: Bool = false
    var isTimestampInSameMinuteAsPreviousMessage: Bool = false
    var isFirstMessageOfTheDay: Bool = false
    var isFirstUnreadMessage: Bool = false
    var isLastMessage: Bool = false
    var searchQueries: [String] = []
    var previousMessageIsKnock: Bool = false
}

protocol ConversationMessageSectionControllerDelegate: AnyObject {
    func messageSectionController(
        _ controller: ConversationMessageSectionController,
        didRequestRefreshForMessage message: ZMConversationMessage
    )
}

extension ZMConversationMessage {
    var isComposite: Bool {
        (self as? ConversationCompositeMessage)?.isComposite == true
    }
}

/// An object that provides an interface to build list sections for a single message.
///
/// A message will be represented as a table/collection section, and the components that make
/// the view of the message (timestamp, reply, content...) will be displayed as individual cells,
/// to reduce the number of cells that are instanciated at a given time.
///
/// To achieve this, each section controller is assigned a cell description, that is responsible for dequeing
/// the cells from the table or collection view and configuring them with a message.

final class ConversationMessageSectionController: NSObject, ZMMessageObserver {

    /// The view descriptor of the section.
    private var cellDescriptions = [AnyConversationMessageCellDescription]()

    #if DEBUG
        var cellDescriptionsForTesting: [AnyConversationMessageCellDescription] {
            get { cellDescriptions }
            set { cellDescriptions = newValue }
        }
    #endif

    /// The view descriptors in the order in which the tableview displays them.
    var tableViewCellDescriptions: [AnyConversationMessageCellDescription] {
        useInvertedIndices ? cellDescriptions.reversed() : cellDescriptions
    }

    private(set) var context: ConversationMessageContext

    /// Whether we need to use inverted indices. This is `true` when the table view is upside down.
    private let useInvertedIndices: Bool

    /// The object that controls actions for the cell.
    var actionController: ConversationMessageActionController?

    /// The message that is being presented.
    private(set) var message: ConversationMessage {
        didSet {
            changeObservers.removeAll()
            startObservingChanges(for: message)
        }
    }

    var selfUser: any UserType

    /// The delegate for cells injected by the list adapter.
    weak var cellDelegate: ConversationMessageCellDelegate?

    /// The object that receives informations from the section.
    weak var sectionDelegate: ConversationMessageSectionControllerDelegate?

    /// Whether this section is selected
    private var selected: Bool

    /// Whether this section is collapsed
    private(set) var isCollapsed: Bool = false {
        didSet {
            actionController?.isCollapsed = isCollapsed
        }
    }

    private var changeObservers: [Any] = []

    private let userSession: UserSession
    private let privateDefaults: PrivateUserDefaults<CollapseKey>

    /// width of a container view to calculate whether message should be collapsed
    var contentWidth: CGFloat

    deinit {
        changeObservers.removeAll()
    }

    init(
        message: ConversationMessage,
        context: ConversationMessageContext,
        selfUser: any UserType,
        selected: Bool = false,
        userSession: UserSession,
        useInvertedIndices: Bool,
        contentWidth: CGFloat,
        userDefaults: UserDefaultsProtocol = UserDefaults.standard
    ) {
        self.message = message
        self.context = context
        self.selfUser = selfUser
        self.selected = selected
        self.userSession = userSession
        self.useInvertedIndices = useInvertedIndices
        self.contentWidth = contentWidth
        self.privateDefaults = PrivateUserDefaults<CollapseKey>(
            userID: selfUser.remoteIdentifier,
            storage: userDefaults
        )

        super.init()

        self.isCollapsed = isCollapsedInitialValue()

        createCellDescriptions(in: context)

        startObservingChanges(for: message)

        if let quotedMessage = message.textMessageData?.quoteMessage {
            startObservingChanges(for: quotedMessage)
        }
    }
    
    private var collapseOwnMessagesEnabled: Bool {
        false
        // Temporarily disabling collapsing own messages,
        // because it conflicts with chat bubbles.
        // https://wearezeta.atlassian.net/browse/WPB-18939
        //
        // privateDefaults.bool(forKey: .collapseOwnMessages)
    }

    private func isCollapsedInitialValue() -> Bool {

        // cases when isCollapsed should be true by default
        if isMessageWithCollapsedByDefault() {
            return true
        }

        // then if in settings user allowed to collapse own messages
        guard collapseOwnMessagesEnabled, message.isSentBySelfUser else {
            return false
        }

        if privateDefaults.wasMessagedUncollapsedBefore(message) {
            return false
        }

        if message.isTextWithNoLinks {

            guard let textMessage = message.textMessageData?.messageText else {
                return false
            }

            return willTextExceedLines(
                text: textMessage,
                availableWidth: contentWidth,
                numberOfLines: 3
            )
        } else {
            return message.isSentBySelfUser && message.isCollapsingSupported
        }
    }

    // MARK: - Content Types

    private func addContent(
        context: ConversationMessageContext,
        isBurstTimestampVisible: Bool,
        isSenderVisible: Bool,
        to cellDescriptions: inout [AnyConversationMessageCellDescription]
    ) {
        let contentCellDescriptions: [AnyConversationMessageCellDescription] = if message.isKnock {
            addPingMessageCells()
        } else if message.isComposite {
            addCompositeMessageCells()
        } else if message.isText, message.isMultipart {
            addTextMessageCells() + addMultipartMessageCells()
        } else if message.isText {
            addTextMessageCells()
        } else if message.isMultipart {
            addMultipartMessageCells()
        } else if message.isImage {
            addImageMessageCell()
        } else if message.isLocation {
            addLocationMessageCells()
        } else if message.isAudio {
            addAudioMessageCell()
        } else if message.isVideo {
            addVideoMessageCell()
        } else if message.isFile {
            addFileMessageCell()
        } else if message.isSystem {
            addSystemMessageCell()
        } else {
            addUnknownMessageCell()
        }

        cellDescriptions.append(contentsOf: contentCellDescriptions)
    }

    private func buttonAction() {
        isCollapsed = !isCollapsed
        cellDelegate?.conversationMessageShouldUpdate()
    }

    private func handleCollapseExpand() {
        isCollapsed = !isCollapsed
        if isCollapsed {
            privateDefaults.removeWasUncollapsed(message)
        } else {
            privateDefaults.saveWasUncollapsed(message)
        }
        sectionDelegate?.messageSectionController(self, didRequestRefreshForMessage: message)
    }

    func collapse() {
        handleCollapseExpand()
    }

    // MARK: - Content Cells

    private func addMultipartMessageCells() -> [AnyConversationMessageCellDescription] {
        if shouldCollapseCell() {
            return addCollapsedCell()
        }

        let multipartMessageCellDescription = ConversationMultipartMessageCellDescription(
            multipartMessage: message.multipartMessageData!,
            isSentBySelfUser: message.isSentBySelfUser
        )
        return [AnyConversationMessageCellDescription(multipartMessageCellDescription)]
    }

    private func addPingMessageCells() -> [AnyConversationMessageCellDescription] {
        guard let sender = message.senderUser else { return [] }

        let pingCellDescription = ConversationPingCellDescription(message: message, sender: sender)
        return [AnyConversationMessageCellDescription(pingCellDescription)]
    }

    private func addImageMessageCell() -> [AnyConversationMessageCellDescription] {
        if shouldCollapseCell() {
            return addCollapsedCell()
        }
        guard let imageMessageData = message.imageMessageData else {
            return []
        }
        let conversationImageMessageCellDescription = ConversationImageMessageCellDescription(
            message: message,
            image: imageMessageData
        )
        return [AnyConversationMessageCellDescription(conversationImageMessageCellDescription)]
    }

    private func shouldCollapseCell() -> Bool {
        // There are system type of messages are collapsed by default
        guard !isMessageWithCollapsedByDefault() else {
            return false
        }
        // Collapse if it was set to be collapsed
        if isCollapsed {
            return true
        }
        // Then there are cases when we receive live update that fits criteria to be collapsed
        // for example if messages has links previews or attachments
        // when cell is refreshed, we recalculate
        if collapseOwnMessagesEnabled, message.isSentBySelfUser, message.hasLinks,
           !privateDefaults.wasMessagedUncollapsedBefore(message) {
            return true
        }

        return false
    }

    private func addCollapsedCell() -> [AnyConversationMessageCellDescription] {
        let cellDescriptions = ConversationCollapsedMessageCellDescription(
            message: message,
            accentColor: (selfUser.zmAccentColor ?? .default).accentColor,
            collapseExpandAction: { [weak self] in
                self?.handleCollapseExpand()
            }
        )
        return [AnyConversationMessageCellDescription(cellDescriptions)]
    }

    private func addTextMessageCells() -> [AnyConversationMessageCellDescription] {
        if shouldCollapseCell() {
            return addCollapsedCell()
        }

        return ConversationTextMessageCellDescription
            .cells(
                for: message,
                searchQueries: context.searchQueries,
                selfUser: selfUser,
                userSession: userSession
            )
    }

    private func addLocationMessageCells() -> [AnyConversationMessageCellDescription] {
        if shouldCollapseCell() {
            return addCollapsedCell()
        }

        guard let locationMessageData = message.locationMessageData else { return [] }

        let locationCell = ConversationLocationMessageCellDescription(message: message, location: locationMessageData)
        return [AnyConversationMessageCellDescription(locationCell)]
    }

    private func addAudioMessageCell() -> [AnyConversationMessageCellDescription] {
        if shouldCollapseCell() {
            return addCollapsedCell()
        }
        let cellDescription = ConversationAudioMessageCellDescription(message: message)
        return [AnyConversationMessageCellDescription(cellDescription)]
    }

    private func addVideoMessageCell() -> [AnyConversationMessageCellDescription] {
        if shouldCollapseCell() {
            return addCollapsedCell()
        }
        let cellDescription = ConversationVideoMessageCellDescription(message: message)
        return [AnyConversationMessageCellDescription(cellDescription)]
    }

    private func addFileMessageCell() -> [AnyConversationMessageCellDescription] {
        guard !shouldCollapseCell() else {
            return addCollapsedCell()
        }

        let cellDescriptions = ConversationFileMessageCellDescription(message: message)
        return [AnyConversationMessageCellDescription(cellDescriptions)]
    }

    private func addSystemMessageCell() -> [AnyConversationMessageCellDescription] {
        ConversationSystemMessageCellDescription.cells(
            for: message,
            isCollapsed: isCollapsed,
            buttonAction: buttonAction,
            selfUser: selfUser,
            accentColor: (selfUser.zmAccentColor ?? .default).accentColor.uiColor,
            userSession: userSession
        )
    }

    private func addUnknownMessageCell() -> [AnyConversationMessageCellDescription] {
        let cellDescription = UnknownStoredMessageCellDescription()
        return [AnyConversationMessageCellDescription(cellDescription)]
    }

    private func addCompositeMessageCells() -> [AnyConversationMessageCellDescription] {
        guard let compositeMessage = message as? ConversationCompositeMessage else { return [] }

        var cells: [AnyConversationMessageCellDescription] = []

        compositeMessage.compositeMessageData?.items.forEach { item in
            switch item {

            case let .text(data):
                cells += ConversationTextMessageCellDescription.cells(
                    textMessageData: data,
                    message: message,
                    searchQueries: context.searchQueries,
                    selfUser: selfUser,
                    userSession: userSession
                )

            case let .button(data):
                let button = ConversationButtonMessageCellDescription(
                    text: data.title,
                    state: data.state,
                    hasError: data.isExpired,
                    userSession: userSession,
                    buttonAction: {
                        data.touchAction()
                    }
                )
                cells.append(AnyConversationMessageCellDescription(button))
            }
        }

        return cells
    }

    // MARK: - Composition

    #if DEBUG
        /// Adds a cell description to the section.
        /// - parameter description: The cell to add to the message section.

        func addForTesting(description: some ConversationMessageCellDescription) {
            cellDescriptions.append(AnyConversationMessageCellDescription(description))
        }
    #endif

    func didSelect() {
        selected = true
    }

    func didDeselect() {
        selected = false
    }

    private func createCellDescriptions(in context: ConversationMessageContext) {
        var cellDescriptions = [AnyConversationMessageCellDescription]()

        let isBurstTimestampVisible = isBurstTimestampVisible(in: context)
        let isSenderVisible = shouldShowSenderDetails(in: context)

        if let conversation = message.conversationLike,
           conversation.isChannel == true,
           conversation.channelHistoryDepth != nil {
            let description = ConversationChannelHistoryAvailableCellDescription(
                hasMoreHistory: conversation.hasMoreHistory
            )
            cellDescriptions.append(AnyConversationMessageCellDescription(description))
        }

        if isBurstTimestampVisible {
            let description = BurstTimestampSenderMessageCellDescription(
                message: message,
                context: context,
                accentColor: selfUser.accentColor
            )
            cellDescriptions.append(AnyConversationMessageCellDescription(description))
        }

        if isSenderVisible, let sender = message.senderUser {
            let description = ConversationSenderMessageCellDescription(
                sender: sender,
                selfUser: selfUser,
                message: message
            )
            cellDescriptions.append(AnyConversationMessageCellDescription(description))
        }

        addContent(
            context: context,
            isBurstTimestampVisible: isBurstTimestampVisible,
            isSenderVisible: isSenderVisible,
            to: &cellDescriptions
        )

        func addToolbox() {
            if isToolboxVisible(in: context) {
                let description = ConversationMessageToolboxCellDescription(message: message, isRedundant: false)
                cellDescriptions.append(AnyConversationMessageCellDescription(description))
            }
        }

        func addReactions() {
            if !message.isSystem, !message.isEphemeral, message.hasReactions() {
                let description = MessageReactionsCellDescription(message: message)
                cellDescriptions.append(AnyConversationMessageCellDescription(description))
            }
        }

        addReactions()
        addToolbox()

        if isFailedRecipientsVisible(in: context) {
            let description = ConversationMessageFailedRecipientsCellDescription(
                failedUsers: message.failedToSendUsers,
                isCollapsed: isCollapsed,
                buttonAction: { self.buttonAction() }
            )
            cellDescriptions.append(AnyConversationMessageCellDescription(description))
        }

        self.cellDescriptions = cellDescriptions
    }

    func updateMessage(_ message: ConversationMessage) {
        self.message = message
        actionController?.message = message
        cellDescriptions.forEach { cellDescription in
            cellDescription.message = message
            cellDescription.actionController = actionController
            cellDescription.delegate = cellDelegate
        }
    }

    func recreateCellDescriptions(in context: ConversationMessageContext) {
        self.context = context
        createCellDescriptions(in: context)
        updateMessage(message)
    }

    func isBurstTimestampVisible(in context: ConversationMessageContext) -> Bool {
        context.isFirstUnreadMessage || context.isFirstMessageOfTheDay
    }

    func isToolboxVisible(in context: ConversationMessageContext) -> Bool {
        guard !message.isSystem || message.isMissedCall else {
            return false
        }

        // for all messages that support collapsing and is collapsed
        if shouldCollapseCell() {
            // if message failed, always show footer with error message and retry button
            if message.deliveryState == .failedToSend {
                return true
            }
            // then do not show footer if sent but show when sending
            return !message.isSent
        }

        return true
    }

    private func isMessageWithCollapsedByDefault() -> Bool {
        message.isSystem || !message.failedToSendUsers.isEmpty
    }

    func shouldShowSenderDetails(in context: ConversationMessageContext) -> Bool {
        guard message.senderUser != nil else {
            return false
        }

        if shouldCollapseCell() {
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

        // A time divider / unread indicator is shown before the actual message.
        if isBurstTimestampVisible(in: context) {
            return true
        }

        // This message is from the same sender but in a different minute.
        if !context.isTimestampInSameMinuteAsPreviousMessage {
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

    @objc
    func highlight(in tableView: UITableView, sectionIndex: Int) {
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
        guard let userSession = userSession as? ZMUserSession else { return }

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

    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        guard !changeInfo.message.hasBeenDeleted else {
            return // Deletions are handled by the window observer
        }

        sectionDelegate?.messageSectionController(self, didRequestRefreshForMessage: message)
    }
}

extension ConversationMessageSectionController: UserObserving {
    func userDidChange(_ changeInfo: UserChangeInfo) {
        sectionDelegate?.messageSectionController(self, didRequestRefreshForMessage: message)
    }
}

extension ConversationMessageSectionController {

    // TODO: [WPB-16627] https://wearezeta.atlassian.net/browse/WPB-16627
    // improve by having one place to calculate width and for actual view to present text
    func willTextExceedLines(text: String, availableWidth: CGFloat, numberOfLines: Int) -> Bool {
        let textSize = CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)

        let font = UIFont.normalLightFont
        let attributes: [NSAttributedString.Key: Any] = [.font: font]

        let boundingBox = text.boundingRect(
            with: textSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )

        let singleLineHeight = NSAttributedString.paragraphStyle.minimumLineHeight
        let maxHeight = singleLineHeight * CGFloat(numberOfLines)

        return boundingBox.height > maxHeight
    }
}
