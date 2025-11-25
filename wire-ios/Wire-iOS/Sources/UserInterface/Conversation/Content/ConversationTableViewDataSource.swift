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

import DifferenceKit
import WireDataModel
import WireFoundation
import WireLogging
import WireMessagingUI
import WireSyncEngine

extension Int: Differentiable {}
extension String: Differentiable {}
extension UUID: Differentiable {}

extension AnyConversationMessageCellDescription: Differentiable {

    typealias DifferenceIdentifier = String

    var differenceIdentifier: String {
        String(describing: (message as! ZMMessage).objectID) + String(describing: baseType)
    }

    override var debugDescription: String {
        differenceIdentifier
    }

    func isContentEqual(to source: AnyConversationMessageCellDescription) -> Bool {
        isConfigurationEqual(with: source)
    }

}

final class ConversationTableViewDataSource: NSObject {

    static let defaultBatchSize = 30 // Magic number: amount of messages per screen (upper bound).

    private lazy var backgroundContext = userSession.contextProvider.newBackgroundContext()
    private var fetchController: NSFetchedResultsController<ZMMessage>?
    private var lastFetchedObjectCount: Int = 0

    var registeredCells: [AnyClass] = []

    var sectionControllers = ThreadSafeDictionary<UUID, ConversationMessageSectionController>()

    private(set) var hasOlderMessagesToLoad = false
    private(set) var hasNewerMessagesToLoad = false

    let userSession: UserSession

    var actionControllers = ThreadSafeDictionary<UUID, ConversationMessageActionController>()

    let conversation: ZMConversation
    let tableView: UpsideDownTableView

    var firstUnreadMessage: ZMConversationMessage?
    var selectedMessage: ZMConversationMessage?
    var editingMessage: ZMConversationMessage?

    weak var conversationCellDelegate: ConversationMessageCellDelegate?
    weak var messageActionResponder: MessageActionResponder?
    private let getUserByIDUseCase: GetUserByIDUseCaseProtocol

    let debouncer = LeadingTrailingDebouncer(cooldownTime: 0.3)

    var contentWidth: CGFloat = UIScreen.main.bounds.width {
        didSet {
            guard UIDevice.current.userInterfaceIdiom == .pad else { return }
            resetSectionControllers()
        }
    }

    var searchQueries: [String] = [] {
        didSet {
            calculateSections { [weak self] sections in
                self?.reloadSections(newSections: sections)
            }
        }
    }

    var allMessages: [ZMMessage] {
        // NOTE: We limit the number of messages to the `lastFetchedObjectCount` since the
        // NSFetchResultsController will add objects to `fetchObjects` if they are modified after
        // the initial fetch, which results in unwanted table view updates. This is normally what
        // we want when new message arrive but not when fetchOffset > 0.

        if let fetchOffset = fetchController?.fetchRequest.fetchOffset, fetchOffset > 0 {
            Array(fetchController?.fetchedObjects?.suffix(lastFetchedObjectCount) ?? [])
        } else {
            fetchController?.fetchedObjects ?? []
        }
    }

    private(set) var currentSections: [Section] = []

    private let isChatBubbleSimpleEnabled: Bool

    private let wireMessagingFactory: any WireMessagingFactoryProtocol

    private let cellProvider: ConversationCellProviderProtocol

