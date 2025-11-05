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
import WireCommonComponents
import WireDataModel
import WireDesign
import WireFoundation
import WireLogging
import WireMainNavigationUI
import WireMessagingUI
import WireRequestStrategy
import WireReusableUIComponents
import WireSyncEngine

private let zmLog = ZMSLog(tag: "ConversationContentViewController")

/// The main conversation view controller
final class ConversationContentViewController: UIViewController {

    weak var delegate: ConversationContentViewControllerDelegate?
    let conversation: ZMConversation
    var bottomMargin: CGFloat = 0 {
        didSet {
            setTableViewBottomMargin(bottomMargin)
        }
    }

    let scrollToBottomButtonTrailingMargin: CGFloat = 10
    let scrollToBottomButtonBottomMargin: CGFloat = 10
    let scrollToBottomButtonWidth: CGFloat = 44
    let scrollToBottomButtonHeight: CGFloat = 44

    /// A button that, when tapped, scrolls the conversation view to the latest messages.
    /// It appears when the user has scrolled up past a certain point in the conversation.
    lazy var scrollToBottomButton = {
        let button = ZMButton(style: .scrollToBottomButtonStyle, cornerRadius: scrollToBottomButtonHeight / 2)
        let icon = UIImage(resource: .downArrow)

        button.setImage(icon, for: .normal)
        button.setImage(icon, for: .highlighted)

        button.tintColor = SemanticColors.Icon.foregroundDefaultWhite

        button.translatesAutoresizingMaskIntoConstraints = false

        button.accessibilityLabel = L10n.Accessibility.Conversation.ScrollToBottomButton.description
        button.accessibilityHint = L10n.Accessibility.Conversation.ScrollToBottomButton.hint

        let action = UIAction { [weak self] _ in
            self?.handleScrollToBottomTapped()
        }

        button.addAction(action, for: .touchUpInside)

        button.imageView?.contentMode = .center

        return button
    }()

    private let userDefaults: PrivateUserDefaults<ConversationBackgroundKey>

    let tableView: UpsideDownTableView = .init(frame: .zero, style: .plain)
    let bottomContainer: UIView = .init(frame: .zero)
    var searchQueries: [String]? {
        didSet {
            guard let searchQueries,
                  !searchQueries.isEmpty else { return }

            dataSource.searchQueries = searchQueries
        }
    }

    let mentionsSearchResultsViewController: UserSearchResultsViewController = .init()

    lazy var dataSource = ConversationTableViewDataSource(
        conversation: conversation,
        tableView: tableView,
        actionResponder: self,
        cellDelegate: self,
        userSession: userSession,
        getUserByIDUseCase: GetUserByIdUseCase(),
        wireMessagingFactory: wireMessagingFactory,
        conversationCellProvider: wireMessagingFactory.makeConversationCellProvider(
            insetsProvider: {
                let margins = HorizontalMargins.conversationHorizontalMargins()
                return ConversationCellInsets(
                    legacy: .init(leading: margins.left, trailing: margins.right),
                    leadingBubble: .init(leading: margins.left, trailing: margins.chatBubbleMinimumTrailing),
                    trailingBubble: .init(leading: margins.chatBubbleMinimumLeading, trailing: margins.right)
                )
            }
        )
    )

    /// Fired regularly in order to always correct time values (like the number of seconds a self-deleting message has
    /// left).
    private var refreshTimer: Timer?

    let messagePresenter: MessagePresenter
    var deletionDialogPresenter: DeletionDialogPresenter?
    let userSession: UserSession
    let mainCoordinator: AnyMainCoordinator
    let selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol
    var connectionViewController: UserConnectionViewController?
    var digitalSignatureToken: Any?
    var userClientToken: Any?
    var isDigitalSignatureVerificationShown: Bool = false

    private var mediaPlaybackManager: MediaPlaybackManager?
    private var cachedRowHeights: [IndexPath: CGFloat] = [:]
    private var hasDoneInitialLayout = false
    private var onScreen = false
    private weak var messageVisibleOnLoad: ZMConversationMessage?
    private var token: NSObjectProtocol?

    private(set) lazy var activityIndicator = BlockingActivityIndicator(view: view)
    let linkDetector = NSDataDetector.linkDetector

