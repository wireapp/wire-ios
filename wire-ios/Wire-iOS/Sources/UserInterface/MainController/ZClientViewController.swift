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

import avs
import Combine
import SwiftUI
import UIKit
import WireAccountImageUI
import WireCallingAssembly
import WireCommonComponents
import WireDesign
import WireFoundation
import WireLogging
import WireMainNavigationUI
import WireMessagingAssembly
import WireMessagingDomain
import WireMessagingUI
import WireNetwork
import WireSidebarUI
import WireSyncEngine
import WireUtilities

final class ZClientViewController: UIViewController {

    typealias MainCoordinator = WireMainNavigationUI.MainCoordinator<MainCoordinatorDependencies>

    // MARK: - Private Members - Add wire cells factory here somehow

    let account: Account
    let userSession: UserSession
    let trackingManager: TrackingManager?
    private let selfProfileViewsMonitor: SelfProfileViewsMonitor
    private(set) var cachedAccountImage = SidebarAccountInfo.AccountImageSource() {
        didSet {
            sidebarViewController.accountInfo.accountImageSource = cachedAccountImage
        }
    }

    private(set) var cachedAccountInfo = SidebarAccountInfo() {
        didSet { sidebarViewController.accountInfo = cachedAccountInfo }
    }

    private(set) var conversationRootViewController: UIViewController?

    private lazy var conversationFilterSelector = ConversationFilterSelector(
        conversationFilter: { [weak conversationListViewController] in
            conversationListViewController?.conversationFilter
        },
        updateConversationFilter: { [weak mainCoordinator] filter in
            mainCoordinator?.applyConversationFilter(filter)
        }
    )

    var currentConversation: ZMConversation? {
        conversationListViewController.selectedConversation
    }

    weak var router: AuthenticatedRouterProtocol?

    private lazy var sidebarViewController = SidebarViewControllerBuilder().build(
        isWireCellsEnabled: userSession.isWireCellsEnabled
    )

    private lazy var sidebarViewControllerDelegate = SidebarViewControllerDelegate(
        mainCoordinator: .init(mainCoordinator: mainCoordinator),
        connectUIBuilder: connectBuilder,
        selfProfileUIBuilder: selfProfileViewControllerBuilder,
        folderPickerViewControllerBuilder: folderPickerViewControllerBuilder,
        analyticsEventTracker: { [weak userSession] in userSession?.analyticsEventTracker }
    )

    private(set) lazy var mainSplitViewController = MainCoordinator.SplitViewController(
        sidebar: sidebarViewController,
        noConversationPlaceholder: NoConversationPlaceholderViewController(),
        tabController: mainTabBarController
    )

    // TODO: [WPB-9867]: make private or remove this property
    private(set) var mediaPlaybackManager: MediaPlaybackManager?

    lazy var mainTabBarController = {
        let tabBarController = MainCoordinator.TabBarController(
            showMeetings: DeveloperFlag.wireMeetings.isOn,
            showFiles: userSession.isWireCellsEnabled
        )
        tabBarController.applyMainTabBarControllerAppearance()
        return tabBarController
    }()

    private lazy var conversationViewControllerBuilder = ConversationViewControllerBuilder(
        userSession: userSession,
        selfProfileUIBuilder: selfProfileViewControllerBuilder,
        mediaPlaybackManager: mediaPlaybackManager,
        wireMessagingFactory: wireMessagingFactory
    )

    private lazy var channelConversationFormFactory = WireConversationChannelCreationFormViewControllerFactory()

    private lazy var settingsViewControllerBuilder = SettingsViewControllerBuilder(
        userSession: userSession,
        trackingManager: trackingManager
    )

    private lazy var defaultSettingsPropertyFactoryDelegate = {
        var settingsTableViewController = { [weak self] in
            self?.mainSplitViewController.settingsContentUI as? SettingsTableViewController ??
                self?.mainTabBarController.settingsContentUI as? SettingsTableViewController ??
                self?.mainSplitViewController.settingsUI as? SettingsTableViewController ??
                self?.mainTabBarController.settingsUI as? SettingsTableViewController
        }

        return DefaultSettingsPropertyFactoryDelegate(
            userSession: userSession,
            settingsTableViewController: settingsTableViewController,
            mainCoordinator: AnyMainCoordinator(mainCoordinator: mainCoordinator)
        )
    }()