    /// calculate cell sections
    ///
    /// - Parameter forceRecalculate: true if force recreate cell with context check
    /// - Returns: arraySection of cell descriptions
    func calculateSections(
        forceRecalculate: Bool = false,
        completion: @escaping ([Section]) -> Void
    ) {
        let mainThreadContext = userSession.contextProvider.viewContext
        let messagesOnMainThread = allMessages
        let messageIds = messagesOnMainThread.map(\.objectID)
        let selfUserOnMainThread = userSession.selfUser
        let selfUserObjectID = selfUserOnMainThread.objectId
        let firstUnreadMessageNonce = firstUnreadMessage?.nonce

        // Dispatching to background thread to offload sections calculation

        backgroundContext = userSession.contextProvider.newBackgroundContext()
        backgroundContext.perform { [weak self, backgroundContext] in
            guard let self else { return }

            var messages: [ZMMessage] = messageIds.compactMap { objectID in
                try? backgroundContext.existingObject(with: objectID) as? ZMMessage
            }

            // sort if needed
            messages = messages.sorted {
                ($0.serverTimestamp ?? .distantPast) > ($1.serverTimestamp ?? .distantPast)
            }

            guard let selfUserOnBackgroundThread = getUserByIDUseCase.getUserByID(
                id: selfUserObjectID,
                context: backgroundContext
            ) else {
                DispatchQueue.main.async {
                    completion(self.currentSections)
                }
                return
            }

            // Go through messages and calculate sections
            let result = messages.enumerated().map { offset, element in
                let context = self.context(
                    for: element,
                    at: offset,
                    firstUnreadMessageNonce: firstUnreadMessageNonce,
                    searchQueries: self.searchQueries,
                    messages: messages
                )

                let sectionController = if let nonce = element.nonce,
                                           let cachedSectionController = self.sectionControllers.get(for: nonce) {
                    cachedSectionController
                } else {
                    self.makeSectionController(
                        message: element,
                        index: offset,
                        messages: messages,
                        selfUser: selfUserOnBackgroundThread,
                        firstUnreadMessageNonce: firstUnreadMessageNonce
                    )
                }

                // Re-create cell description if the context has changed (message has been moved around
                // or received new neighbours).
                return (element.nonce!, sectionController, context)
            }

            // Return back to main thread
            DispatchQueue.main.async {
                var sections = [Section]()

                for (messageObjectId, sectionController, context) in result {

                    // saving calculations result in local cache
                    self.sectionControllers.set(value: sectionController, for: messageObjectId)
                    self.actionControllers.set(value: sectionController.actionController, for: messageObjectId)

                    // Re-set messages from Main thread to section controller to not have crash with later interactions
                    // with data

                    // Fix for tapping composite message buttons [WPB-19793]:
                    // This workaround forces replacing `message` instance in `CompositeMessageItem` with an instance
                    // originating from the main context.
                    var recreateCellDescriptions = false

                    if let managedID = (sectionController.message as? ZMMessage)?.objectID,
                       let mainThreadMessage = try? mainThreadContext.existingObject(with: managedID) as? ZMMessage {
                        sectionController.updateMessage(mainThreadMessage)
                        recreateCellDescriptions = mainThreadMessage.isComposite
                    } else {
                        WireLogger.conversation
                            .debug(
                                "No message found to reset from background to main thread, nonce: \(String(describing: sectionController.message.nonce))"
                            )
                    }

                    sectionController.selfUser = selfUserOnMainThread

                    if sectionController.context != context || forceRecalculate || recreateCellDescriptions {
                        sectionController.recreateCellDescriptions(in: context)
                    }

                    sections.append(ArraySection(
                        model: messageObjectId,
                        elements: sectionController.tableViewCellDescriptions
                    ))
                }

                completion(
                    self.postProcessedSections(
                        sections,
                        selfUser: selfUserOnMainThread,
                        allMessages: messagesOnMainThread
                    )
                )
            }
        }

    }

    func calculateSections(
        updating sectionController: ConversationMessageSectionController
    ) -> [Section] {
        guard let sectionIdentifier = sectionController.message.nonce,
              let section = currentSections.firstIndex(where: { $0.model == sectionIdentifier })
        else { return currentSections }

        let messages = allMessages

        let context = context(
            for: sectionController.message,
            at: section,
            firstUnreadMessageNonce: firstUnreadMessage?.nonce,
            searchQueries: searchQueries,
            messages: messages
        )

        sectionController.recreateCellDescriptions(in: context)

        for (row, description) in sectionController.tableViewCellDescriptions.enumerated() {
            // workaround: this loop might add a status view to a message, which is removed again later, so skip
            if description.instance is ConversationMessageToolboxCellDescription {
                continue
            }
            if let cell = tableView.cellForRow(at: IndexPath(row: row, section: section)) {
                cell.accessibilityCustomActions = sectionController.actionController?.makeAccessibilityActions()
                description.configureCell(cell, animated: true)
            }
        }

        var updatedSections = currentSections
        updatedSections[section] = ArraySection(
            model: sectionIdentifier,
            elements: sectionController.tableViewCellDescriptions
        )
        updatedSections = postProcessedSections(
            updatedSections,
            selfUser: userSession.selfUser,
            allMessages: messages
        )

        return updatedSections
    }