    private let logger: WireLogger
    private var accentColorChangeHandler: AccentColorChangeHandler?
    private let wireMessagingFactory: any WireMessagingFactoryProtocol

    init(
        conversation: ZMConversation,
        message: ZMConversationMessage? = nil,
        mediaPlaybackManager: MediaPlaybackManager?,
        userSession: UserSession,
        mainCoordinator: AnyMainCoordinator,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol,
        userDefaults: UserDefaultsProtocol = UserDefaults.standard,
        wireMessagingFactory: any WireMessagingFactoryProtocol
    ) {
        self.messagePresenter = MessagePresenter(mediaPlaybackManager: mediaPlaybackManager)
        self.userSession = userSession
        self.mainCoordinator = mainCoordinator
        self.selfProfileUIBuilder = selfProfileUIBuilder
        self.conversation = conversation
        self.messageVisibleOnLoad = message ?? conversation.firstUnreadMessage
        self.logger = .conversation
        self.userDefaults = PrivateUserDefaults<ConversationBackgroundKey>(
            userID: userSession.selfUser.remoteIdentifier,
            storage: userDefaults
        )
        self.wireMessagingFactory = wireMessagingFactory

        super.init(nibName: nil, bundle: nil)

        self.mediaPlaybackManager = mediaPlaybackManager

        messagePresenter.targetViewController = self
        messagePresenter.modalTargetController = parent

        self.token = NotificationCenter.default.addObserver(
            forName: .activeMediaPlayerChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateMediaBar()
        }

        NotificationCenter.default.addObserver(
            forName: .featureDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let change = note.object as? LegacyFeatureRepository.FeatureChange else { return }

            switch change {
            case .fileSharingEnabled, .fileSharingDisabled:
                self?.updateVisibleCells()

            default:
                break
            }
        }

    }

    deinit {
        DeveloperToolsViewModel.context.currentConversation = nil
        NotificationCenter.default.removeObserver(self)
        accentColorChangeHandler = nil
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        view = .init()

        view.addSubview(tableView)

        view.addSubview(scrollToBottomButton)

        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomContainer)