    private(set) lazy var selfProfileViewControllerBuilder = SelfProfileViewControllerBuilder(
        selfUser: userSession.editableSelfUser,
        userRightInterfaceType: UserRight.self,
        userSession: userSession,
        accountSelector: SessionManager.shared,
        analyticsEventTracker: { [weak userSession] in userSession?.analyticsEventTracker }
    )

    private lazy var connectBuilder = StartUIViewControllerBuilder(
        userSession: userSession,
        mainCoordinator: .init(mainCoordinator: mainCoordinator),
        createGroupConversationUIBuilder: createGroupConversationBuilder,
        channelConversationFormFactory: channelConversationFormFactory,
        selfProfileUIBuilder: selfProfileViewControllerBuilder
    )

    private lazy var createGroupConversationBuilder = CreateGroupConversationViewControllerBuilder(
        userSession: userSession
    )

    private lazy var folderPickerViewControllerBuilder = FolderPickerViewControllerBuilder(
        conversationDirectory: userSession.conversationDirectory,
        conversationFilter: { [weak self] in
            self?.conversationFilter()
        }
    )

    private(set) lazy var conversationListViewController = ConversationListViewController(
        account: account,
        selfUserLegalHoldSubject: userSession.selfUserLegalHoldSubject,
        userSession: userSession,
        zClientViewController: self,
        mainCoordinator: .init(mainCoordinator: mainCoordinator),
        isSelfUserE2EICertifiedUseCase: userSession.isSelfUserE2EICertifiedUseCase,
        connectViewControllerBuilder: connectBuilder,
        selfProfileViewControllerBuilder: selfProfileViewControllerBuilder,
        createGroupConversationViewControllerBuilder: createGroupConversationBuilder,
        folderPickerViewControllerBuilder: folderPickerViewControllerBuilder,
        getUserAccountImageSourceUseCase: GetUserAccountImageSourceUseCase()
    )

    var proximityMonitorManager: ProximityMonitorManager?
    var legalHoldDisclosureController: LegalHoldDisclosureController?

    var userObserverToken: NSObjectProtocol?
    var conferenceCallingUnavailableObserverToken: Any?
    var userDidViewSelfProfileToken: SelfUnregisteringNotificationCenterToken?
    private var subscription: AnyCancellable?

    private let topOverlayContainer = UIView()
    private var topOverlayViewController: UIViewController?

    private let colorSchemeController: ColorSchemeController
    private var incomingApnsObserver: NSObjectProtocol?
    private var networkAvailabilityObserverToken: NSObjectProtocol?
    private var featureChangeObserverToken: SelfUnregisteringNotificationCenterToken?
    private var userDefaultsObservation: NSKeyValueObservation?
    private var loggingRequestLoopObserverToken: SelfUnregisteringNotificationCenterToken?
    private let wireMeetingsFactory: any WireMeetingsFactoryProtocol
    let wireMessagingFactory: any WireMessagingFactoryProtocol

    private(set) lazy var mainCoordinator = MainCoordinator(
        mainSplitViewController: mainSplitViewController,
        mainTabBarController: mainTabBarController,
        conversationUIBuilder: conversationViewControllerBuilder,
        settingsContentUIBuilder: settingsViewControllerBuilder
    )