    init(
        conversation: ZMConversation,
        tableView: UpsideDownTableView,
        actionResponder: MessageActionResponder,
        cellDelegate: ConversationMessageCellDelegate,
        userSession: UserSession,
        getUserByIDUseCase: GetUserByIDUseCaseProtocol,
        wireMessagingFactory: any WireMessagingFactoryProtocol,
        conversationCellProvider: any ConversationCellProviderProtocol
    ) {
        self.messageActionResponder = actionResponder
        self.conversationCellDelegate = cellDelegate
        self.conversation = conversation
        self.tableView = tableView
        self.userSession = userSession
        self.getUserByIDUseCase = getUserByIDUseCase
        self.isChatBubbleSimpleEnabled = userSession.isChatBubbleSimpleEnabled
        self.wireMessagingFactory = wireMessagingFactory
        self.cellProvider = conversationCellProvider

        super.init()

        tableView.dataSource = self
    }

    func resetSectionControllers() {
        debouncer.call(id: nil) { [weak self] in
            self?.sectionControllers.reset()
            self?.calculateSections { [weak self] sections in
                guard let self else { return }
                currentSections = sections
                tableView.reloadData()
            }
        }
    }

    func section(for message: ZMConversationMessage) -> Int? {
        currentSections.firstIndex(where: { $0.model == message.nonce })
    }

    func getOrCreateActionController(
        for message: ZMMessage,
        sectionController: ConversationMessageSectionController,
        selfUser: any UserType
    ) -> ConversationMessageActionController {
        if let nonce = message.nonce,
           let cachedEntry = actionControllers.get(for: nonce) {
            return cachedEntry
        }

        return makeActionController(
            for: message,
            sectionController: sectionController,
            selfUser: selfUser
        )
    }

    func makeActionController(
        for message: ZMConversationMessage,
        sectionController: ConversationMessageSectionController,
        selfUser: any UserType
    ) -> ConversationMessageActionController {
        ConversationMessageActionController(
            responder: messageActionResponder,
            message: message,
            context: .content,
            view: tableView,
            isCollapsed: sectionController.isCollapsed,
            selfUserId: selfUser.remoteIdentifier
        )
    }

    private func makeSectionController(
        message: ZMMessage,
        index: Int,
        messages: [ZMMessage],
        selfUser: any UserType,
        firstUnreadMessageNonce: UUID?
    ) -> ConversationMessageSectionController {
        let context = context(
            for: message,
            at: index,
            firstUnreadMessageNonce: firstUnreadMessageNonce,
            searchQueries: searchQueries,
            messages: messages
        )
        let sectionController = ConversationMessageSectionController(
            message: message,
            context: context,
            selfUser: selfUser,
            selected: message.isEqual(selectedMessage),
            userSession: userSession,
            useInvertedIndices: true,
            contentWidth: contentWidth,
            isChatBubbleSimpleEnabled: isChatBubbleSimpleEnabled
        )
        sectionController.cellDelegate = conversationCellDelegate
        sectionController.sectionDelegate = self
        sectionController.actionController = getOrCreateActionController(
            for: message,
            sectionController: sectionController,
            selfUser: selfUser
        )

        return sectionController
    }

    func getOrCreateSectionController(
        for message: ZMMessage,
        at index: Int,
        selfUser: any UserType,
        messages: [ZMMessage]
    ) -> ConversationMessageSectionController {
        if let nonce = message.nonce,
           let cachedEntry = sectionControllers.get(for: nonce) {
            cachedEntry.contentWidth = contentWidth
            return cachedEntry
        }

        let sectionController = makeSectionController(
            message: message,
            index: index,
            messages: messages,
            selfUser: selfUser,
            firstUnreadMessageNonce: firstUnreadMessage?.nonce
        )

        if let nonce = message.nonce {
            sectionControllers.set(value: sectionController, for: nonce)
        }

        return sectionController
    }

    func sectionController(
        at sectionIndex: Int,
        selfUser: any UserType,
        messages: [ZMMessage]
    ) -> ConversationMessageSectionController {
        let message = messages[sectionIndex]
        return getOrCreateSectionController(
            for: message,
            at: sectionIndex,
            selfUser: selfUser,
            messages: messages
        )
    }

