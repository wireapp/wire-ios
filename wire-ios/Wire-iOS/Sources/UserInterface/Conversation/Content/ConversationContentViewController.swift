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

    let tableView = UpsideDownTableView(frame: .zero, style: .plain)
    let bottomContainer = UIView(frame: .zero)
    var searchQueries: [String]? {
        didSet {
            guard let searchQueries,
                  !searchQueries.isEmpty else { return }

            dataSource.searchQueries = searchQueries
        }
    }

    let mentionsSearchResultsViewController = UserSearchResultsViewController()

    lazy var dataSource = ConversationTableViewDataSource(
        conversation: conversation,
        tableView: tableView,
        actionResponder: self,
        cellDelegate: self,
        userSession: userSession
    )

    let messagePresenter: MessagePresenter
    var deletionDialogPresenter: DeletionDialogPresenter?
    let userSession: UserSession
    let mainCoordinator: MainCoordinating
    var connectionViewController: UserConnectionViewController?
    var digitalSignatureToken: Any?
    var userClientToken: Any?
    var isDigitalSignatureVerificationShown = false

    private var mediaPlaybackManager: MediaPlaybackManager?
    private var cachedRowHeights: [IndexPath: CGFloat] = [:]
    private var hasDoneInitialLayout = false
    private var onScreen = false
    private weak var messageVisibleOnLoad: ZMConversationMessage?
    private var token: NSObjectProtocol?

    private(set) lazy var activityIndicator = BlockingActivityIndicator(view: view)

    init(
        conversation: ZMConversation,
        message: ZMConversationMessage? = nil,
        mediaPlaybackManager: MediaPlaybackManager?,
        userSession: UserSession,
        mainCoordinator: some MainCoordinating
    ) {
        messagePresenter = MessagePresenter(mediaPlaybackManager: mediaPlaybackManager)
        self.userSession = userSession
        self.mainCoordinator = mainCoordinator
        self.conversation = conversation
        messageVisibleOnLoad = message ?? conversation.firstUnreadMessage

        super.init(nibName: nil, bundle: nil)

        self.mediaPlaybackManager = mediaPlaybackManager

        messagePresenter.targetViewController = self
        messagePresenter.modalTargetController = parent

        token = NotificationCenter.default.addObserver(forName: .activeMediaPlayerChanged, object: nil, queue: .main) { [weak self] _ in
            self?.updateMediaBar()
        }

        NotificationCenter.default.addObserver(forName: .featureDidChangeNotification,
                                               object: nil,
                                               queue: .main) { [weak self] note in
            guard let change = note.object as? FeatureRepository.FeatureChange else { return }

            switch change {
            case .fileSharingEnabled, .fileSharingDisabled:
                self?.updateVisibleCells()

            default:
                break
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: ZMConversation.failedToSendMessageNotificationName, object: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()

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
                scrollToBottomButton.heightAnchor.constraint(equalToConstant: scrollToBottomButtonHeight),
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
        tableView.keyboardDismissMode = AutomationHelper.sharedHelper.disableInteractiveKeyboardDismissal ? .none : .interactive

        tableView.backgroundColor = SemanticColors.View.backgroundConversationView
        view.backgroundColor = SemanticColors.View.backgroundConversationView

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
    }

    @objc
    private func applicationDidBecomeActive(_ notification: Notification) {
        dataSource.resetSectionControllers()
        tableView.reloadData()
    }

    private func handleScrollToBottomTapped() {
        scrollToBottomIfNeeded()
    }

    @objc
    private func showErrorAlertToSendMessage(_ notification: Notification) {
        typealias MessageSendError = L10n.Localizable.Error.Message.Send
        UIAlertController.showErrorAlertWithLink(title: MessageSendError.title,
                                                 message: MessageSendError.missingLegalholdConsent)
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onScreen = true

        for cell in tableView.visibleCells {
            cell.willDisplayCell()
        }

        messagePresenter.modalTargetController = parent

        updateHeaderHeight()

        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        onScreen = false
        removeHighlightsAndMenu()
        super.viewWillDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

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

    override var shouldAutorotate: Bool {
        true
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
        guard dataSource.messages.indices.contains(indexPath.section) == true else { return nil }

        // If the menu is visible, hide it and do nothing
        if UIMenuController.shared.isMenuVisible {
            UIMenuController.shared.hideMenu()
            return nil
        }

        let message = dataSource.messages[indexPath.section] as? ZMMessage

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

        if let firstIndexPath = indexPathsForVisibleRows?.first {
            let lastVisibleMessage = dataSource.messages[firstIndexPath.section]
            conversation.markMessagesAsRead(until: lastVisibleMessage)
        }

        // Update media bar visiblity
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
        let mediaPlayingMessage = AppDelegate.shared.mediaPlaybackManager?.activeMediaPlayer?.sourceMessage

        if let mediaPlayingMessage,
           mediaPlayingMessage.conversationLike === conversation,
           !displaysMessage(mediaPlayingMessage),
           !mediaPlayingMessage.isVideo {
            DispatchQueue.main.async {
                self.delegate?.conversationContentViewController(self, didEndDisplayingActiveMediaPlayerFor: mediaPlayingMessage)
            }
        } else {
            DispatchQueue.main.async {
                self.delegate?.conversationContentViewController(self, willDisplayActiveMediaPlayerFor: mediaPlayingMessage)
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
}

extension ConversationContentViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // no-op
    }
}

extension UIAlertController {
    fileprivate static func showErrorAlertWithLink(title: String,
                                                   message: String) {
        let topmostViewController = UIApplication.shared.topmostViewController(onlyFullScreen: false)

        let legalHoldLearnMoreHandler: ((UIAlertAction) -> Swift.Void) = { _ in
            let browserViewController = BrowserViewController(url: WireURLs.shared.legalHoldInfo)
            topmostViewController?.present(browserViewController, animated: true)
        }

        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)

        alertController.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))
        alertController.addAction(UIAlertAction(title: L10n.Localizable.LegalholdActive.Alert.learnMore,
                                                style: .default,
                                                handler: legalHoldLearnMoreHandler))

        topmostViewController?.present(alertController, animated: true)
    }
}
