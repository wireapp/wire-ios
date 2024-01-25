//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import WireSyncEngine
import WireCommonComponents

final class ConversationViewController: UIViewController {
    unowned let zClientViewController: ZClientViewController
    private let visibleMessage: ZMConversationMessage?

    typealias keyboardShortcut = L10n.Localizable.Keyboardshortcut

    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(action: #selector(gotoBottom(_:)),
                         input: UIKeyCommand.inputDownArrow,
                         modifierFlags: [.command, .alternate],
                         discoverabilityTitle: keyboardShortcut.scrollToBottom),
            UIKeyCommand(action: #selector(onCollectionButtonPressed(_:)),
                         input: "f",
                         modifierFlags: [.command],
                         discoverabilityTitle: keyboardShortcut.searchInConversation),
            UIKeyCommand(action: #selector(titleViewTapped),
                         input: "i", modifierFlags: [.command],
                         discoverabilityTitle: keyboardShortcut.conversationDetail)
        ]
    }

    @objc
    func gotoBottom(_: Any?) {
        contentViewController.tableView.scrollToBottom(animated: true)
    }

    var conversation: ZMConversation {
        didSet {
            if oldValue == conversation {
                return
            }

            update(conversation: conversation)
        }
    }

    var isFocused = false

    private(set) var startCallController: ConversationCallController!

    let contentViewController: ConversationContentViewController
    let inputBarController: ConversationInputBarViewController

    var collectionController: CollectionsViewController?
    var outgoingConnectionViewController: OutgoingConnectionViewController!
    let conversationBarController: BarController = BarController()
    let guestsBarController: GuestsBarController = GuestsBarController()
    let invisibleInputAccessoryView: InvisibleInputAccessoryView = InvisibleInputAccessoryView()
    let mediaBarViewController: MediaBarViewController
    private let titleView: ConversationTitleView

    let userSession: UserSession

    var inputBarBottomMargin: NSLayoutConstraint?
    var inputBarZeroHeight: NSLayoutConstraint?

    var isAppearing = false
    private var voiceChannelStateObserverToken: Any?
    private var conversationObserverToken: Any?
    private var conversationListObserverToken: Any?

    var participantsController: UIViewController? {

        var viewController: UIViewController?

        switch conversation.conversationType {
        case .group:
            let groupDetailsViewController = GroupDetailsViewController(conversation: conversation, userSession: userSession)
            viewController = groupDetailsViewController
        case .`self`, .oneOnOne, .connection:
            viewController = createUserDetailViewController()
        case .invalid:
            fatal("Trying to open invalid conversation")
        default:
            break
        }

        return viewController?.wrapInNavigationController(setBackgroundColor: true)
    }

    required init(conversation: ZMConversation,
                  visibleMessage: ZMMessage?,
                  zClientViewController: ZClientViewController,
                  userSession: UserSession) {
        self.conversation = conversation
        self.visibleMessage = visibleMessage
        self.zClientViewController = zClientViewController
        self.userSession = userSession
        contentViewController = ConversationContentViewController(conversation: conversation,
                                                                  message: visibleMessage,
                                                                  mediaPlaybackManager: zClientViewController.mediaPlaybackManager,
                                                                  userSession: userSession)

        inputBarController = ConversationInputBarViewController(conversation: conversation, userSession: userSession)

        mediaBarViewController = MediaBarViewController(mediaPlaybackManager: zClientViewController.mediaPlaybackManager)

        titleView = ConversationTitleView(conversation: conversation, interactive: true)

        super.init(nibName: nil, bundle: nil)

        definesPresentationContext = true

        update(conversation: conversation)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        dismissCollectionIfNecessary()

        hideAndDestroyParticipantsPopover()
        contentViewController.delegate = nil
    }

    private func update(conversation: ZMConversation) {
        setupNavigatiomItem()
        updateOutgoingConnectionVisibility()

        voiceChannelStateObserverToken = addCallStateObserver()
        conversationObserverToken = ConversationChangeInfo.add(observer: self, for: conversation)
        startCallController = ConversationCallController(conversation: conversation, target: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        conversationListObserverToken = userSession.addConversationListObserver(
            self,
            for: userSession.conversationList()
        )

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        UIView.performWithoutAnimation({
            self.view.backgroundColor = SemanticColors.View.backgroundConversationView
        })

        setupInputBarController()
        setupContentViewController()

        contentViewController.tableView.pannableView = inputBarController.view

        setupMediaBarViewController()

        addToSelf(contentViewController)
        addToSelf(inputBarController)
        addToSelf(conversationBarController)

        updateOutgoingConnectionVisibility()
        createConstraints()
        updateInputBarVisibility()

        if let quote = conversation.draftMessage?.quote, !quote.hasBeenDeleted {
            inputBarController.addReplyComposingView(contentViewController.createReplyComposingView(for: quote))
        }

        resolveConversationIfOneOnOne()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            updateRightNavigationItemsButtons()
            updateLeftNavigationBarItems()
        }
    }

    func createOutgoingConnectionViewController() {
        outgoingConnectionViewController = OutgoingConnectionViewController()
        outgoingConnectionViewController.view.translatesAutoresizingMaskIntoConstraints = false
        outgoingConnectionViewController.buttonCallback = { [weak self] action in

            switch action {
            case .cancel:
                self?.conversation.connectedUser?.cancelConnectionRequest(completion: { (error) in
                    if let error = error as? LocalizedError {
                        self?.presentLocalizedErrorAlert(error)
                    }
                })
            case .archive:
                self?.userSession.enqueue({
                    self?.conversation.isArchived = true
                })
            }
            self?.openConversationList()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isAppearing = true
        updateGuestsBarVisibility()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        updateGuestsBarVisibility()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateLeftNavigationBarItems()
        ZMUserSession.shared()?.didClose(conversation: conversation)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateLeftNavigationBarItems()
    }

    func scroll(to message: ZMConversationMessage?) {
        contentViewController.scroll(to: message, completion: nil)
    }

    // MARK: - Device orientation
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return .all
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil) { _ in
            self.updateLeftNavigationBarItems()
        }

        super.viewWillTransition(to: size, with: coordinator)

        hideAndDestroyParticipantsPopover()
    }

    override func willTransition(to newCollection: UITraitCollection,
                                 with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        self.updateLeftNavigationBarItems()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        if collectionController?.view.window == nil {
            collectionController = nil
        }
    }

    func openConversationList() {
        guard let leftControllerRevealed = wr_splitViewController?.isLeftViewControllerRevealed else { return }
        wr_splitViewController?.setLeftViewControllerRevealed(!leftControllerRevealed, animated: true, completion: nil)
    }

    // MARK: - Getters, setters

    func setCollection(_ collectionController: CollectionsViewController?) {
        self.collectionController = collectionController

        updateLeftNavigationBarItems()
    }

    // MARK: - Application Events & Notifications
    override func accessibilityPerformEscape() -> Bool {
        openConversationList()
        return true
    }

    @objc
    func onBackButtonPressed(_ backButton: UIButton?) {
        openConversationList()
    }

    private func setupContentViewController() {
        contentViewController.delegate = self
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentViewController.bottomMargin = 16
        inputBarController.mentionsView = contentViewController.mentionsSearchResultsViewController
        contentViewController.mentionsSearchResultsViewController.delegate = inputBarController
    }

    private func setupMediaBarViewController() {
        mediaBarViewController.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapMediaBar(_:))))
    }

    @objc
    func didTapMediaBar(_ tapGestureRecognizer: UITapGestureRecognizer?) {
        if let mediaPlayingMessage = AppDelegate.shared.mediaPlaybackManager?.activeMediaPlayer?.sourceMessage,
           conversation === mediaPlayingMessage.conversationLike {
            contentViewController.scroll(to: mediaPlayingMessage, completion: nil)
        }
    }

    private func setupInputBarController() {
        inputBarController.delegate = self
        inputBarController.view.translatesAutoresizingMaskIntoConstraints = false

        // Create an invisible input accessory view that will allow us to take advantage of built in keyboard
        // dragging and sizing of the scrollview
        invisibleInputAccessoryView.delegate = self
        invisibleInputAccessoryView.isUserInteractionEnabled = false // make it not block touch events
        invisibleInputAccessoryView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        if !AutomationHelper.sharedHelper.disableInteractiveKeyboardDismissal {
            inputBarController.inputBar.invisibleInputAccessoryView = invisibleInputAccessoryView
        }
    }

    private func updateInputBarVisibility() {
        if conversation.isReadOnly {
            inputBarController.inputBar.textView.resignFirstResponder()
            inputBarController.dismissMentionsIfNeeded()
            inputBarController.removeReplyComposingView()
        }

        inputBarZeroHeight?.isActive = conversation.isReadOnly
        view.setNeedsLayout()
    }

    @objc
    private func titleViewTapped() {
        if let superview = titleView.superview,
           let participantsController = participantsController {
            presentParticipantsViewController(participantsController, from: superview)
        }
    }

    private func setupNavigatiomItem() {
        titleView.tapHandler = { [weak self] _ in
            self?.titleViewTapped()
        }
        titleView.configure()

        navigationItem.titleView = titleView
        navigationItem.leftItemsSupplementBackButton = false

        updateRightNavigationItemsButtons()
    }

    // MARK: Resolve 1-1 conversations

    private func resolveConversationIfOneOnOne() {
        let isOneOnOneConversation = conversation.conversationType == .oneOnOne
            || conversation.conversationType == .group && (conversation.localParticipants.count == 2)

        guard isOneOnOneConversation && conversation.messageProtocol == .proteus else {
            return
        }

        guard
            let otherUser = conversation.localParticipants.first(where: { !$0.isSelfUser }),
            let otherUserID = otherUser.qualifiedID,
            let context = conversation.managedObjectContext,
            let mlsService = context.mlsService
        else {
            WireLogger.conversation.warn("missing expected value to resolve 1-1 conversation!")
            return
        }

        Task {
            do {
                let service = OneOnOneResolver(
                    protocolSelector: OneOnOneProtocolSelector(),
                    migrator: OneOnOneMigrator(mlsService: mlsService)
                )
                let resolvedState = try await service.resolveOneOnOneConversation(with: otherUserID, in: context)

                if case .migratedToMLSGroup(let identifier) = resolvedState {
                    await navigateToNewMLSConversation(mlsGroupIdentifier: identifier, in: context)
                }
            } catch {
                WireLogger.conversation.warn("resolution of proteus 1-1 conversation failed: \(error)")
            }
        }
    }

    @MainActor
    private func navigateToNewMLSConversation(
        mlsGroupIdentifier: MLSGroupID,
        in context: NSManagedObjectContext
    ) async {
        let mlsConversation = await context.perform {
            ZMConversation.fetch(with: mlsGroupIdentifier, in: context)
        }

        guard let mlsConversation else {
            assertionFailure("conversation with MLSGroupID \(mlsGroupIdentifier) is expected to be always available at this point!")
            return
        }

        zClientViewController.showConversation(mlsConversation, at: nil)
    }

    // MARK: - ParticipantsPopover

    private func hideAndDestroyParticipantsPopover() {
        if (presentedViewController is GroupDetailsViewController) || (presentedViewController is ProfileViewController) {
            dismiss(animated: true)
        }
    }
}