    func loadMessages(
        near message: ZMConversationMessage,
        forceRecalculate: Bool = false,
        completion: ((IndexPath?) -> Void)? = nil
    ) {
        guard let moc = conversation.managedObjectContext, let serverTimestamp = message.serverTimestamp else {
            if message.hasBeenDeleted {
                completion?(nil)
                return
            } else {
                fatal("conversation.managedObjectContext == nil or serverTimestamp == nil")
            }
        }

        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        let validMessage = conversation.visibleMessagesPredicate!

        let beforeGivenMessage = NSPredicate(format: "%K > %@", ZMMessageServerTimestampKey, serverTimestamp as NSDate)

        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [validMessage, beforeGivenMessage])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(ZMMessage.serverTimestamp), ascending: false)]

        // It's the number of messages that are newer than the `message`
        let index = try! moc.count(for: fetchRequest)

        let offset = max(0, index - ConversationTableViewDataSource.defaultBatchSize)
        let limit = ConversationTableViewDataSource.defaultBatchSize * 2

        loadMessages(offset: offset, limit: limit, forceRecalculate: forceRecalculate) { [weak self] in
            guard let self else { return }
            let indexPath = topIndexPath(for: message)
            completion?(indexPath)
        }
    }

    func loadMessages(
        offset: Int = 0,
        limit: Int = ConversationTableViewDataSource.defaultBatchSize,
        forceRecalculate: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        let fetchRequest = fetchRequest()
        fetchRequest
            .fetchLimit = limit +
            5 // We need to fetch a bit more than requested so that there is overlap between messages in different
        // fetches
        fetchRequest.fetchOffset = offset

        fetchController = NSFetchedResultsController<ZMMessage>(
            fetchRequest: fetchRequest,
            managedObjectContext: conversation
                .managedObjectContext!,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        fetchController?.delegate = self
        try! fetchController?.performFetch()

        lastFetchedObjectCount = fetchController?.fetchedObjects?.count ?? 0
        hasOlderMessagesToLoad = allMessages.count == fetchRequest.fetchLimit
        hasNewerMessagesToLoad = offset > 0
        firstUnreadMessage = conversation.firstUnreadMessage

        debouncer.call(id: nil) { [weak self] in
            self?.calculateSections(forceRecalculate: forceRecalculate) { [weak self] sections in
                self?.currentSections = sections
                self?.tableView.reloadData()
                completion?()
            }
        }
    }

    var loadingMessages = false

    private func loadOlderMessages() {
        guard !loadingMessages else {
            return
        }
        guard let currentOffset = fetchController?.fetchRequest.fetchOffset,
              let currentLimit = fetchController?.fetchRequest.fetchLimit else { return }

        let newLimit = currentLimit + ConversationTableViewDataSource.defaultBatchSize
        loadingMessages = true

        loadMessages(offset: currentOffset, limit: newLimit) { [weak self] in
            self?.loadingMessages = false
        }
    }

    func loadNewerMessages() {
        guard !loadingMessages else { return }

        guard let currentOffset = fetchController?.fetchRequest.fetchOffset,
              let currentLimit = fetchController?.fetchRequest.fetchLimit else { return }

        let newOffset = max(0, currentOffset - ConversationTableViewDataSource.defaultBatchSize)

        loadMessages(offset: newOffset, limit: currentLimit) { [weak self] in
            self?.loadingMessages = false
        }
    }

    func indexOfMessage(_ message: ZMConversationMessage) -> Int {
        guard let index = index(of: message) else {
            return NSNotFound
        }
        return index
    }

    func index(of message: ZMConversationMessage) -> Int? {
        if let indexPath = fetchController?.indexPath(forObject: message as! ZMMessage) {
            indexPath.row
        } else {
            nil
        }
    }

    func topIndexPath(for message: ZMConversationMessage) -> IndexPath? {
        guard let section = index(of: message) else {
            return nil
        }

        // The table view is upside down. The first visible cell of the message has the last index
        // in the message section.
        let numberOfMessageComponents = tableView.numberOfRows(inSection: section)

        return IndexPath(row: numberOfMessageComponents - 1, section: section)
    }

    func didScroll(tableView: UITableView) {
        let scrolledToTop = (tableView.contentOffset.y + tableView.bounds.height) - tableView.contentSize.height > 0

        if scrolledToTop, hasOlderMessagesToLoad {
            // NOTE: we dispatch async because `didScroll(tableView:)` can be called inside a `performBatchUpdate()`,
            // which would cause data source inconsistency if change the fetchLimit.
            DispatchQueue.main.async {
                self.loadOlderMessages()
            }
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let scrolledToBottom = scrollView.contentOffset.y < 0
        guard scrolledToBottom, hasNewerMessagesToLoad else { return }

        // We are at the bottom and should load new messages

        // To avoid loosing scroll position:
        // 1. Remember the newest message now
        let newestMessageBeforeReload = allMessages.first
        // 2. Load more messages
        loadNewerMessages()

        // 3. Get the index path of the message that should stay displayed
        if let newestMessageBeforeReload,
           let sectionIndex = index(of: newestMessageBeforeReload) {

            // 4. Get the frame of that message
            let indexPathRect = tableView.rect(forSection: sectionIndex)

            // 5. Update content offset so it stays visible. To reduce flickering compensate for empty space below the
            // message
            scrollView.contentOffset = CGPoint(x: 0, y: indexPathRect.minY - 16)
        }
    }

    private func fetchRequest() -> NSFetchRequest<ZMMessage> {
        let fetchRequest = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        fetchRequest.predicate = conversation.visibleMessagesPredicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(ZMMessage.serverTimestamp), ascending: false)]
        return fetchRequest
    }
}