    /// init method for testing allows injecting an Account object and self user
    required init(
        account: Account,
        selfProfileViewsMonitor: SelfProfileViewsMonitor,
        userSession: UserSession,
        trackingManager: TrackingManager?,
        wireMeetingsFactory: any WireMeetingsFactoryProtocol,
        wireMessagingFactory: any WireMessagingFactoryProtocol
    ) {
        self.account = account
        self.selfProfileViewsMonitor = selfProfileViewsMonitor
        self.userSession = userSession
        self.trackingManager = trackingManager
        self.colorSchemeController = .init(userSession: userSession)

        self.wireMeetingsFactory = wireMeetingsFactory
        self.wireMessagingFactory = wireMessagingFactory

        super.init(nibName: nil, bundle: nil)

        self.proximityMonitorManager = ProximityMonitorManager()
        self.mediaPlaybackManager = MediaPlaybackManager(name: "conversationMedia", userSession: userSession)

        AVSMediaManager.sharedInstance().register(mediaPlaybackManager, withOptions: ["media": "external "])

        if let appGroupIdentifier = Bundle.main.appGroupIdentifier,
           let remoteIdentifier = userSession.selfUser.remoteIdentifier {
            let sharedContainerURL = FileManager.sharedContainerDirectory(for: appGroupIdentifier)

            _ = sharedContainerURL.appendingPathComponent("AccountData", isDirectory: true)
                .appendingPathComponent(remoteIdentifier.uuidString, isDirectory: true)
        }

        NotificationCenter.default.post(name: NSNotification.Name.ZMUserSessionDidBecomeAvailable, object: nil)

        let featureToken = NotificationCenter.default
            .addObserver(forName: .featureDidChangeNotification, object: nil, queue: .main) { [weak self] note in
                guard let change = note.object as? LegacyFeatureRepository.FeatureChange else { return }

                switch change {
                case .conferenceCallingIsAvailable:
                    guard let session = SessionManager.shared,
                          session.usePackagingFeatureConfig else { break }
                    self?.presentConferenceCallingAvailableAlert()

                default:
                    break
                }
            }
        self.featureChangeObserverToken = SelfUnregisteringNotificationCenterToken(featureToken)

        // Observe developer flag changes using KVO
        self.userDefaultsObservation = UserDefaults.standard
            .observe(\.showUnreadConversationsFilter, options: [.new]) { [weak self] _, _ in
                // Update sidebar's showUnreadFilters when developer flag changes
                self?.sidebarViewController.showUnreadFilters = DeveloperFlag.showUnreadConversationsFilter.isOn
                self?.sidebarViewController.showMeetings = DeveloperFlag.wireMeetings.isOn
            }

        observeCellsFeatureChange()
        createLegalHoldDisclosureController()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        AVSMediaManager.sharedInstance().unregisterMedia(mediaPlaybackManager)
    }

