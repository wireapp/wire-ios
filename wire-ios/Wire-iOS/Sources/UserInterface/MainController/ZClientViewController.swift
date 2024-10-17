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
import WireAccountImageUI
import WireCommonComponents
import WireDesign
import WireFoundation
import WireMainNavigationUI
import WireSidebarUI
import WireSyncEngine

// TODO: [WPB-11602] after logging in and getting certificate, the account image is blank instead of showing initials

final class ZClientViewController: UIViewController {

    typealias MainCoordinator = WireMainNavigationUI.MainCoordinator<MainCoordinatorDependencies>
    typealias MainSplitViewController = MainCoordinator.SplitViewController
    typealias MainTabBarController = MainCoordinator.TabBarController

    // MARK: - Private Members

    let account: Account
    let userSession: UserSession
    private(set) var cachedAccountImage = UIImage() {
        didSet { sidebarViewController.accountInfo.accountImage = cachedAccountImage }
    }

    private(set) var conversationRootViewController: UIViewController?

    var currentConversation: ZMConversation? {
        conversationListViewController.selectedConversation
    }

    weak var router: AuthenticatedRouterProtocol?

    private lazy var sidebarViewController = SidebarViewControllerBuilder().build()

    private(set) lazy var mainSplitViewController = MainSplitViewController(
        sidebar: sidebarViewController,
        noConversationPlaceholder: NoConversationPlaceholderViewController(),
        tabController: mainTabBarController
    )

    // TODO [WPB-9867]: make private or remove this property
    private(set) var mediaPlaybackManager: MediaPlaybackManager?

    let mainTabBarController = {
        let tabBarController = MainTabBarController()
        tabBarController.applyMainTabBarControllerAppearance()
        return tabBarController
    }()

    private lazy var conversationViewControllerBuilder = ConversationViewControllerBuilder(
        userSession: userSession,
        mediaPlaybackManager: mediaPlaybackManager
    )

    private lazy var settingsViewControllerBuilder = SettingsViewControllerBuilder(userSession: userSession)

    private var selfProfileViewControllerBuilder: SelfProfileViewControllerBuilder {
        .init(
            selfUser: userSession.editableSelfUser,
            userRightInterfaceType: UserRight.self,
            userSession: userSession,
            accountSelector: SessionManager.shared
        )
    }

    private lazy var connectBuilder = StartUIViewControllerBuilder(userSession: userSession)
    private lazy var createGroupConversationBuilder = CreateGroupConversationViewControllerBuilder(userSession: userSession)
    private lazy var userProfileViewControllerBuilder = UserProfileViewControllerBuilder(userSession: userSession)

    private lazy var conversationListViewController = ConversationListViewController(
        account: account,
        selfUserLegalHoldSubject: userSession.selfUserLegalHoldSubject,
        userSession: userSession,
        zClientViewController: self,
        mainCoordinator: .init(mainCoordinator: mainCoordinator),
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

    private(set) lazy var mainCoordinator = MainCoordinator(
        mainSplitViewController: mainSplitViewController,
        mainTabBarController: mainTabBarController,
        conversationUIBuilder: conversationViewControllerBuilder,
        settingsContentUIBuilder: settingsViewControllerBuilder,
        connectUIBuilder: connectBuilder,
        createGroupConversationUIBuilder: createGroupConversationBuilder,
        selfProfileUIBuilder: selfProfileViewControllerBuilder,
        userProfileUIBuilder: userProfileViewControllerBuilder
    )

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

        setupSplitViewController()

        // TODO: [WPB-11609] fix if needed
        // attemptToPresentInitialConversation()

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // in expanded layout we want to see the same background color of the
        // sidebar also for the status bar
        if mainSplitViewController.isCollapsed {
            view.backgroundColor = ColorTheme.Backgrounds.surface
        } else {
            view.backgroundColor = SidebarViewDesign().backgroundColor
        }
    }

    private func setupSplitViewController() {
        let archiveUI = ArchivedListViewController(userSession: userSession)

        // TODO: [WPB-11608] the border color doesn't match on iPad (iOS 15)
        mainSplitViewController.borderColor = ColorTheme.Strokes.outline
        mainSplitViewController.conversationListUI = conversationListViewController

        mainTabBarController.archiveUI = archiveUI
        mainTabBarController.settingsUI = settingsViewControllerBuilder
            .build(mainCoordinator: mainCoordinator)

        mainTabBarController.delegate = mainCoordinator
        mainSplitViewController.delegate = mainCoordinator
        archiveUI.delegate = mainCoordinator
        userProfileViewControllerBuilder.delegate = mainCoordinator
        connectBuilder.delegate = mainCoordinator
        createGroupConversationBuilder.delegate = mainCoordinator

        addChild(mainSplitViewController)
        mainSplitViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainSplitViewController.view)
        mainSplitViewController.didMove(toParent: self)

