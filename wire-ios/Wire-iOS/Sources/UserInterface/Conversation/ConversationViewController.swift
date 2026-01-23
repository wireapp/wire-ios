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

import UIKit
import WireCommonComponents
import WireDesign
import WireDomain
import WireFoundation
import WireLocators
import WireLogging
import WireMainNavigationUI
import WireMessagingAssembly
import WireMessagingDomain
import WireMessagingUI
import WireSyncEngine

final class ConversationViewController: UIViewController {

    let mainCoordinator: AnyMainCoordinator
    let selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol
    let conversationCreationRepository: any ConversationCreationRepositoryProtocol
    private let visibleMessage: ZMConversationMessage?
    private let getParticipantImageSourceUseCase: GetParticipantImageSourceUseCaseProtocol
    var actionControllerForSelectedEmoji: ConversationMessageActionController?
    let wireMessagingFactory: WireMessagingFactoryProtocol
    private(set) var wireDriveState: CellsState = .disabled
    typealias keyboardShortcut = L10n.Localizable.Keyboardshortcut

    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(
                action: #selector(gotoBottom(_:)),
                input: UIKeyCommand.inputDownArrow,
                modifierFlags: [.command, .alternate],
                discoverabilityTitle: keyboardShortcut.scrollToBottom
            ),
            UIKeyCommand(
                action: #selector(onSearchButtonPressed(_:)),
                input: "f",
                modifierFlags: [.command],
                discoverabilityTitle: keyboardShortcut.searchInConversation
            ),
            UIKeyCommand(
                action: #selector(onConversationDetailsPressed),
                input: "i",
                modifierFlags: [.command],
                discoverabilityTitle: keyboardShortcut.conversationDetail
            )
        ]
    }

    @objc
    func gotoBottom(_: Any?) {
        contentViewController?.tableView.scrollToBottom(animated: true)
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

    let exchangeableContentViewController: UIViewController

    var contentViewController: ConversationContentViewController? {
        exchangeableContentViewController as? ConversationContentViewController
    }

    let inputBarController: ConversationInputBarViewController

    var collectionController: CollectionsViewController?
    var outgoingConnectionViewController: OutgoingConnectionViewController!
    let conversationBarController: BarController = .init()
    let guestsBarController: GuestsBarController = .init()
    let invisibleInputAccessoryView: InvisibleInputAccessoryView = .init()
    private let mediaBarViewController: MediaBarViewController

    private let titleView: WireMessagingUI.ConversationTitleView

    let userSession: UserSession

    var inputBarBottomMargin: NSLayoutConstraint?
    var inputBarZeroHeight: NSLayoutConstraint?

    var isAppearing = false
    private var voiceChannelStateObserverToken: Any?
    private var conversationObserverToken: Any?
    private var conversationListObserverToken: Any?
    private var userObservationToken: NSObjectProtocol?
    private var selfUserObservationToken: NSObjectProtocol?
    var updateLeftNavigationBarItemsTask: Task<Void, Never>?

    var participantsController: UIViewController? {
        get async {

            let areLegacyBotsAvailable = (try? await conversationCreationRepository.areBotsSetUpInTheTeam()) ?? false
            let isAppsFeatureEnabled = await userSession.clientSessionComponent?.featureConfigRepository
                .isFeatureEnabled(.apps) ?? false

            var viewController: UIViewController?

            switch conversation.conversationType {
            case .group:
                viewController = GroupDetailsViewController(
                    conversation: conversation,
                    userSession: userSession,
                    mainCoordinator: mainCoordinator,
                    selfProfileUIBuilder: selfProfileUIBuilder,
                    conversationCreationRepository: conversationCreationRepository,
                    isUserE2EICertifiedUseCase: userSession.isUserE2EICertifiedUseCase,
                    areLegacyBotsAvailable: areLegacyBotsAvailable,
                    isAppsFeatureEnabled: isAppsFeatureEnabled
                )
            case .`self`, .oneOnOne, .connection:
                viewController = createUserDetailViewController()
            case .invalid:
                fatal("Trying to open invalid conversation")
            default:
                break
            }
            guard let viewController else { return nil }
            return UINavigationController(rootViewController: viewController)
        }
    }

    private let individualChangesFactory: MessagesIndividualUpdatesFactory

    required init(
        conversation: ZMConversation,
        visibleMessage: ZMMessage?,
        userSession: UserSession,
        mainCoordinator: AnyMainCoordinator,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol,
        conversationCreationRepository: any ConversationCreationRepositoryProtocol,
        mediaPlaybackManager: MediaPlaybackManager?,
        classificationProvider: (any SecurityClassificationProviding)?,
        networkStatusObservable: any NetworkStatusObservable,
        getParticipantImageSourceUseCase: any GetParticipantImageSourceUseCaseProtocol,
        wireMessagingFactory: any WireMessagingFactoryProtocol
    ) {
        self.conversation = conversation
        self.visibleMessage = visibleMessage
        self.userSession = userSession
        self.mainCoordinator = mainCoordinator
        self.selfProfileUIBuilder = selfProfileUIBuilder
        self.conversationCreationRepository = conversationCreationRepository

        self.individualChangesFactory = MessagesIndividualUpdatesFactory(
            context: userSession.contextProvider.viewContext
        )
        self.exchangeableContentViewController = if DeveloperFlag.chatBubbles.isOn {
            WireMessagingAssembly.makeConversationScreen(
                loadMessagesRepo: LoadConversationMessagesRepository(
                    conversationObjectID: conversation.objectID,
                    syncContext: userSession.contextProvider.syncContext,
                    backgroundContext: userSession.contextProvider.newBackgroundContext()
                ),
                senderNameObserverProvider: { [individualChangesFactory] model in
                    individualChangesFactory.makeSenderNameObserver(user: model)
                }
            )
        } else {
            ConversationContentViewController(
                conversation: conversation,
                message: visibleMessage,
                mediaPlaybackManager: mediaPlaybackManager,
                userSession: userSession,
                mainCoordinator: mainCoordinator,
                selfProfileUIBuilder: selfProfileUIBuilder,
                conversationCreationRepository: conversationCreationRepository,
                wireMessagingFactory: wireMessagingFactory
            )
        }

        self.getParticipantImageSourceUseCase = getParticipantImageSourceUseCase

        DeveloperToolsViewModel.context.currentConversation = conversation

        self.inputBarController = ConversationInputBarViewController(
            conversation: conversation,
            userSession: userSession,
            classificationProvider: classificationProvider,
            networkStatusObservable: networkStatusObservable,
            wireMessagingFactory: wireMessagingFactory
        )

        self.mediaBarViewController = MediaBarViewController(mediaPlaybackManager: mediaPlaybackManager)

        self.titleView = WireMessagingUI.ConversationTitleView(
            source: ConversationTitleSource(
                accountImageSource: nil,
                title: conversation.displayNameWithFallback,
                subtitle: Self.getConversationSubtitle(conversation),
                isMLS: conversation.messageProtocol == .mls,
                isVerified: conversation.isVerified,
                isUnderLegalHold: conversation.isUnderLegalHold
            ),
            canAnimate: !ProcessInfo.processInfo.isRunningTests
        )

        self.wireMessagingFactory = wireMessagingFactory
        self.wireDriveState = userSession.contextProvider.syncContext.performAndWait {
            conversation.cellsState
        }

        super.init(nibName: nil, bundle: nil)

        definesPresentationContext = true

        update(conversation: conversation)

        if let user = conversation.firstActiveParticipantOtherThanSelf {
            titleView.updateOtherUserAccentColor(user.accentColor)
        }
        titleView.updateSelfUserAccentColor(userSession.selfUser.accentColor)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        dismissCollectionIfNecessary()

        hideAndDestroyParticipantsPopover()
        contentViewController?.delegate = nil
    }

    private var observationToken: SelfUnregisteringNotificationCenterToken?

    private func update(conversation: ZMConversation) {
        setupNavigationItem()
        updateOutgoingConnectionVisibility()

        voiceChannelStateObserverToken = addCallStateObserver()
        conversationObserverToken = ConversationChangeInfo.add(observer: self, for: conversation)
        if let participant = conversation.firstActiveParticipantOtherThanSelf {
            userObservationToken = userSession.addUserObserver(self, for: participant)
        }

        selfUserObservationToken = userSession.addUserObserver(self, for: userSession.selfUser)

        startCallController = ConversationCallController(conversation: conversation, target: self)

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        conversationListObserverToken = userSession.addConversationListObserver(
            self,
            for: userSession.conversationList()
        )

        observationToken = PrivacyWarningChecker.addPresenter(self)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardFrameWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )

        UIView.performWithoutAnimation {
            self.view.backgroundColor = SemanticColors.View.backgroundConversationView
        }

        setupInputBarController()
        setupContentViewController()

        contentViewController?.tableView.pannableView = inputBarController.view

        setupMediaBarViewController()

        addToSelf(exchangeableContentViewController)
        addToSelf(inputBarController)
        addToSelf(conversationBarController)

        updateOutgoingConnectionVisibility()
        createConstraints()
        updateInputBarVisibility()

        if let quote = conversation.draftMessage?.quote, !quote.hasBeenDeleted, let contentViewController {
            let messageReplyAttachmentsViewModel = MessageReplyAttachmentsViewModel(
                fetchCachedNodeUseCase: wireMessagingFactory.makeFetchCachedNodeUseCase(),
                fetchNodeUseCase: wireMessagingFactory.makeFetchNodeUseCase()
            )
            inputBarController.addReplyComposingView(contentViewController.createReplyComposingView(
                for: quote,
                messageReplyAttachmentsViewModel: messageReplyAttachmentsViewModel
            ))
        }

        resolveConversationIfOneOnOne()
        updateVerificationStatusIfNeeded()
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
                self?.conversation.connectedUser?.cancelConnectionRequest(completion: { error in
                    if let error = error as? LocalizedError {
                        self?.presentLocalizedErrorAlert(error)
                    }
                })
            case .archive:
                self?.userSession.enqueue {
                    self?.conversation.isArchived = true
                }
            }
            self?.mainCoordinator.hideConversation()
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
        contentViewController?.scroll(to: message, completion: nil)
    }

    // MARK: - Device orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            .portrait
        } else {
            .all
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil) { _ in
            self.updateLeftNavigationBarItems()
        }

        super.viewWillTransition(to: size, with: coordinator)

        hideAndDestroyParticipantsPopover()
    }

    override func willTransition(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.willTransition(to: newCollection, with: coordinator)
        updateLeftNavigationBarItems()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        if collectionController?.view.window == nil {
            collectionController = nil
        }
    }

    // MARK: - Application Events & Notifications

    override func accessibilityPerformEscape() -> Bool {
        mainCoordinator.hideConversation()
        return true
    }

    @objc
    func onBackButtonPressed(_ backButton: UIButton?) {
        mainCoordinator.hideConversation()
    }

    private func setupContentViewController() {
        contentViewController?.delegate = self
        exchangeableContentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentViewController?.bottomMargin = 16
        inputBarController.mentionsView = contentViewController?.mentionsSearchResultsViewController
        contentViewController?.mentionsSearchResultsViewController.delegate = inputBarController
    }

    private func setupMediaBarViewController() {
        mediaBarViewController.view.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(didTapMediaBar(_:))
        ))
    }

    @objc
    func didTapMediaBar(_ tapGestureRecognizer: UITapGestureRecognizer?) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let mediaPlayingMessage = appDelegate.mediaPlaybackManager?.activeMediaPlayer?.sourceMessage,
           conversation === mediaPlayingMessage.conversationLike {
            contentViewController?.scroll(to: mediaPlayingMessage, completion: nil)
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
    private func setupTitleViewTap() {
        var actions = [UIAction]()

        // uncomment code when feature prod ready
        if userSession.isWireDriveEnabled, conversation.isWireDriveEnabled {
            actions.append(
                UIAction(
                    title: L10n.Localizable.Conversation.Action.files,
                    image: UIImage(resource: .files),
                    handler: { [weak self] _ in
                        self?.onFilesButtonPressed(nil)
                    }
                )
            )
        }

        if shouldShowCollectionsButton {
            actions.append(
                UIAction(
                    title: L10n.Localizable.Conversation.Action.search,
                    image: UIImage(systemName: "magnifyingglass"),
                    handler: { [weak self] _ in
                        self?.onSearchButtonPressed(nil)
                    }
                )
            )
        }
        let conversationDetailsAction = UIAction(
            title: L10n.Localizable.Conversation.Action.conversationDetails,
            image: UIImage(systemName: "info.circle"),
            handler: { [weak self] _ in
                self?.onConversationDetailsPressed()
            }
        )
        conversationDetailsAction.accessibilityIdentifier = Locators.ActiveConversationPage.conversationDetailsButton
            .rawValue
        actions.append(conversationDetailsAction)

        let menu = UIMenu(title: "", children: actions)

        titleView.menuProvider = { menu }
    }

    private func setupNavigationItem(isAfterTitleRelatedDataChanged: Bool = false) {
        setupTitleViewTap()

        if conversation.conversationType == .oneOnOne {
            Task { [weak self] in
                guard let self else { return }
                guard let user = conversation.firstActiveParticipantOtherThanSelf else {
                    WireLogger.conversation
                        .error("missing first active participant other then self for 1-1 conversation")
                    return
                }
                let imageSource = await getParticipantImageSourceUseCase
                    .invoke(user: user)
                if isAfterTitleRelatedDataChanged,
                   case .text = imageSource,
                   case .image = titleView.source.accountImageSource {
                    // no need to update because of the way updates come when avatar is changed (in several events)
                    // if we get empty image after update but previously there was an image, we need to skip
                    // so with next update event (which comes right after) we get updated image
                    return
                }
                titleView
                    .updateSource(ConversationTitleSource(
                        accountImageSource: imageSource,
                        title: conversation.displayNameWithFallback,
                        subtitle: Self.getConversationSubtitle(conversation),
                        isMLS: conversation.messageProtocol == .mls,
                        isVerified: conversation.isVerified,
                        isUnderLegalHold: conversation.isUnderLegalHold
                    ))
            }
        } else {
            // no need Image avatar for group chat
            titleView.updateSource(ConversationTitleSource(
                accountImageSource: nil,
                title: conversation.displayNameWithFallback,
                subtitle: Self.getConversationSubtitle(conversation),
                isMLS: conversation.messageProtocol == .mls,
                isVerified: conversation.isVerified,
                isUnderLegalHold: conversation.isUnderLegalHold
            ))
        }

        navigationItem.titleView = titleView
        navigationItem.leftItemsSupplementBackButton = false

        updateRightNavigationItemsButtons()
    }

    static func getConversationSubtitle(_ conversation: ZMConversation) -> String? {
        guard conversation.conversationType == .oneOnOne,
              let user = conversation.firstActiveParticipantOtherThanSelf else {
            return nil
        }
        if user.isExternalPartner {
            return L10n.Localizable.Profile.Details.partner.uppercased()
        } else if user.isFederated {
            return L10n.Localizable.Profile.Details.federated.uppercased()
        } else if user.isGuest(in: conversation) {
            return L10n.Localizable.Profile.Details.guest.uppercased()
        }
        return nil

    }

    // MARK: Resolve 1-1 conversations

    private func resolveConversationIfOneOnOne() {
        guard conversation.conversationType == .oneOnOne,
              conversation.messageProtocol == .proteus
        else {
            return
        }

        guard
            let conversationID = conversation.remoteIdentifier,
            let otherUser = conversation.localParticipants.first(where: { !$0.isSelfUser }),
            let otherUserID = otherUser.qualifiedID,
            let viewContext = conversation.managedObjectContext,
            let syncContext = viewContext.zm_sync
        else {
            WireLogger.conversation.warn(
                "missing expected value to resolve 1-1 conversation!",
                attributes: [.conversationId: conversation.remoteIdentifier ?? "<nil>"]
            )
            return
        }

        Task {
            do {
                let resolvedState = try await userSession.resolveOneOnOneConversation(with: otherUserID)

                if case let .migratedToMLSGroup(identifier) = resolvedState {
                    await navigateToNewMLSConversation(mlsGroupIdentifier: identifier, in: viewContext)
                }
            } catch {
                WireLogger.conversation.warn(
                    "resolution of proteus 1-1 conversation failed: \(error)",
                    attributes: [.senderUserId: otherUserID.safeForLoggingDescription, .conversationId: conversationID]
                )
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
            assertionFailure(
                "conversation with MLSGroupID \(mlsGroupIdentifier) is expected to be always available at this point!"
            )
            return
        }

        await mainCoordinator.showConversation(conversation: mlsConversation, message: nil)
    }

    // MARK: - ParticipantsPopover

    private func hideAndDestroyParticipantsPopover() {
        if (presentedViewController is GroupDetailsViewController) ||
            (presentedViewController is ProfileViewController) {
            dismiss(animated: true)
        }
    }

    // MARK: - Update verification status for MLS groups

    private func updateVerificationStatusIfNeeded() {
        guard
            conversation.conversationType.isOne(of: .group, .oneOnOne),
            conversation.messageProtocol == .mls
        else {
            return
        }

        guard
            let mlsGroupID = conversation.mlsGroupID
        else {
            WireLogger.conversation.warn("missing mlsGroupID to update verification status!")
            return
        }

        Task {
            await userSession.mlsGroupVerification?.updateConversation(conversation, with: mlsGroupID)
            setupNavigationItem()
        }
    }
}

// MARK: - InvisibleInputAccessoryViewDelegate

extension ConversationViewController: InvisibleInputAccessoryViewDelegate {

    // WARNING: DO NOT TOUCH THIS UNLESS YOU KNOW WHAT YOU ARE DOING
    func invisibleInputAccessoryView(
        _ invisibleInputAccessoryView: InvisibleInputAccessoryView,
        superviewFrameChanged frame: CGRect?
    ) {
        // Adjust the input bar distance from bottom based on the invisibleAccessoryView
        var distanceFromBottom: CGFloat = 0

        // On iOS 8, the frame goes to zero when the accessory view is hidden
        if frame?.equalTo(.zero) == false {

            let convertedFrame = view.convert(
                invisibleInputAccessoryView.superview?.frame ?? .zero,
                from: invisibleInputAccessoryView.superview?.superview
            )

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
            contentViewController?.updateTableViewHeaderView()
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
            setupNavigationItem(isAfterTitleRelatedDataChanged: true)
        }

        if note.mlsVerificationStatusChanged {
            setupNavigationItem()
        }
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

    func conversationInsideList(_ list: ConversationList, didChange changeInfo: ConversationChangeInfo) {
        updateLeftNavigationBarItems()
    }
}

// MARK: - UserObserving

extension ConversationViewController: UserObserving {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        if changeInfo.accentColorValueChanged {
            if changeInfo.user.isSelfUser {
                titleView.updateSelfUserAccentColor(changeInfo.user.accentColor)
            } else {
                titleView.updateOtherUserAccentColor(changeInfo.user.accentColor)
            }
        }

        if changeInfo.nameChanged || changeInfo.imageMediumDataChanged ||
            changeInfo.imageSmallProfileDataChanged || changeInfo.teamsChanged {
            setupNavigationItem(isAfterTitleRelatedDataChanged: true)
        }
    }
}

// MARK: - InputBar

extension ConversationViewController: ConversationInputBarViewControllerDelegate {
    func conversationInputBarViewControllerDidComposeText(
        text: String,
        attachments: [MultipartAttachment],
        mentions: [Mention],
        replyingTo message: ZMConversationMessage?
    ) {
        contentViewController?.scrollToBottomIfNeeded()
        inputBarController.sendController.sendTextMessage(
            text,
            attachments: attachments,
            mentions: mentions,
            userSession: userSession,
            replyingTo: message,
        )
    }

    func conversationInputBarViewControllerShouldBeginEditing(_ controller: ConversationInputBarViewController)
        -> Bool {
        let isScrolledToBottom = contentViewController?.isScrolledToBottom ?? false

        if !isScrolledToBottom, !controller.isEditingMessage,
           !controller.isReplyingToMessage {
            collectionController = nil
            contentViewController?.searchQueries = []
            contentViewController?.scrollToBottomIfNeeded()
        }

        return true
    }

    func conversationInputBarViewControllerShouldEndEditing(_ controller: ConversationInputBarViewController) -> Bool {
        true
    }

    func conversationInputBarViewControllerDidFinishEditing(
        _ message: ZMConversationMessage,
        withText newText: String?,
        mentions: [Mention]
    ) {
        contentViewController?.didFinishEditing(message)
        userSession.enqueue {
            if let newText,
               !newText.isEmpty || message.isMultipart {
                let fetchLinkPreview = !Settings.disableLinkPreviews
                message.textMessageData?.editText(newText, mentions: mentions, fetchLinkPreview: fetchLinkPreview)
            } else {
                ZMMessage.deleteForEveryone(message)
            }
        }
    }

    func conversationInputBarViewControllerDidCancelEditing(_ message: ZMConversationMessage) {
        contentViewController?.didFinishEditing(message)
    }

    func conversationInputBarViewControllerWants(toShow message: ZMConversationMessage) {
        contentViewController?.scroll(to: message) { _ in
            self.contentViewController?.highlight(message)
        }
    }

    func conversationInputBarViewControllerEditLastMessage() {
        contentViewController?.editLastMessage()
    }

    func conversationInputBarViewControllerDidComposeDraft(message: DraftMessage) {
        userSession.enqueue {
            // Clear draft if text is empty, otherwise save it
            if message.text.isEmpty {
                self.conversation.draftMessage = nil
            } else {
                self.conversation.draftMessage = message
            }
        }
    }

    @MainActor
    @objc
    private func onConversationDetailsPressed() {
        Task {
            if let superview = titleView.superview, let participantsController = await participantsController {
                presentParticipantsViewController(participantsController, from: superview)
            }
        }
    }

    @objc
    private func onSearchButtonPressed(_ sender: AnyObject?) {
        guard shouldShowCollectionsButton else { return }
        if collectionController == .none {
            let collections = CollectionsViewController(
                conversation: conversation,
                userSession: userSession,
                mainCoordinator: mainCoordinator,
                selfProfileUIBuilder: selfProfileUIBuilder,
                conversationCreationRepository: conversationCreationRepository
            )
            collections.delegate = self

            collections.onDismiss = { [weak self] _ in
                guard let self else { return }
                collectionController?.dismiss(animated: true)
            }
            collectionController = collections
        } else {
            collectionController?.refetchCollection()
        }

        collectionController?.shouldTrackOnNextOpen = true

        let navigationController = KeyboardAvoidingViewController(viewController: collectionController!)
            .wrapInNavigationController()

        navigationController.presentOverAll(animated: true)
    }

    @objc
    func onFilesButtonPressed(_ sender: AnyObject?) {
        let selfUserColorRawValue = userSession.selfUser.accentColorValue

        let filesView = wireMessagingFactory
            .makeFilesView(
                cellName: conversation.wireDriveName,
                isCellsStatePending: wireDriveState == .pending
            ) {
                WireAccentColor(rawValue: selfUserColorRawValue) ?? .default
            }

        filesView.modalPresentationStyle = .fullScreen
        filesView.presentOverAll(animated: true)
    }

    /// If cells state is different than ready we need to sync it when view appears to ensure the value is up to date
    /// as it might have been updated to either a `pending` or `ready` state.
    func syncCellsState() {
        guard wireDriveState != .ready else {
            return
        }

        guard let conversationRepository = userSession.clientSessionComponent?.conversationRepository else {
            return
        }

        let syncCellsStateUseCase = SyncCellsStateUseCase(
            repository: conversationRepository,
            context: userSession.contextProvider.newBackgroundContext(),
            localDomain: userSession.resolvedBackendMetadata.domain
        )

        Task {
            do {
                self.wireDriveState = try await syncCellsStateUseCase.invoke(
                    conversationObjectID: conversation.objectID
                )
            } catch {
                WireLogger.conversation
                    .error("could not sync cells state for conversation: \(String(describing: error))")
            }
        }

    }

}