// MARK: - InvisibleInputAccessoryViewDelegate

extension ConversationViewController: InvisibleInputAccessoryViewDelegate {

    // WARNING: DO NOT TOUCH THIS UNLESS YOU KNOW WHAT YOU ARE DOING
    func invisibleInputAccessoryView(_ invisibleInputAccessoryView: InvisibleInputAccessoryView, superviewFrameChanged frame: CGRect?) {
        // Adjust the input bar distance from bottom based on the invisibleAccessoryView
        var distanceFromBottom: CGFloat = 0

        // On iOS 8, the frame goes to zero when the accessory view is hidden
        if frame?.equalTo(.zero) == false {

            let convertedFrame = view.convert(invisibleInputAccessoryView.superview?.frame ?? .zero, from: invisibleInputAccessoryView.superview?.superview)

            // We have to use intrinsicContentSize here because the frame may not have actually been updated yet
            let newViewHeight = invisibleInputAccessoryView.intrinsicContentSize.height

            distanceFromBottom = view.frame.size.height - convertedFrame.origin.y - newViewHeight

            distanceFromBottom = max(0, distanceFromBottom)
        }

        let closure: () -> Void = {
            self.inputBarBottomMargin?.constant = -distanceFromBottom
            self.view.layoutIfNeeded()
        }

        if isAppearing {
            UIView.performWithoutAnimation(closure)
        } else {
            closure()
        }
    }
}