extension ConversationTableViewDataSource: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // no-op
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for changeType: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        if let message = anObject as? ZMConversationMessage, changeType == .insert {
            /// VoiceOver will output the announcement string from the message
            message.postAnnouncementIfNeeded()
        }
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange sectionInfo: NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for changeType: NSFetchedResultsChangeType
    ) {
        // no-op
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        debouncer.call(id: nil) { [weak self] in
            self?.calculateSections { sections in
                self?.reloadSections(newSections: sections)
            }
        }
    }

    func reloadSections(newSections: [Section]) {
        let stagedChangeset = StagedChangeset(source: currentSections, target: newSections)
        tableView.reload(using: stagedChangeset, with: .fade) { currentSections = $0 }
    }

}

extension ConversationTableViewDataSource: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        currentSections.count
    }

    func select(indexPath: IndexPath) {
        let sectionController = sectionController(
            at: indexPath.section,
            selfUser: userSession.selfUser,
            messages: allMessages
        )
        sectionController.didSelect()
        reloadSections(newSections: calculateSections(updating: sectionController))
    }

    func deselect(indexPath: IndexPath) {
        let sectionController = sectionController(
            at: indexPath.section,
            selfUser: userSession.selfUser,
            messages: allMessages
        )
        sectionController.didDeselect()
        reloadSections(newSections: calculateSections(updating: sectionController))
    }

    func highlight(message: ZMConversationMessage) {
        guard let section = index(of: message) else {
            return
        }

        let sectionController = sectionController(
            at: section,
            selfUser: userSession.selfUser,
            messages: allMessages
        )
        sectionController.highlight(in: tableView, sectionIndex: section)
    }

    func collapse(message: ZMConversationMessage) {
        guard let nonce = message.nonce, let section = sectionControllers.get(for: nonce) else {
            return
        }
        section.collapse()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard currentSections.indices.contains(section) else { return 0 }

        return currentSections[section].elements.count
    }

    func registerCellIfNeeded(
        with description: AnyConversationMessageCellDescription,
        in tableView: UITableView
    ) {
        guard !registeredCells.contains(where: { obj in
            obj == description.baseType
        }) else {
            return
        }

        description.register(in: tableView)
        registeredCells.append(description.baseType)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard currentSections.indices.contains(indexPath.section) else {
            fatal("currentSections has \(currentSections.count) elements, but try to access #\(indexPath)")
        }

        let section = currentSections[indexPath.section]
        guard section.elements.indices.contains(indexPath.row) else {
            fatal("section.elements has \(section.elements.count) elements, but try to access #\(indexPath)")
        }

        let cellDescription = section.elements[indexPath.row]
        if let model = cellDescription.conversationCellModel {
            return cellProvider.provideCell(
                for: model,
                tableView: tableView,
                indexPath: indexPath,
                onLongPress: { [weak self] cell in
                    guard let actionController = cellDescription.actionController else { return }

                    let messageActionController = MessageActionsViewController.controller(
                        withActions: MessageAction.allCases,
                        actionController: actionController
                    )

                    self?.conversationCellDelegate?.conversationMessageCell(
                        cell,
                        present: messageActionController
                    )
                }
            )

        } else {

            registerCellIfNeeded(with: cellDescription, in: tableView)
            return cellDescription.makeCell(for: tableView, at: indexPath)

        }
    }
}

extension ConversationTableViewDataSource: ConversationMessageSectionControllerDelegate {

