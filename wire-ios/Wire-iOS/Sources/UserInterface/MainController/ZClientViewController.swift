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

import avs
import SwiftUI
import UIKit
import WireAccountImage
import WireCommonComponents
import WireDesign
import WireSidebar
import WireSyncEngine
import WireUIFoundation

final class ZClientViewController: UIViewController {

    // MARK: - Private Members

    let account: Account
    let userSession: UserSession
    private(set) var cachedAccountImage = UIImage() {
        didSet { sidebarViewController.accountInfo.accountImage = cachedAccountImage }
    }

    private(set) var conversationRootViewController: UIViewController?
    // TODO [WPB-8778]: Check if this property is still needed
    private(set) var currentConversation: ZMConversation?

    weak var router: AuthenticatedRouterProtocol?

    let sidebarViewController = {
        let sidebarViewController = SidebarViewController { accountImage, availability in
            AnyView(AccountImageViewRepresentable(accountImage: accountImage, availability: availability?.map()))
        }
        sidebarViewController.wireTextStyleMapping = .init()
        return sidebarViewController
    }()

    private(set) lazy var wireSplitViewController = MainSplitViewController<SidebarViewController, ConversationListViewController>(
        sidebar: sidebarViewController,
        noConversationPlaceholder: NoConversationPlaceholderViewController(),
        tabContainer: mainTabBarController
    )

    // TODO [WPB-9867]: make private or remove this property
    private(set) var mediaPlaybackManager: MediaPlaybackManager?

    let mainTabBarController = {
        let tabBarController = MainTabBarController<ConversationListViewController>()
        tabBarController.applyMainTabBarControllerAppearance()
        return tabBarController
    }()

    private var selfProfileViewControllerBuilder: SelfProfileViewControllerBuilder {
        .init(
            selfUser: userSession.editableSelfUser,
            userRightInterfaceType: UserRight.self,
            userSession: userSession,
            accountSelector: SessionManager.shared
        )
    }
    private lazy var conversationListViewController = ConversationListViewController(
        account: account,
        selfUserLegalHoldSubject: userSession.selfUserLegalHoldSubject,
        userSession: userSession,
        zClientViewController: self,
        mainCoordinator: mainCoordinator,
        isSelfUserE2EICertifiedUseCase: userSession.isSelfUserE2EICertifiedUseCase,
        selfProfileViewControllerBuilder: selfProfileViewControllerBuilder
    )

    var proximityMonitorManager: ProximityMonitorManager?
    var legalHoldDisclosureController: LegalHoldDisclosureController?

    var userObserverToken: NSObjectProtocol?
    var conferenceCallingUnavailableObserverToken: Any?

    private let topOverlayContainer = UIView()
    private var topOverlayViewController: UIViewController?

    private let colorSchemeController: ColorSchemeController
    private var incomingApnsObserver: NSObjectProtocol?
    private var networkAvailabilityObserverToken: NSObjectProtocol?

    private(set) lazy var mainCoordinator = {
        var newConversationBuilder = StartUIViewControllerBuilder(userSession: userSession)
        let mainCoordinator = MainCoordinator(
            mainSplitViewController: wireSplitViewController,
            mainTabBarController: mainTabBarController,
            newConversationBuilder: newConversationBuilder,
            selfProfileBuilder: selfProfileViewControllerBuilder
        )
        newConversationBuilder.delegate = mainCoordinator
        return mainCoordinator
    }()