// MARK: - ZMConversationObserver

extension ConversationViewController: ZMConversationObserver {
    func conversationDidChange(_ note: ConversationChangeInfo) {
        if note.causedByConversationPrivacyChange {
            presentPrivacyWarningAlert(for: note)
        }

        if note.participantsChanged ||
            note.connectionStateChanged {
            updateRightNavigationItemsButtons()
            updateLeftNavigationBarItems()
            updateOutgoingConnectionVisibility()
            contentViewController.updateTableViewHeaderView()
            updateInputBarVisibility()
        }

        if note.participantsChanged ||
            note.externalParticipantsStateChanged {
            updateGuestsBarVisibility()
        }

        if note.nameChanged ||
            note.securityLevelChanged ||
            note.connectionStateChanged ||
            note.legalHoldStatusChanged {
            setupNavigatiomItem()
        }
    }

    func dismissProfileClientViewController(_ sender: UIBarButtonItem?) {
        dismiss(animated: true)
    }
}

// MARK: - ZMConversationListObserver

extension ConversationViewController: ZMConversationListObserver {
    func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
        updateLeftNavigationBarItems()
        if changeInfo.deletedObjects.contains(conversation) {
            ZClientViewController.shared?.transitionToList(animated: true, completion: nil)
        }
    }

    func conversationInsideList(_ list: ZMConversationList, didChange changeInfo: ConversationChangeInfo) {
        updateLeftNavigationBarItems()
    }
}