    func messageSectionController(
        _ controller: ConversationMessageSectionController,
        didRequestRefreshForMessage message: ZMConversationMessage
    ) {
        guard let nonce = message.nonce else { return }
        debouncer.call(id: nonce) { [weak self] in
            guard let self else { return }
            reloadSections(newSections: calculateSections(updating: controller))
        }
    }

}

extension ConversationTableViewDataSource {

    func messageBeforeMessage(at index: Int, messages: [ZMConversationMessage]) -> ZMConversationMessage? {
        let previousIndex = index + 1
        guard messages.indices.contains(previousIndex) else { return nil }
        return messages[previousIndex]
    }

    func isPreviousSenderSame(
        forMessage message: ZMConversationMessage?,
        at index: Int,
        messages: [ZMMessage]
    ) -> Bool {
        guard let message,
              Message.isNormal(message),
              !Message.isKnock(message) else { return false }

        guard let previousMessage = messageBeforeMessage(at: index, messages: messages),
              previousMessage.senderUser === message.senderUser,
              Message.isNormal(previousMessage) else { return false }

        return true
    }

    func context(
        for message: ZMConversationMessage,
        at index: Int,
        firstUnreadMessageNonce: UUID?,
        searchQueries: [String],
        messages: [ZMMessage]
    ) -> ConversationMessageContext {

        let isTimestampInSameMinuteAsPreviousMessage: Bool

        let previousMessage = messageBeforeMessage(at: index, messages: messages)

        if let currentMessage = message.serverTimestamp, let prevMessage = previousMessage?.serverTimestamp {
            isTimestampInSameMinuteAsPreviousMessage = currentMessage.isInSameMinute(asDate: prevMessage)
        } else {
            isTimestampInSameMinuteAsPreviousMessage = false
        }

        let isLastMessage = (index == 0) && !hasNewerMessagesToLoad
        return ConversationMessageContext(
            isSameSenderAsPrevious: isPreviousSenderSame(forMessage: message, at: index, messages: messages),
            isTimestampInSameMinuteAsPreviousMessage: isTimestampInSameMinuteAsPreviousMessage,
            isFirstMessageOfTheDay: isFirstMessageOfTheDay(for: message, at: index, messages: messages),
            isFirstUnreadMessage: message.nonce == firstUnreadMessageNonce,
            isLastMessage: isLastMessage,
            searchQueries: searchQueries,
            previousMessageIsKnock: previousMessage?.isKnock == true
        )
    }

    private func isFirstMessageOfTheDay(
        for message: ZMConversationMessage,
        at index: Int,
        messages: [ZMConversationMessage]
    ) -> Bool {
        guard let previous = messageBeforeMessage(at: index, messages: messages)?.serverTimestamp,
              let current = message.serverTimestamp else { return false }
        return !Calendar.current.isDate(current, inSameDayAs: previous)
    }

    typealias Section = ArraySection<UUID, AnyConversationMessageCellDescription>

    /// Iterates over the sections (messages) and compares two subsequent messages. Based on that some minor
    /// modifications are applied.
    ///
    /// - If a message doesn't show the sender (because it was sent just a moment after the previous one), the space
    /// between the messages is reduced.
    /// - If a message's status does not provide relevant info over a subsequent message's status, it is hidden.
    private func postProcessedSections(
        _ sections: [Section],
        selfUser: any UserType,
        allMessages: [ZMMessage]
    ) -> [Section] {

        var sections = sections

        let messages = allMessages

        // find subsequent messages and collapse space if needed
        for currentSectionIndex in sections.indices.reversed() {
            // The lowest index refers to the latest message.
            let previousSectionIndex = currentSectionIndex + 1

            // Calling `elements.last` because the indices are reversed.
            guard let currentSectionFirstElement = sections[currentSectionIndex].elements.last?.instance else {
                continue
            }

            guard
                sections.indices.contains(previousSectionIndex),
                var previousSectionLastElement = sections[previousSectionIndex].elements.first?.instance
            else {
                // no previous message, so reset the margins
                currentSectionFirstElement.topMargin = 8
                currentSectionFirstElement.bottomMargin = 8
                continue
            }

            // filter redundant status cells
            if isMessageStatus(
                of: previousSectionIndex,
                redundantTo: currentSectionIndex,
                in: sections,
                selfUser: selfUser,
                messages: messages
            ),
                messages.indices.contains(previousSectionIndex) {

                // collapse the status view's height
                let previousMessage = messages[previousSectionIndex]
                let newCellDescription = ConversationMessageToolboxCellDescription(
                    message: previousMessage,
                    isRedundant: true
                )
                newCellDescription.topMargin = 0
                newCellDescription.bottomMargin = 0

                // we notify the table view by creating a new cell description
                let previousStatus = statusCellDescription(for: previousSectionIndex, in: sections)
                newCellDescription.delegate = previousStatus?.cellDescription.delegate
                previousStatus?.replace(newCellDescription, &sections)

                // for collapsing the space we will refer to the cell description before the previous message's status
                if let newPreviousSectionLastElement = sections[previousSectionIndex].elements.first?.instance {
                    previousSectionLastElement = newPreviousSectionLastElement
                }
            }

            // collapse space between subsequent messages
            if isSpaceCollapsedBefore(currentSectionFirstElement: currentSectionFirstElement) {
                if !(previousSectionLastElement is ConversationMessageToolboxCellDescription) {
                    previousSectionLastElement.bottomMargin = 2
                }
                currentSectionFirstElement.topMargin = 2
            } else {
                previousSectionLastElement.bottomMargin = 8
                currentSectionFirstElement.topMargin = 8
            }

        }

        return sections

    }