    /// init method for testing allows injecting an Account object and self user
    required init(
        account: Account,
        userSession: UserSession
    ) {
        self.account = account
        self.userSession = userSession

        colorSchemeController = .init(userSession: userSession)

        super.init(nibName: nil, bundle: nil)

        proximityMonitorManager = ProximityMonitorManager()
        mediaPlaybackManager = MediaPlaybackManager(name: "conversationMedia", userSession: userSession)

        AVSMediaManager.sharedInstance().register(mediaPlaybackManager, withOptions: ["media": "external "])

        if let appGroupIdentifier = Bundle.main.appGroupIdentifier,
           let remoteIdentifier = userSession.selfUser.remoteIdentifier {
            let sharedContainerURL = FileManager.sharedContainerDirectory(for: appGroupIdentifier)

            _ = sharedContainerURL.appendingPathComponent("AccountData", isDirectory: true).appendingPathComponent(remoteIdentifier.uuidString, isDirectory: true)
        }

        NotificationCenter.default.post(name: NSNotification.Name.ZMUserSessionDidBecomeAvailable, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)

        NotificationCenter.default.addObserver(forName: .featureDidChangeNotification, object: nil, queue: .main) { [weak self] note in
            guard let change = note.object as? FeatureRepository.FeatureChange else { return }

            switch change {
            case .conferenceCallingIsAvailable:
                guard let session = SessionManager.shared,
                      session.usePackagingFeatureConfig else { break }
                self?.presentConferenceCallingAvailableAlert()

            default:
                break
            }
        }

        setupAppearance()
        createLegalHoldDisclosureController()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        AVSMediaManager.sharedInstance().unregisterMedia(mediaPlaybackManager)
    }

    private func restoreStartupState() {
        attemptToPresentInitialConversation()
    }

    @discardableResult
    private func attemptToPresentInitialConversation() -> Bool {
        var stateRestored = false

        let lastViewedScreen: SettingsLastScreen? = Settings.shared[.lastViewedScreen]
        switch lastViewedScreen {
        case .list?:

            transitionToList(animated: false, completion: nil)

            // only attempt to show content vc if it would be visible
            if isConversationViewVisible {
                stateRestored = attemptToLoadLastViewedConversation(withFocus: false, animated: false)
            }
        case .conversation?:
            stateRestored = attemptToLoadLastViewedConversation(withFocus: true, animated: false)
        default:
            break
        }
        return stateRestored
    }

    // MARK: - Overloaded methods

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorTheme.Backgrounds.surface

        setupSplitViewController()

        // TODO: enable
        // restoreStartupState()