        createTopViewConstraints()

        sidebarViewController.accountInfo = .init(userSession.selfUser, cachedAccountImage)
        sidebarViewController.wireAccentColor = .init(rawValue: userSession.selfUser.accentColorValue) ?? .default
        sidebarViewController.delegate = mainCoordinator

        // prevent split view appearance on large phones
        if traitCollection.userInterfaceIdiom != .pad {
            if #available(iOS 17.0, *) {
                mainSplitViewController.traitOverrides.horizontalSizeClass = .compact
            } else {
                setOverrideTraitCollection(.init(horizontalSizeClass: .compact), forChild: mainSplitViewController)
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
            await mainCoordinator.showConnect()
        }
    }

    // MARK: Status bar
    private var child: UIViewController? {
        return topOverlayViewController ?? mainSplitViewController
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

        mainSplitViewController.show(.primary)
    }

    func loadIncomingContactRequestsAndFocus(onView focus: Bool, animated: Bool) {
        // TODO: [WPB-11620] check if this flow works
        let connectRequests = ConnectRequestsViewController(userSession: userSession)
        let navigationController = UINavigationController(rootViewController: connectRequests)
        Task {
            await mainCoordinator.presentViewController(navigationController)
        }
    }

    /// Open the user clients detail screen
    ///
    /// - Parameter conversation: conversation to open
    func openDetailScreen(for conversation: ZMConversation) {
        let controller = GroupDetailsViewController(
            conversation: conversation,
            userSession: userSession,
            mainCoordinator: .init(mainCoordinator: mainCoordinator),
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
            if let rightViewController = self.mainSplitViewController.viewController(for: .secondary),
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

        Task {
            await mainCoordinator.showConversation(conversation: currentConversation, message: nil)
        }
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
        // TODO: [WPB-11609] check if needed

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
            // selectListItemWhenNoPreviousItemSelected()
            return false
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

    func transitionToList(animated: Bool,
                          leftViewControllerRevealed: Bool = true,
                          completion: Completion?) {
        Task {
            let currentFilter = conversationListViewController.conversationFilter
            await mainCoordinator.showConversationList(conversationFilter: currentFilter)
            completion?()
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
            mainSplitViewController.view.topAnchor.constraint(equalTo: topOverlayContainer.bottomAnchor),
            mainSplitViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mainSplitViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainSplitViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let heightConstraint = topOverlayContainer.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = UILayoutPriority.defaultLow
        heightConstraint.isActive = true
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if mainSplitViewController.isCollapsed {
            view.backgroundColor = ColorTheme.Backgrounds.surface
        } else {
            view.backgroundColor = SidebarViewDesign().backgroundColor
        }
    }

    /// Open the user client list screen
    ///
    /// - Parameter user: the UserType with client list to show

    func openClientListScreen(for user: UserType) { // TODO: [WPB-11614] use mainCoordinator if possible
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
        // TODO: [WPB-11620] check if the conversation is opened, e.g. after accepting a connection request
        dismissAllModalControllers { [weak self] in
            guard
                let self,
                !conversation.isDeleted,
                conversation.managedObjectContext != nil
            else { return }

            Task {
                await self.mainCoordinator.dismissPresentedViewController()
                self.conversationListViewController.viewModel.select(conversation: conversation, scrollTo: message, focusOnView: focus, animated: animated)
            }
        }
    }

    func select(conversation: ZMConversation) {
        conversationListViewController.viewModel.select(conversation: conversation)
    }

    var isConversationViewVisible: Bool {
        mainCoordinator.isConversationVisible
    }

    var isConversationListVisible: Bool {
        mainCoordinator.isConversationListVisible
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
                let selfUser = userSession.selfUser
                sidebarViewController.accountInfo = .init(selfUser, cachedAccountImage)
                sidebarViewController.wireAccentColor = .init(rawValue: selfUser.accentColorValue) ?? .default
            }
        }
    }

    @objc func setupUserChangeInfoObserver() {
        userObserverToken = userSession.addUserObserver(self, for: userSession.selfUser)
    }
}