    private func statusCellDescription(
        for sectionIndex: Int,
        in sections: [Section]
    ) -> (
        cellDescription: ConversationMessageToolboxCellDescription,
        replace: (_ cellDescription: ConversationMessageToolboxCellDescription, _ sections: inout [Section]) -> Void
    )? {

        for elementIndex in sections[sectionIndex].elements.indices {
            let cellDescription = sections[sectionIndex].elements[elementIndex].instance

            if let cellDescription = cellDescription as? ConversationMessageToolboxCellDescription {

                func replace(
                    by newCellDescription: ConversationMessageToolboxCellDescription,
                    in sections: inout [Section]
                ) {
                    sections[sectionIndex]
                        .elements[elementIndex] = AnyConversationMessageCellDescription(newCellDescription)
                }

                return (cellDescription, replace)
            }

        }

        return nil
    }

    private func isMessageStatus(
        of previousIndex: Int,
        redundantTo currentIndex: Int,
        in sections: [Section],
        selfUser: any UserType,
        messages: [ZMMessage]
    ) -> Bool {
        guard messages.indices.contains(previousIndex), messages.indices.contains(currentIndex) else {
            return false
        }

        let previousMessage = messages[previousIndex]
        let currentMessage = messages[currentIndex]

        // the message is from a different user
        if previousMessage.senderUser?.remoteIdentifier != currentMessage.senderUser?.remoteIdentifier {
            return false
        }

        // always show the countdown
        if previousMessage.isEphemeral == true {
            return false
        }

        // always show if the message was edited {
        if previousMessage.updatedAt != nil {
            return false
        }

        // if the current message is collapsed, show status for the previous
        if sectionController(at: currentIndex, selfUser: selfUser, messages: messages).isCollapsed {
            return false
        }

        // current message shows sender
        if sections[currentIndex].elements.last?.instance is ConversationSenderMessageCellDescription {
            return false
        }

        // time divider could be the first and sender the second
        if sections[currentIndex].elements.dropLast().last?.instance is ConversationSenderMessageCellDescription {
            return false
        }

        return previousMessage.deliveryState == currentMessage.deliveryState
    }

    private func isSpaceCollapsedBefore(
        currentSectionFirstElement cellDescription: any ConversationMessageCellDescription
    ) -> Bool {
        if cellDescription is ConversationTextMessageCellDescription ||
            cellDescription is ConversationFileMessageCellDescription ||
            cellDescription is ConversationImageMessageCellDescription ||
            cellDescription is ConversationVideoMessageCellDescription ||
            cellDescription is ConversationReplyCellDescription ||
            cellDescription is ConversationCollapsedMessageCellDescription {
            // no stack cell description and no sender is shown, so collapse the space if needed
            true
        } else {
            false
        }
    }

}

extension Date {

    func isInSameMinute(asDate date: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        let otherComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return components == otherComponents
    }

}

extension ZMConversationMessage {

    var text: String? {
        textMessageData?.messageText
    }
}

extension ZMConversationMessage {

    var isSentFromThisDevice: Bool {
        guard let sender = senderUser else { return false }
        return sender.isSelfUser && deliveryState == .pending
    }

}