        if Bundle.developerModeEnabled {
            // better way of dealing with this?
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(requestLoopNotification(_:)),
                name: .loggingRequestLoop,
                object: nil
            )
        }

        setupUserChangeInfoObserver()
        setUpConferenceCallingUnavailableObserver()
    }

    private func setupSplitViewController() {

        mainTabBarController.archive = ArchivedConversationsViewControllerBuilder(userSession: userSession).build()
        mainTabBarController.settings = SettingsMainViewControllerBuilder(userSession: userSession, selfUser: userSession.editableSelfUser).build()

        wireSplitViewController.conversationList = conversationListViewController
        wireSplitViewController.delegate = mainCoordinator

        addChild(wireSplitViewController)
        wireSplitViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(wireSplitViewController.view)
        wireSplitViewController.didMove(toParent: self)

        createTopViewConstraints()

        sidebarViewController.accountInfo = .init(userSession.selfUser, cachedAccountImage)
        sidebarViewController.delegate = mainCoordinator

        // prevent split view appearance on large phones
        if traitCollection.userInterfaceIdiom != .pad {
            if #available(iOS 17.0, *) {
                wireSplitViewController.traitOverrides.horizontalSizeClass = .compact
            } else {
                setOverrideTraitCollection(.init(horizontalSizeClass: .compact), forChild: wireSplitViewController)
            }
        }

        Task {
            do {
                cachedAccountImage = try await GetUserAccountImageUseCase().invoke(account: account)
            } catch {
                WireLogger.ui.error("Failed to update user's account image: \(String(reflecting: error))")
            }
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    override var shouldAutorotate: Bool {
        return presentedViewController?.shouldAutorotate ?? true
    }

    // MARK: keyboard shortcut
    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(
                action: #selector(openStartUI(_:)),
                input: "n",
                modifierFlags: [.command],
                discoverabilityTitle: L10n.Localizable.Keyboardshortcut.openPeople
            )
        ]
    }

    @objc
    private func openStartUI(_ sender: Any?) {
        Task {
            await mainCoordinator.showNewConversation()
        }
    }

    // MARK: Status bar
    private var child: UIViewController? {
        return topOverlayViewController ?? wireSplitViewController
    }

    private var childForStatusBar: UIViewController? {
        // For iPad regular mode, there is a black bar area and we always use light style and non hidden status bar
        return isIPadRegular() ? nil : child
    }

    override var childForStatusBarStyle: UIViewController? {
        return childForStatusBar
    }

    override var childForStatusBarHidden: UIViewController? {
        return childForStatusBar
    }

    // MARK: trait

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // TODO: check if still needed
        // if changing from compact width to regular width, make sure current conversation is loaded
        if false, previousTraitCollection?.horizontalSizeClass == .compact && traitCollection.horizontalSizeClass == .regular {
            if let currentConversation {
                select(conversation: currentConversation)
            } else {
                attemptToLoadLastViewedConversation(withFocus: false, animated: false)
            }
        }

        view.setNeedsLayout()
    }

    // MARK: - Singleton

    @available(*, deprecated, message: "Please don't access this property, it will be deleted.")
    static var shared: ZClientViewController? {
        return (UIApplication.shared.delegate as? AppDelegate)?.appRootRouter?.zClientViewController
    }

    /// Select the connection inbox and optionally move focus to it.
    ///
    /// - Parameter focus: focus or not
    func selectIncomingContactRequestsAndFocus(onView focus: Bool) {
        mainTabBarController.selectedIndex = MainTabBarControllerContent.conversations.rawValue
        conversationListViewController.selectInboxAndFocusOnView(focus: focus)
    }

    /// Exit the connection inbox.  This contains special logic for reselecting another conversation etc when you
    /// have no more connection requests.
    func hideIncomingContactRequests() {
        let conversationsList = userSession.conversationList()
        if let conversation = conversationsList.items.first {
            select(conversation: conversation)
        }

        wireSplitViewController.show(.primary)
    }

    private func pushContentViewController(
        _ viewController: UIViewController? = nil,
        focusOnView focus: Bool = false,
        animated: Bool = false,
        completion: Completion? = nil
    ) {
        // TODO: `focus` argument is not used
        conversationRootViewController = viewController
        let secondaryNavigationController = wireSplitViewController.viewController(for: .secondary) as! UINavigationController
        secondaryNavigationController.setViewControllers([conversationRootViewController!], animated: false)
    }

    func loadPlaceholderConversationController(animated: Bool) {
        currentConversation = nil
        pushContentViewController(focusOnView: false, animated: animated)
    }

    /// Load and optionally show a conversation, but don't change the list selection.  This is the place to put
    /// stuff if you definitely need it to happen when a conversation is selected and/or presented
    ///
    /// This method should only be called when the list selection changes, or internally by other zclientviewcontroller
    ///
    /// - Parameters:
    ///   - conversation: conversation to load
    ///   - message: scroll to a specific message
    ///   - focus: focus on view or not
    ///   - animated: animated or not
    ///   - completion: optional completion handler
    func load(
        _ conversation: ZMConversation,
        scrollTo message: ZMConversationMessage?,
        focusOnView focus: Bool,
        animated: Bool
    ) {
        var conversationRootController: ConversationRootViewController?
        if conversation === currentConversation,
           conversationRootController != nil {
            if let message {
                conversationRootController?.scroll(to: message)
            }
        } else {
            conversationRootController = ConversationRootViewController(
                conversation: conversation,
                message: message,
                userSession: userSession,
                mainCoordinator: mainCoordinator,
                mediaPlaybackManager: mediaPlaybackManager
            )
        }

        currentConversation = conversation
        conversationRootController?.conversationViewController?.isFocused = focus

        pushContentViewController(conversationRootController, focusOnView: focus, animated: animated)
    }

    func loadIncomingContactRequestsAndFocus(onView focus: Bool, animated: Bool) {
        currentConversation = nil

        let inbox = ConnectRequestsViewController(userSession: userSession)
        pushContentViewController(inbox.wrapInNavigationController(), focusOnView: focus, animated: animated)
    }

    /// Open the user clients detail screen
    ///
    /// - Parameter conversation: conversation to open
    func openDetailScreen(for conversation: ZMConversation) {
        let controller = GroupDetailsViewController(
            conversation: conversation,
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            isUserE2EICertifiedUseCase: userSession.isUserE2EICertifiedUseCase
        )
        let navController = controller.wrapInNavigationController()
        navController.modalPresentationStyle = .formSheet

        present(navController, animated: true)
    }

    @objc
    private func dismissClientListController(_ sender: Any?) {
        dismiss(animated: true)
    }

    // MARK: - Animated conversation switch
    func dismissAllModalControllers(callback: Completion?) {
        let dismissAction = {
            if let rightViewController = self.wireSplitViewController.viewController(for: .secondary),
               rightViewController.presentedViewController != nil {
                rightViewController.dismiss(animated: false, completion: callback)
            } else if let presentedViewController = self.conversationListViewController.presentedViewController {
                // This is a workaround around the fact that the transitioningDelegate of the settings
                // view controller is not called when the transition is not being performed animated.
                // This sounds like a bug in UIKit (Radar incoming) as I would expect the custom animator
                // being called with `transitionContext.isAnimated == false`. As this is not the case
                // we have to restore the proper pre-presentation state here.
                let conversationView = self.conversationListViewController.view
                if let transform = conversationView?.layer.transform {
                    if !CATransform3DIsIdentity(transform) || conversationView?.alpha != 1 {
                        conversationView?.layer.transform = CATransform3DIdentity
                        conversationView?.alpha = 1
                    }
                }

                presentedViewController.dismiss(animated: true, completion: callback)
            } else if self.presentedViewController != nil {
                self.dismiss(animated: false, completion: callback)
            } else {
                callback?()
            }
        }

        if userSession.ringingCallConversation != nil {
            dismissAction()
        } else {
            minimizeCallOverlay(animated: true, completion: dismissAction)
        }
    }

    // MARK: - ColorSchemeControllerDidApplyChangesNotification

    private func reloadCurrentConversation() {
        guard let currentConversation else { return }

        let currentConversationViewController = ConversationRootViewController(
            conversation: currentConversation,
            message: nil,
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            mediaPlaybackManager: mediaPlaybackManager
        )

        // Need to reload conversation to apply color scheme changes
        pushContentViewController(currentConversationViewController)
    }

    // MARK: - Debug logging notifications

    @objc
    private func requestLoopNotification(_ notification: Notification?) {
        guard let path = notification?.userInfo?["path"] as? String else { return }

        var presentingViewController = self as UIViewController
        while let presentedViewController = presentingViewController.presentedViewController {
            presentingViewController = presentedViewController
        }

        DebugAlert.showSendLogsMessage(
            message: "A request loop is going on at \(path)",
            presentingViewController: presentingViewController,
            fallbackActivityPopoverConfiguration: .sourceView(
                presentingViewController.view,
                .init(origin: presentingViewController.view.center, size: .zero)
            )
        )
    }

    /// Attempt to load the last viewed conversation associated with the current account.
    /// If no info is available, we attempt to load the first conversation in the list.
    ///
    /// - Returns: In the first case, YES is returned, otherwise NO.
    @discardableResult
    private func attemptToLoadLastViewedConversation(withFocus focus: Bool, animated: Bool) -> Bool {

        if let currentAccount = SessionManager.shared?.accountManager.selectedAccount {
            if let conversation = Settings.shared.lastViewedConversation(for: currentAccount) {
                select(conversation: conversation, focusOnView: focus, animated: animated)
            }

            // dispatch async here because it has to happen after the collection view has finished
            // laying out for the first time
            DispatchQueue.main.async {
                self.conversationListViewController.scrollToCurrentSelection(animated: false)
            }

            return true

        } else {
            selectListItemWhenNoPreviousItemSelected()
            return false
        }
    }

    /**
     * This handles the case where we have to select a list item on startup but there is no previous item saved
     */
    func selectListItemWhenNoPreviousItemSelected() {
        // check for conversations and pick the first one.. this can be tricky if there are pending updates and
        // we haven't synced yet, but for now we just pick the current first item
        let list = userSession.conversationList().items

        if let conversation = list.first {
            // select the first conversation and don't focus on it
            select(conversation: conversation)
        } else {
            loadPlaceholderConversationController(animated: true)
        }
    }

    @objc
    func contentSizeCategoryDidChange(_ notification: Notification?) {
        reloadCurrentConversation()
    }

    private func setupAppearance() {

        let labelColor: UIColor
        labelColor = .label

        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = labelColor
    }

    // MARK: - Setup methods

    func transitionToList(animated: Bool, completion: Completion?) {
        transitionToList(animated: animated,
                         leftViewControllerRevealed: true,
                         completion: completion)
    }

    func transitionToList(animated: Bool,
                          leftViewControllerRevealed: Bool = true,
                          completion: Completion?) {
        let action: Completion = { [weak self] in
            self?.wireSplitViewController.show(leftViewControllerRevealed ? .primary : .secondary)
            completion?()
        }

        if let presentedViewController = wireSplitViewController.viewController(for: .secondary)?.presentedViewController {
            presentedViewController.dismiss(animated: animated, completion: action)
        } else {
            action()
        }

    }

    func setTopOverlay(to viewController: UIViewController?, animated: Bool = true) {
        topOverlayViewController?.willMove(toParent: nil)

        if let previousViewController = topOverlayViewController, let viewController {
            addChild(viewController)
            viewController.view.frame = topOverlayContainer.bounds
            viewController.view.translatesAutoresizingMaskIntoConstraints = false

            if animated {
                transition(from: previousViewController,
                           to: viewController,
                           duration: 0.5,
                           options: .transitionCrossDissolve,
                           animations: { viewController.view.fitIn(view: self.view) },
                           completion: { _ in
                    viewController.didMove(toParent: self)
                    previousViewController.removeFromParent()
                    self.topOverlayViewController = viewController
                })
            } else {
                topOverlayContainer.addSubview(viewController.view)
                viewController.view.fitIn(view: topOverlayContainer)
                viewController.didMove(toParent: self)
                topOverlayViewController = viewController
            }
        } else if let previousViewController = topOverlayViewController {
            if animated {
                let heightConstraint = topOverlayContainer.heightAnchor.constraint(equalToConstant: 0)

                UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
                    heightConstraint.isActive = true

                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                }, completion: { _ in
                    heightConstraint.isActive = false

                    self.topOverlayViewController?.removeFromParent()
                    previousViewController.view.removeFromSuperview()
                    self.topOverlayViewController = nil
                })
            } else {
                self.topOverlayViewController?.removeFromParent()
                previousViewController.view.removeFromSuperview()
                self.topOverlayViewController = nil
            }
        } else if let viewController {
            addChild(viewController)
            viewController.view.frame = topOverlayContainer.bounds
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            topOverlayContainer.addSubview(viewController.view)
            viewController.view.fitIn(view: topOverlayContainer)

            viewController.didMove(toParent: self)

            let isRegularContainer = traitCollection.horizontalSizeClass == .regular

            if animated && !isRegularContainer {
                let heightConstraint = viewController.view.heightAnchor.constraint(equalToConstant: 0)
                heightConstraint.isActive = true

                self.topOverlayViewController = viewController

                UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                    heightConstraint.isActive = false
                    self.view.layoutIfNeeded()
                })
            } else {
                topOverlayViewController = viewController
            }
        }
    }

    private func createLegalHoldDisclosureController() {
        legalHoldDisclosureController = LegalHoldDisclosureController(
            selfUserLegalHoldSubject: userSession.selfUserLegalHoldSubject,
            userSession: userSession,
            presenter: { viewController, animated, completion in
                viewController.presentTopmost(animated: animated, completion: completion)
            })
    }

    private func createTopViewConstraints() {

        topOverlayContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topOverlayContainer)

        NSLayoutConstraint.activate([
            topOverlayContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topOverlayContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topOverlayContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            wireSplitViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            wireSplitViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            wireSplitViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wireSplitViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let heightConstraint = topOverlayContainer.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = UILayoutPriority.defaultLow
        heightConstraint.isActive = true
    }

    /// Open the user client list screen
    ///
    /// - Parameter user: the UserType with client list to show

    func openClientListScreen(for user: UserType) {
        var viewController: UIViewController?

        if user.isSelfUser, let clients = user.allClients as? [UserClient] {
            let clientListViewController = ClientListViewController(clientsList: clients, credentials: nil, detailedView: true, showTemporary: true)
            clientListViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissClientListController(_:)))
            viewController = clientListViewController
        } else {
            guard let selfUser = ZMUser.selfUser() else {
                assertionFailure("ZMUser.selfUser() is nil")
                return
            }

            let profileViewController = ProfileViewController(
                user: user,
                viewer: selfUser,
                context: .deviceList,
                userSession: userSession,
                mainCoordinator: mainCoordinator
            )

            if let conversationViewController = (conversationRootViewController as? ConversationRootViewController)?.conversationViewController {
                profileViewController.delegate = conversationViewController

                profileViewController.viewControllerDismisser = conversationViewController
            }
            viewController = profileViewController
        }

        let navWrapperController: UINavigationController? = viewController?.wrapInNavigationController()
        navWrapperController?.modalPresentationStyle = .formSheet
        if let aController = navWrapperController {
            present(aController, animated: true)
        }
    }

    func showConversationList() {
        transitionToList(animated: true, completion: nil)
    }

    // MARK: - Select conversation

    /// Select a conversation and move the focus to the conversation view.
    ///
    /// - Parameters:
    ///   - conversation: the conversation to select
    ///   - message: scroll to  this message
    ///   - focus: focus on the view or not
    ///   - animated: perform animation or not
    func select(
        conversation: ZMConversation,
        scrollTo message: ZMConversationMessage? = nil,
        focusOnView focus: Bool,
        animated: Bool
    ) {
        dismissAllModalControllers { [weak self] in
            guard
                let self,
                !conversation.isDeleted,
                conversation.managedObjectContext != nil
            else { return }

            conversationListViewController.viewModel.select(conversation: conversation, scrollTo: message, focusOnView: focus, animated: animated)
        }
    }

    func select(conversation: ZMConversation) {
        conversationListViewController.viewModel.select(conversation: conversation)
    }

    var isConversationViewVisible: Bool {
        // TODO: fix
        false
        // wireSplitViewController.isConversationViewVisible
    }

    var isConversationListVisible: Bool {
        // TODO: fix
        return false
        // return (wireSplitViewController.layoutSize == .regularLandscape) ||
        // (wireSplitViewController.isLeftViewControllerRevealed && conversationListViewController.presentedViewController == nil)
    }

    func minimizeCallOverlay(
        animated: Bool,
        completion: Completion?
    ) {
        router?.minimizeCallOverlay(animated: animated, completion: completion)
    }
}

// MARK: - ZClientViewController + UserObserving

extension ZClientViewController: UserObserving {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        Task { @MainActor [self] in

            var sidebarUpdateNeeded = false

            if changeInfo.nameChanged || changeInfo.availabilityChanged {
                sidebarUpdateNeeded = true
            }

            if changeInfo.accentColorValueChanged {
                sidebarUpdateNeeded = true
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.mainWindow?.tintColor = UIColor.accent()
            }

            if changeInfo.imageMediumDataChanged || changeInfo.imageSmallProfileDataChanged {
                sidebarUpdateNeeded = true
                do {
                    cachedAccountImage = try await GetUserAccountImageUseCase().invoke(account: account)
                } catch {
                    WireLogger.ui.error("Failed to update user's account image: \(String(reflecting: error))")
                }
            }

            if sidebarUpdateNeeded {
                sidebarViewController.accountInfo = .init(userSession.selfUser, cachedAccountImage)
            }
        }
    }

    @objc func setupUserChangeInfoObserver() {
        userObserverToken = userSession.addUserObserver(self, for: userSession.selfUser)
    }
}