        NSLayoutConstraint.activate(
            [
                tableView.topAnchor.constraint(equalTo: view.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                bottomContainer.topAnchor.constraint(equalTo: tableView.bottomAnchor),
                bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                bottomContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                scrollToBottomButton.trailingAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                    constant: -scrollToBottomButtonTrailingMargin
                ),
                scrollToBottomButton.bottomAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                    constant: -scrollToBottomButtonBottomMargin
                ),
                scrollToBottomButton.widthAnchor.constraint(equalToConstant: scrollToBottomButtonWidth),
                scrollToBottomButton.heightAnchor.constraint(equalToConstant: scrollToBottomButtonHeight)
            ]
        )
        let heightCollapsingConstraint = bottomContainer.heightAnchor.constraint(equalToConstant: 0)
        heightCollapsingConstraint.priority = .defaultHigh
        heightCollapsingConstraint.isActive = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = false
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false
        tableView.keyboardDismissMode = AutomationHelper.sharedHelper
            .disableInteractiveKeyboardDismissal ? .none : .interactive

        setupMentionsResultsView()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive(_:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showErrorAlertToSendMessage),
            name: ZMConversation.failedToSendMessageNotificationName,
            object: .none
        )

        updateBackgroundColor(color: userSession.selfUser.zmAccentColor)

        accentColorChangeHandler = AccentColorChangeHandler
            .addObserver(userSession: userSession) { [unowned self] color in
                updateBackgroundColor(color: color)
            }
    }

    private func updateBackgroundColor(color: ZMAccentColor?) {
        func set(color: UIColor) {
            tableView.backgroundColor = color
            view.backgroundColor = color
        }
        guard let color, userDefaults.bool(forKey: .conversationBackground) else {
            set(color: SemanticColors.View.backgroundConversationView)
            return
        }
        set(color: color.accentColor.conversationBackgroundColor)
    }

    @objc
    private func applicationDidBecomeActive(_ notification: Notification) {
        dataSource.resetSectionControllers()
    }

    private func handleScrollToBottomTapped() {
        scrollToBottomIfNeeded()
    }

    @objc
    private func showErrorAlertToSendMessage(_ notification: Notification) {
        typealias MessageSendError = L10n.Localizable.Error.Message.Send
        UIAlertController.showErrorAlertWithLink(
            title: MessageSendError.title,
            message: MessageSendError.missingLegalholdConsent
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateVisibleMessagesWindow()

        if #unavailable(iOS 13) {
            if traitCollection.forceTouchCapability == .available {
                registerForPreviewing(with: self, sourceView: view)
            }
        } else {
            // handle Context menu in table view delegate
        }

        UIAccessibility.post(notification: .screenChanged, argument: nil)
        setNeedsStatusBarAppearanceUpdate()

        startRefreshTimerIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onScreen = true

        for cell in tableView.visibleCells {
            cell.willDisplayCell()
        }

        messagePresenter.modalTargetController = parent

        updateHeaderHeight()
        updateBackgroundColor(color: userSession.selfUser.zmAccentColor)
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        onScreen = false
        removeHighlightsAndMenu()
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopRefreshTimer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let margins = HorizontalMargins.conversationHorizontalMargins()
        dataSource.contentWidth = tableView.bounds.width - margins.right - margins.left
        scrollToFirstUnreadMessageIfNeeded()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
    }

    func setupMentionsResultsView() {
        mentionsSearchResultsViewController.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(mentionsSearchResultsViewController)
        view.addSubview(mentionsSearchResultsViewController.view)

        mentionsSearchResultsViewController.view.fitIn(view: view)
    }

    func scrollToFirstUnreadMessageIfNeeded() {
        if !hasDoneInitialLayout {
            hasDoneInitialLayout = true
            scroll(to: messageVisibleOnLoad)
        }
    }

    override func didReceiveMemoryWarning() {
        zmLog.warn("Received system memory warning.")
        super.didReceiveMemoryWarning()
    }

    func setConversationHeaderView(_ headerView: UIView) {
        headerView.frame = headerViewFrame(view: headerView)
        tableView.tableHeaderView = headerView
    }

    @discardableResult
    func willSelectRow(at indexPath: IndexPath, tableView: UITableView) -> IndexPath? {
        let messages = dataSource.allMessages
        guard messages.indices.contains(indexPath.section) == true else { return nil }

        // If the menu is visible, hide it and do nothing
        if UIMenuController.shared.isMenuVisible {
            UIMenuController.shared.hideMenu()
            return nil
        }

        let message = messages[indexPath.section]

        if message == dataSource.selectedMessage {

            // If this cell is already selected, deselect it.
            dataSource.selectedMessage = nil
            dataSource.deselect(indexPath: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)

            return nil
        } else {
            if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
                dataSource.deselect(indexPath: indexPathForSelectedRow)
            }
            dataSource.selectedMessage = message
            dataSource.select(indexPath: indexPath)

            return indexPath
        }
    }

    // MARK: - Get/set

    func setTableViewBottomMargin(_ bottomMargin: CGFloat) {
        var insets = tableView.correctedContentInset
        insets.bottom = bottomMargin
        tableView.correctedContentInset = insets
        tableView.contentOffset = CGPoint(x: tableView.contentOffset.x, y: -bottomMargin)
    }

    var isScrolledToBottom: Bool {
        !dataSource.hasNewerMessagesToLoad &&
            tableView.contentOffset.y + tableView.correctedContentInset.bottom <= 0
    }

    // MARK: - Actions

    func highlight(_ message: ZMConversationMessage) {
        dataSource.highlight(message: message)
    }

    private func updateVisibleMessagesWindow() {
        guard UIApplication.shared.applicationState == .active else {
            return // We only update the last read if the app is active
        }

        // We should not update last read if the view is not visible to the user

        guard let window = view.window,
              window.convert(view.bounds, from: view).intersects(window.bounds) else {
            return
        }

        guard !view.isHidden, view.alpha != 0 else {
            return
        }

        //  Workaround to fix incorrect first/last cells in conversation
        //  As described in http://stackoverflow.com/questions/4099188/uitableviews-indexpathsforvisiblerows-incorrect
        _ = tableView.visibleCells

        let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows

        if let firstIndexPath = indexPathsForVisibleRows?.first,
           let lastVisibleMessage = dataSource.allMessages[ifExists: firstIndexPath.section] {
            conversation.markMessagesAsRead(until: lastVisibleMessage)
        }

        // Update media bar visibility
        updateMediaBar()
    }

    // MARK: - Custom UI, utilities

    func removeHighlightsAndMenu() {
        UIMenuController.shared.hideMenu()
    }

    func didFinishEditing(_ message: ZMConversationMessage?) {
        dataSource.editingMessage = nil
    }

    // MARK: - MediaPlayer

    /// Update media bar visiblity
    private func updateMediaBar() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let mediaPlayingMessage = appDelegate.mediaPlaybackManager?.activeMediaPlayer?.sourceMessage else {
            return
        }

        if mediaPlayingMessage.conversationLike === conversation,
           !displaysMessage(mediaPlayingMessage),
           !mediaPlayingMessage.isVideo {
            DispatchQueue.main.async {
                self.delegate?.conversationContentViewController(
                    self,
                    didEndDisplayingActiveMediaPlayerFor: mediaPlayingMessage
                )
            }
        } else {
            DispatchQueue.main.async {
                self.delegate?.conversationContentViewController(
                    self,
                    willDisplayActiveMediaPlayerFor: mediaPlayingMessage
                )
            }
        }
    }

    private func displaysMessage(_ message: ZMConversationMessage) -> Bool {
        guard let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows else { return false }
        let index = dataSource.indexOfMessage(message)
        return indexPathsForVisibleRows.contains { $0.section == index }
    }

    // MARK: - Feature config changes

    private func updateVisibleCells() {
        guard let visibleRows = tableView.indexPathsForVisibleRows else { return }
        tableView.beginUpdates()
        tableView.reloadRows(at: visibleRows, with: .none)
        tableView.endUpdates()
    }

    // MARK: - Update Timer

    @objc
    private func startRefreshTimerIfNeeded() {
        stopRefreshTimer()

        var timeInterval = TimeInterval()
        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            let section = dataSource.currentSections[indexPath.section]
            for cellDescription in section.elements {
                if let refreshInterval = cellDescription.conversationCellModel?.refreshInterval, refreshInterval > 0 {
                    timeInterval = timeInterval == .zero
                        ? refreshInterval
                        : min(timeInterval, refreshInterval)
                }
            }
        }

        guard timeInterval > 0 else { return }
        logger.info("starting refresh timer with interval: \(timeInterval)")
        refreshTimer = .scheduledTimer(
            timeInterval: timeInterval,
            target: self,
            selector: #selector(refreshTimerFire(_:)),
            userInfo: .none,
            repeats: true
        )
    }

    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        logger.info("stopped refresh timer")
    }

    @objc
    private func refreshTimerFire(_ timer: Timer) {
        logger.info("refresh timer fire")

        var indexPathsToReload = [IndexPath]()
        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            let section = dataSource.currentSections[indexPath.section]
            let cellDescription = section.elements[indexPath.row]
            if let refreshInterval = cellDescription.conversationCellModel?.refreshInterval, refreshInterval > 0 {
                indexPathsToReload += [indexPath]
                continue
            }
        }
        tableView.reloadRows(at: indexPathsToReload, with: .fade)
    }

}