// MARK: - InputBar

extension ConversationViewController: ConversationInputBarViewControllerDelegate {
    func conversationInputBarViewControllerDidComposeText(text: String,
                                                          mentions: [Mention],
                                                          replyingTo message: ZMConversationMessage?) {
        contentViewController.scrollToBottomIfNeeded()
        inputBarController.sendController.sendTextMessage(text, mentions: mentions, userSession: userSession, replyingTo: message)
    }

    func conversationInputBarViewControllerShouldBeginEditing(_ controller: ConversationInputBarViewController) -> Bool {
        if !contentViewController.isScrolledToBottom && !controller.isEditingMessage &&
            !controller.isReplyingToMessage {
            collectionController = nil
            contentViewController.searchQueries = []
            contentViewController.scrollToBottomIfNeeded()
        }

        setGuestBarForceHidden(true)
        return true
    }

    func conversationInputBarViewControllerShouldEndEditing(_ controller: ConversationInputBarViewController) -> Bool {
        setGuestBarForceHidden(false)
        return true
    }

    func conversationInputBarViewControllerDidFinishEditing(_ message: ZMConversationMessage,
                                                            withText newText: String?,
                                                            mentions: [Mention]) {
        contentViewController.didFinishEditing(message)
        userSession.enqueue({
            if let newText = newText,
               !newText.isEmpty {
                let fetchLinkPreview = !Settings.disableLinkPreviews
                message.textMessageData?.editText(newText, mentions: mentions, fetchLinkPreview: fetchLinkPreview)
            } else {
                ZMMessage.deleteForEveryone(message)
            }
        })
    }

    func conversationInputBarViewControllerDidCancelEditing(_ message: ZMConversationMessage) {
        contentViewController.didFinishEditing(message)
    }

    func conversationInputBarViewControllerWants(toShow message: ZMConversationMessage) {
        contentViewController.scroll(to: message) { _ in
            self.contentViewController.highlight(message)
        }
    }

    func conversationInputBarViewControllerEditLastMessage() {
        contentViewController.editLastMessage()
    }

    func conversationInputBarViewControllerDidComposeDraft(message: DraftMessage) {
        userSession.enqueue {
            self.conversation.draftMessage = message
        }
    }

    var searchBarButtonItem: UIBarButtonItem {
        let showingSearchResults = (self.collectionController?.isShowingSearchResults ?? false)
        let action = #selector(ConversationViewController.onCollectionButtonPressed(_:))

        let button = IconButton()
        button.setIcon(showingSearchResults ? .activeSearch : .search, size: .tiny, for: .normal)
        button.accessibilityIdentifier = "collection"
        button.accessibilityLabel = L10n.Accessibility.Conversation.SearchButton.description

        button.addTarget(self, action: action, for: .touchUpInside)

        button.backgroundColor = SemanticColors.Button.backgroundBarItem
        button.setIconColor(SemanticColors.Icon.foregroundDefault, for: .normal)
        button.layer.borderWidth = 1
        button.setBorderColor(SemanticColors.Button.borderBarItem.resolvedColor(with: traitCollection), for: .normal)
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.bounds.size = button.systemLayoutSizeFitting(CGSize(width: .max, height: 32))

        return UIBarButtonItem(customView: button)
    }

    @objc
    private func onCollectionButtonPressed(_ sender: AnyObject?) {
        if collectionController == .none {
            let collections = CollectionsViewController(conversation: conversation, userSession: userSession)
            collections.delegate = self

            collections.onDismiss = { [weak self] _ in
                guard let weakSelf = self else {
                    return
                }

                weakSelf.collectionController?.dismiss(animated: true)
            }
            collectionController = collections
        } else {
            collectionController?.refetchCollection()
        }

        collectionController?.shouldTrackOnNextOpen = true

        let navigationController = KeyboardAvoidingViewController(viewController: collectionController!).wrapInNavigationController(setBackgroundColor: true)

        ZClientViewController.shared?.present(navigationController, animated: true)
    }

}