    /// Allows to be notified when the cells feature config is updated locally so we can setup the Files tab.
    /// On login, tab will show up with a slight delay, after resources have been pulled from the server (initial sync).
    private func observeCellsFeatureChange() {
        subscription = userSession.clientSessionComponent?.featureConfigRepository
            .observeFeatureStates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] featureState in
                guard let self else { return }
                switch featureState.name {
                case .cells where featureState.isEnabled:
                    let filesBrowserView = wireMessagingFactory.makeFilesBrowserView()
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        guard !sidebarViewController.showFiles else { break }
                        sidebarViewController.showFiles = true
                        mainTabBarController.filesUI = filesBrowserView
                    } else {
                        guard mainTabBarController.filesUI == nil else { break }
                        mainTabBarController.filesUI = filesBrowserView
                    }
                default:
                    break
                }
            }
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
            let loggingToken = NotificationCenter.default.addObserver(
                forName: .loggingRequestLoop,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.requestLoopNotification(notification)
            }
            loggingRequestLoopObserverToken = SelfUnregisteringNotificationCenterToken(loggingToken)
        }

        setupUserChangeInfoObserver()
        setUpConferenceCallingUnavailableObserver()
        setupDidViewSelfProfileObserver()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        migrateAnalytics()
        firstTimeRequestToEnableAnalytics()
        view.backgroundColor = ColorTheme.Backgrounds.surface
    }

    private func migrateAnalytics() {
        Task {
            do {
                guard let trackingManager, let domain = userSession.selfUser.domain,
                      trackingManager.isAnalyticsTrackingAvailable(for: domain) else { return }
                try await trackingManager.migrateAnalyticsSetupIfNeeded()
            } catch {
                WireLogger.analytics.error("failed to migrate analytics between accounts: \(error)")
            }
        }
    }

    private func firstTimeRequestToEnableAnalytics() {
        Task {
            do {
                guard let trackingManager, let domain = userSession.selfUser.domain,
                      trackingManager.isAnalyticsTrackingAvailable(for: domain) else { return }
                try await trackingManager.firstTimeRequestToEnableAnalytics()
            } catch {
                WireLogger.analytics.error("failed to first time enable analytics: \(error)")
            }
        }
    }

    private func setupSplitViewController() {
        let archiveUI = ArchivedListViewController(userSession: userSession)

        mainSplitViewController.borderColor = ColorTheme.Strokes.outline
        mainSplitViewController.conversationListUI = conversationListViewController

        settingsViewControllerBuilder.settingsPropertyFactoryDelegate = defaultSettingsPropertyFactoryDelegate
        mainTabBarController.archiveUI = archiveUI

        let meetingsUI = wireMeetingsFactory.makeMeetingsView()
        mainTabBarController.meetingsUI = meetingsUI
        mainTabBarController.settingsUI = settingsViewControllerBuilder
            .build(mainCoordinator: mainCoordinator)
        if userSession.isWireCellsEnabled {
            let filesBrowserView = wireMessagingFactory.makeFilesBrowserView()
            mainTabBarController.filesUI = filesBrowserView
        }

        mainTabBarController.delegate = mainCoordinator
        mainSplitViewController.delegate = mainCoordinator
        archiveUI.delegate = mainCoordinator
        connectBuilder.delegate = self

        createGroupConversationBuilder.delegate = mainCoordinator
        channelConversationFormFactory.delegate = mainCoordinator

        addChild(mainSplitViewController)
        mainSplitViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainSplitViewController.view)
        mainSplitViewController.didMove(toParent: self)

        createTopViewConstraints()

        sidebarViewController.accountInfo = cachedAccountInfo
        sidebarViewController.wireAccentColor = .init(rawValue: userSession.selfUser.accentColorValue) ?? .default
        sidebarViewController.delegate = sidebarViewControllerDelegate

        // prevent split view appearance on large phones
        if traitCollection.userInterfaceIdiom != .pad {
            if #available(iOS 17.0, *) {
                mainSplitViewController.traitOverrides.horizontalSizeClass = .compact
            } else {
                setOverrideTraitCollection(.init(horizontalSizeClass: .compact), forChild: mainSplitViewController)
            }
        }

        Task {
            await updateCachedAccountImage()
            await updateCachedAccountInfo()
        }

        conversationFilterSelector.observe(conversationDirectory: userSession.conversationDirectory)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let viewController = presentedViewController,
           viewController is ModalPresentationViewController,
           !viewController.isBeingDismissed {
            return viewController.supportedInterfaceOrientations
        }
        return wr_supportedInterfaceOrientations
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
            let rootViewController = await connectBuilder.build()
            let connectUI = UINavigationController(rootViewController: rootViewController)
            connectUI.modalPresentationStyle = .formSheet
            await mainCoordinator.presentViewController(connectUI)
        }
    }

    // MARK: Status bar

    private var child: UIViewController? {
        topOverlayViewController ?? mainSplitViewController
    }

    private var childForStatusBar: UIViewController? {
        // For iPad regular mode, there is a black bar area and we always use light style and non hidden status bar
        isIPadRegular() ? nil : child
    }

    override var childForStatusBarStyle: UIViewController? {
        childForStatusBar
    }

    override var childForStatusBarHidden: UIViewController? {
        childForStatusBar
    }

    // MARK: - Singleton

    @available(*, deprecated, message: "Please don't access this property, it will be deleted.")
    static var shared: ZClientViewController? {
        (UIApplication.shared.delegate as? AppDelegate)?.appRootRouter?.zClientViewController
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
            selfProfileUIBuilder: selfProfileViewControllerBuilder,
            isUserE2EICertifiedUseCase: userSession.isUserE2EICertifiedUseCase
        )
        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true)
    }

    @objc
    private func dismissClientListController(_ sender: Any?) {
        dismiss(animated: true)
    }

    // MARK: - Animated conversation switch

    func dismissAllModalControllers() async {
        if userSession.ringingCallConversation != nil {
            await mainCoordinator.dismissPresentedViewController()
        } else {
            await withCheckedContinuation { continuation in
                minimizeCallOverlay(animated: true, completion: continuation.resume)
            }
            await mainCoordinator.dismissPresentedViewController()
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

    // MARK: - Setup methods

    func transitionToList(
        animated: Bool,
        leftViewControllerRevealed: Bool = true,
        completion: Completion?
    ) {
        Task {
            let currentFilter = conversationListViewController.conversationFilter
            await mainCoordinator.showConversationList(conversationFilter: currentFilter)
            completion?()
        }
    }

    func setTopOverlay(to viewController: UIViewController?, animated: Bool = true) {
        topOverlayViewController?.willMove(toParent: nil)

        func setupConstraints(for view: UIView, in superview: UIView) {
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
                view.topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor),
                superview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                superview.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        if let previousViewController = topOverlayViewController, let viewController {
            addChild(viewController)
            viewController.view.frame = topOverlayContainer.bounds
            viewController.view.translatesAutoresizingMaskIntoConstraints = false

            if animated {
                transition(
                    from: previousViewController,
                    to: viewController,
                    duration: 0.5,
                    options: .transitionCrossDissolve,
                    animations: { setupConstraints(for: viewController.view, in: self.view) },
                    completion: { _ in
                        viewController.didMove(toParent: self)
                        previousViewController.removeFromParent()
                        self.topOverlayViewController = viewController
                    }
                )
            } else {
                topOverlayContainer.addSubview(viewController.view)
                setupConstraints(for: viewController.view, in: topOverlayContainer)
                viewController.didMove(toParent: self)
                topOverlayViewController = viewController
            }
        } else if let previousViewController = topOverlayViewController {
            if animated {
                let heightConstraint = topOverlayContainer.heightAnchor.constraint(equalToConstant: 0)
                UIView.animate(
                    withDuration: 0.35,
                    delay: 0,
                    options: [.curveEaseIn, .beginFromCurrentState],
                    animations: {
                        heightConstraint.isActive = true

                        self.view.setNeedsLayout()
                        self.view.layoutIfNeeded()
                    },
                    completion: { _ in
                        heightConstraint.isActive = false

                        self.topOverlayViewController?.removeFromParent()
                        previousViewController.view.removeFromSuperview()
                        self.topOverlayViewController = nil
                    }
                )
            } else {
                topOverlayViewController?.removeFromParent()
                previousViewController.view.removeFromSuperview()
                topOverlayViewController = nil
            }
        } else if let viewController {
            addChild(viewController)
            viewController.view.frame = topOverlayContainer.bounds
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            topOverlayContainer.addSubview(viewController.view)
            setupConstraints(for: viewController.view, in: topOverlayContainer)

            viewController.didMove(toParent: self)

            let isRegularContainer = traitCollection.horizontalSizeClass == .regular

            if animated, !isRegularContainer {
                let heightConstraint = viewController.view.heightAnchor.constraint(equalToConstant: 0)
                heightConstraint.isActive = true

                topOverlayViewController = viewController

                UIView.animate(
                    withDuration: 0.35,
                    delay: 0,
                    options: [.curveEaseOut, .beginFromCurrentState],
                    animations: {
                        heightConstraint.isActive = false
                        self.view.layoutIfNeeded()
                    }
                )
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
                viewController.presentOverAll(animated: animated, completion: completion)
            }
        )
    }

    private func createTopViewConstraints() {

        topOverlayContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topOverlayContainer)

        NSLayoutConstraint.activate([
            topOverlayContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topOverlayContainer.topAnchor.constraint(equalTo: view.topAnchor),
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
        view.backgroundColor = ColorTheme.Backgrounds.surface
    }

    /// Open the user client list screen
    ///
    /// - Parameter user: the UserType with client list to show

    func openClientListScreen(for user: WireDataModel.UserType) {
        var viewController: UIViewController?

        if user.isSelfUser, let clients = user.allClients as? [UserClient] {
            let clientListViewController = ClientListViewController(
                clientsList: clients,
                credentials: nil,
                detailedView: true,
                showTemporary: true
            )
            clientListViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(dismissClientListController(_:))
            )
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
                mainCoordinator: .init(mainCoordinator: mainCoordinator),
                selfProfileUIBuilder: selfProfileViewControllerBuilder
            )

            if let conversationViewController = (conversationRootViewController as? ConversationRootViewController)?
                .conversationViewController {
                profileViewController.delegate = conversationViewController

            }
            viewController = profileViewController
        }

        if let viewController {
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.modalPresentationStyle = .formSheet
            Task {
                await mainCoordinator.presentViewController(navigationController)
            }
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
        Task {
            await dismissAllModalControllers()
            if mainTabBarController.selectedContent != .conversations {
                await mainCoordinator.showConversationList(conversationFilter: .none)
            }

            guard !conversation.isDeleted, conversation.managedObjectContext != nil else { return }

            conversationListViewController.viewModel.select(
                conversation: conversation,
                scrollTo: message,
                focusOnView: focus,
                animated: animated
            )
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

    private func updateCachedAccountImage() async {
        do {
            let useCase = GetUserAccountImageSourceUseCase()
            cachedAccountImage = try await useCase.invoke(
                user: userSession.selfUser,
                userContext: userSession.contextProvider.viewContext,
                account: account
            ).mapToAccountImageSource()
        } catch {
            WireLogger.ui.error("Failed to update user's account image: \(String(reflecting: error))")
        }
    }

    private func updateCachedAccountInfo() async {
        do {
            let user = userSession.selfUser
            cachedAccountInfo = SidebarAccountInfo(
                user,
                cachedAccountImage,
                cachedAccountInfo.isE2EICertified,
                showNotificationsBadge: shouldShowNotificationsBadge(user: user)
            )
            let isE2EICertified = try await userSession.isSelfUserE2EICertifiedUseCase.invoke()
            cachedAccountInfo.isE2EICertified = isE2EICertified
        } catch {
            WireLogger.ui.error("Failed to update user's account info for the sidebar: \(String(reflecting: error))")
        }
    }

    private func shouldShowNotificationsBadge(user: any WireDataModel.UserType) -> Bool {
        !user.isTeamMember && userSession.resolvedBackendMetadata.apiVersion
            .map { $0 >= .v7 } ?? false && !hasSeenSelfProfile
    }

    private var hasSeenSelfProfile: Bool {
        selfProfileViewsMonitor.didViewSelfProfile
    }

    private func conversationFilter() -> ConversationFilter? {
        conversationListViewController.conversationFilter
    }
}

// MARK: - ZClientViewController + UserObserving

extension ZClientViewController: UserObserving {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        Task { @MainActor [self] in

            var sidebarUpdateNeeded = false

            if changeInfo.nameChanged || changeInfo.availabilityChanged || changeInfo.trustLevelChanged || changeInfo
                .teamsChanged {
                sidebarUpdateNeeded = true
            }

            if changeInfo.accentColorValueChanged {
                sidebarUpdateNeeded = true
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.mainWindow?.tintColor = UIColor.accent()
            }

            if changeInfo.imageMediumDataChanged || changeInfo.imageSmallProfileDataChanged {
                sidebarUpdateNeeded = true
                await updateCachedAccountImage()
            }

            if sidebarUpdateNeeded {
                await updateCachedAccountInfo()
                sidebarViewController
                    .wireAccentColor = .init(rawValue: userSession.selfUser.accentColorValue) ?? .default
            }
        }
    }

    @objc
    func setupUserChangeInfoObserver() {
        userObserverToken = userSession.addUserObserver(self, for: userSession.selfUser)
    }
}

extension ZClientViewController {
    func setupDidViewSelfProfileObserver() {
        let token = NotificationCenter.default.addObserver(
            forName: .userDidViewSelfProfile,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.updateCachedAccountInfo()
            }
        }
        userDidViewSelfProfileToken = SelfUnregisteringNotificationCenterToken(token)
    }
}