// MARK: - TableView

extension ConversationContentViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if onScreen {
            cell.willDisplayCell()
        }

        // using dispatch_async because when this method gets run, the cell is not yet in visible cells,
        // so the update will fail
        // dispatch_async runs it with next runloop, when the cell has been added to visible cells
        DispatchQueue.main.async {
            self.updateVisibleMessagesWindow()
        }

        cachedRowHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.didEndDisplayingCell()

        cachedRowHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        cachedRowHeights[indexPath] ?? UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        willSelectRow(at: indexPath, tableView: tableView)
    }

    private func actionControllerToSwipe(
        indexPath: IndexPath,
        isLeading: Bool
    ) -> ConversationMessageActionController? {

        let section = dataSource.currentSections[ifExists: indexPath.section]?.elements[ifExists: indexPath.row]
        let actionController = section?.actionController
        let cellDescription = section?.instance
        // There were a bug with no able to swipe https://wearezeta.atlassian.net/browse/WPB-17839
        // Happened because action controller of a section controller was nil and
        // different to actionControllers[<message.nonce>], so it was out of sync
        // it was fixed but for extra safety backup action controller if not found
        var backupActionController: ConversationMessageActionController?
        if let nonce = cellDescription?.message?.nonce {
            backupActionController = dataSource.sectionControllers.get(for: nonce)?.actionController
        }

        if cellDescription?.supportsActions ?? false,
           let actionController = actionController ?? backupActionController,
           isLeading ? actionController.message.canAddReaction : actionController
           .canPerformAction(action: .react("❤️")) {
            return actionController
        }

        return nil
    }

    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {

        guard let actionController = actionControllerToSwipe(indexPath: indexPath, isLeading: true) else {
            return nil
        }

        // setting an empty title string since it would be displayed upside down
        // TODO: [WPB-16341] set "Reply" as text for accessibility reasons
        let replyAction = UIContextualAction(style: .normal, title: "") { _, _, completionHandler in
            actionController.perform(action: .reply)
            completionHandler(true)
        }

        // since the table view is flipped vertically we also render the image flipped
        // TODO: [WPB-16341] use the arrowImage, remove the upsideDownImage
        let arrowImage = UIImage(systemName: "arrowshape.turn.up.backward.fill")!
            .withTintColor(.white, renderingMode: .alwaysTemplate)
            .verticallyInverted()

        replyAction.image = arrowImage
        replyAction.backgroundColor = UIColor.accent()
        return UISwipeActionsConfiguration(actions: [replyAction])
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {

        guard let actionController = actionControllerToSwipe(indexPath: indexPath, isLeading: true) else {
            return nil
        }

        // since the table view is flipped vertically we also render the image flipped
        // TODO: [WPB-16341] use the real image, remove the upsideDownImage
        let reactImage = UIImage(resource: .addEmojis)
            .withTintColor(.white, renderingMode: .alwaysTemplate)
            .verticallyInverted()

        let reactAction = UIContextualAction(style: .normal, title: "") { [weak self] _, _, completionHandler in
            guard let delegate = self?.delegate else {
                completionHandler(false)
                return
            }
            completionHandler(true)
            // Since view is swipable, we need to wait for it to go back
            // so we can show popover from cell's original place and not from swiped position
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let popoverInfo = tableView.cellForRow(at: indexPath).map {
                    (sourceView: tableView, frame: $0.frame)
                }
                delegate.didSwipeToReact(actionController: actionController, popoverPresentationInfo: popoverInfo)
            }
        }
        reactAction.image = reactImage
        reactAction.backgroundColor = UIColor.accent()
        return UISwipeActionsConfiguration(actions: [reactAction])
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        startRefreshTimerIfNeeded()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // use for example when tapping the arrow to scroll to the bottom
        startRefreshTimerIfNeeded()
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        startRefreshTimerIfNeeded()
    }
}

extension ConversationContentViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // no-op
    }
}

private extension UIAlertController {

    static func showErrorAlertWithLink(
        title: String,
        message: String
    ) {
        let topmostViewController = UIApplication.shared.topmostViewController(onlyFullScreen: false)

        let legalHoldLearnMoreHandler: ((UIAlertAction) -> Swift.Void) = { _ in
            WireURLs.shared.legalHoldInfo.open(from: topmostViewController)
        }

        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))
        alertController.addAction(UIAlertAction(
            title: L10n.Localizable.LegalholdActive.Alert.learnMore,
            style: .default,
            handler: legalHoldLearnMoreHandler
        ))

        topmostViewController?.present(alertController, animated: true)
    }

}

extension AccentColor {
    var conversationBackgroundColor: UIColor {
        switch self {
        case .blue:
            SemanticColors.View.conversationBackgroundBlue
        case .purple:
            SemanticColors.View.conversationBackgroundPurple
        case .green:
            SemanticColors.View.conversationBackgroundGreen
        case .amber:
            SemanticColors.View.conversationBackgroundAmber
        case .red:
            SemanticColors.View.conversationBackgroundRed
        case .turquoise:
            SemanticColors.View.conversationBackgroundTurquoise
        }
    }
}
