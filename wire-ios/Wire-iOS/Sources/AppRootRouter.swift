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
import UIKit
import WireCommonComponents
import WireSyncEngine

// MARK: - AppRootRouter
final class AppRootRouter: NSObject {

    // MARK: - Public Property

    let screenCurtain = ScreenCurtain()

    // MARK: - Private Property

    private var appStateCalculator: AppStateCalculator
    private var urlActionRouter: URLActionRouter

    private var authenticationCoordinator: AuthenticationCoordinator?
    private var switchingAccountRouter: SwitchingAccountRouter
    private var sessionManagerLifeCycleObserver: SessionManagerLifeCycleObserver
    private let foregroundNotificationFilter: ForegroundNotificationFilter
    private var quickActionsManager: QuickActionsManager
    private var authenticatedRouter: AuthenticatedRouter? {
        didSet {
            setupAnalyticsSharing()
        }
    }

    private var observerTokens: [NSObjectProtocol] = []
    private var authenticatedBlocks: [() -> Void] = []
    private let teamMetadataRefresher = TeamMetadataRefresher(selfUserProvider: SelfUser.provider)

    // MARK: - Private Set Property

    private(set) var sessionManager: SessionManager

    // swiftlint:disable:next todo_requires_jira_link
    // TODO: This should be private
    private(set) var rootViewController: RootViewController

    private var lastLaunchOptions: LaunchOptions?

    // MARK: - Initialization

    init(
        viewController: RootViewController,
        sessionManager: SessionManager,
        appStateCalculator: AppStateCalculator
    ) {
        self.rootViewController = viewController
        self.sessionManager = sessionManager
        self.appStateCalculator = appStateCalculator
        self.urlActionRouter = URLActionRouter(viewController: viewController)
        self.switchingAccountRouter = SwitchingAccountRouter()
        self.quickActionsManager = QuickActionsManager()
        self.foregroundNotificationFilter = ForegroundNotificationFilter()
        self.sessionManagerLifeCycleObserver = SessionManagerLifeCycleObserver()

        urlActionRouter.sessionManager = sessionManager
        sessionManagerLifeCycleObserver.sessionManager = sessionManager
        foregroundNotificationFilter.sessionManager = sessionManager
        quickActionsManager.sessionManager = sessionManager

        sessionManager.foregroundNotificationResponder = foregroundNotificationFilter
        sessionManager.switchingDelegate = switchingAccountRouter
        sessionManager.presentationDelegate = urlActionRouter

        super.init()

        setupAppStateCalculator()
        setupURLActionRouter()
        setupNotifications()
        setupAdditionalWindows()

        AppRootRouter.configureAppearance()

        createLifeCycleObserverTokens()
        setCallingSettings()
    }

    // MARK: - Public implementation

    func start(launchOptions: LaunchOptions) {
        self.lastLaunchOptions = launchOptions
        showInitial(launchOptions: launchOptions)
        sessionManager.resolveAPIVersion()
    }

    func openDeepLinkURL(_ deepLinkURL: URL) -> Bool {
        return urlActionRouter.open(url: deepLinkURL)
    }

    func performQuickAction(
        for shortcutItem: UIApplicationShortcutItem,
        completionHandler: ((Bool) -> Void)?
    ) {
        quickActionsManager.performAction(for: shortcutItem, completionHandler: completionHandler)
    }

    // MARK: - Private implementation
    private func setupAppStateCalculator() {
        appStateCalculator.delegate = self
    }

    private func setupURLActionRouter() {
        urlActionRouter.delegate = self
    }

    private func setupNotifications() {
        setupApplicationNotifications()
        setupContentSizeCategoryNotifications()
        setupAudioPermissionsNotifications()
    }

    private func setupAdditionalWindows() {
        screenCurtain.makeKeyAndVisible()
        screenCurtain.isHidden = true
    }

    private func createLifeCycleObserverTokens() {
        sessionManagerLifeCycleObserver.createLifeCycleObserverTokens()
    }

    private func setCallingSettings() {
        sessionManager.updateCallNotificationStyleFromSettings()
        sessionManager.updateMuteOtherCallsFromSettings()
        sessionManager.usePackagingFeatureConfig = true
        let useCBR = SecurityFlags.forceConstantBitRateCalls.isEnabled ? true : Settings.shared[.callingConstantBitRate] ?? false
        sessionManager.useConstantBitRateAudio = useCBR
    }

    // MARK: - Transition

    /// A queue on which we dispatch app state transitions.

    private let appStateTransitionQueue = DispatchQueue(label: "AppRootRouter.appStateTransitionQueue")

    /// A group to encapsulate the entire transition to a new app state.

    private let appStateTransitionGroup = DispatchGroup()

    /// Synchronously enqueues a transition to a new app state.
    ///
    /// The transition will only begin once a previous transition has completed.
    ///
    /// - Parameters:
    ///     - appState: The new state to transition to.
    ///     - completion: A block executed after the transition has completed.

    private func enqueueTransition(to appState: AppState, completion: @escaping () -> Void = {}) {
        // Perform the wait on a background queue so we don't cause a
        // deadlock on the main queue.
        appStateTransitionQueue.async { [weak self] in
            guard let `self` = self else { return }

            self.appStateTransitionGroup.wait()

            DispatchQueue.main.async {
                self.transition(to: appState, completion: completion)
            }
        }
    }

}

// MARK: - AppStateCalculatorDelegate
extension AppRootRouter: AppStateCalculatorDelegate {
    func appStateCalculator(_: AppStateCalculator,
                            didCalculate appState: AppState,
                            completion: @escaping () -> Void) {
        enqueueTransition(to: appState, completion: completion)
    }

    @MainActor
    private func transition(to appState: AppState, completion: @escaping () -> Void) {
        applicationWillTransition(to: appState)

        resetAuthenticationCoordinatorIfNeeded(for: appState)

        let completionBlock = { [weak self] in
            completion()
            self?.applicationDidTransition(to: appState)
        }

        switch appState {
        case .retryStart:
            retryStart(completion: completionBlock)
        case .blacklisted(reason: let reason):
            showBlacklisted(reason: reason, completion: completionBlock)
        case .jailbroken:
            showJailbroken(completion: completionBlock)
        case .certificateEnrollmentRequired:
            showCertificateEnrollRequest(completion: completionBlock)
        case .databaseFailure(let error):
            showDatabaseLoadingFailure(error: error, completion: completionBlock)
        case .migrating:
            showLaunchScreen(isLoading: true, completion: completionBlock)
        case .unauthenticated(error: let error):
            screenCurtain.userSession = nil
            configureUnauthenticatedAppearance()
            showUnauthenticatedFlow(error: error, completion: completionBlock)
        case let .authenticated(userSession):
            configureAuthenticatedAppearance()
            executeAuthenticatedBlocks()
            screenCurtain.userSession = userSession
            showAuthenticated(
                userSession: userSession,
                completion: completionBlock
            )
        case .headless:
            showLaunchScreen(completion: completionBlock)
        case .loading(account: let toAccount, from: let fromAccount):
            showSkeleton(fromAccount: fromAccount,
                         toAccount: toAccount,
                         completion: completionBlock)
        case let .locked(userSession):
            screenCurtain.userSession = userSession
            showAppLock(userSession: userSession, completion: completionBlock)
        }
    }

    private func resetAuthenticationCoordinatorIfNeeded(for state: AppState) {
        switch state {
        case .authenticated:
            authenticationCoordinator?.tearDown()
            authenticationCoordinator = nil
        default:
            break
        }
    }

    func performWhenAuthenticated(_ block: @escaping () -> Void) {
        if case .authenticated = appStateCalculator.appState {
            block()
        } else {
            authenticatedBlocks.append(block)
        }
    }

    func executeAuthenticatedBlocks() {
        while !authenticatedBlocks.isEmpty {
            authenticatedBlocks.removeFirst()()
        }
    }

    func reload() {
        enqueueTransition(to: .headless)
        enqueueTransition(to: appStateCalculator.appState)
    }
}

extension AppRootRouter {
    // MARK: - Navigation Helpers
    private func showInitial(launchOptions: LaunchOptions) {
        enqueueTransition(to: .headless) { [weak self] in
            Analytics.shared.tagEvent("app.open")
            self?.sessionManager.start(launchOptions: launchOptions)
        }
    }

    private func showBlacklisted(reason: BlacklistReason, completion: @escaping () -> Void) {
        let blockerViewController = BlockerViewController(context: reason.blockerViewControllerContext)
        rootViewController.set(childViewController: blockerViewController,
                               completion: completion)
    }

    private func showJailbroken(completion: @escaping () -> Void) {
        let blockerViewController = BlockerViewController(context: .jailbroken)
        rootViewController.set(childViewController: blockerViewController,
                               completion: completion)
    }

    private func showCertificateEnrollRequest(completion: @escaping () -> Void) {
        let blockerViewController = BlockerViewController(
            context: .pendingCertificateEnroll,
            sessionManager: sessionManager)
        rootViewController.set(childViewController: blockerViewController,
                               completion: completion)
    }

    private func showDatabaseLoadingFailure(error: Error, completion: @escaping () -> Void) {
        let blockerViewController = BlockerViewController(
            context: .databaseFailure,
            sessionManager: sessionManager,
            error: error
        )

        rootViewController.set(childViewController: blockerViewController,
                               completion: completion)
    }

    private func showLaunchScreen(isLoading: Bool = false, completion: @escaping () -> Void) {
        let launchViewController = LaunchImageViewController()

        if isLoading {
            launchViewController.showLoadingScreen()
        }

        rootViewController.set(childViewController: launchViewController,
                               completion: completion)
    }

    private func showUnauthenticatedFlow(error: NSError?, completion: @escaping () -> Void) {
        // Only execute handle events if there is no current flow
        guard
            self.authenticationCoordinator == nil ||
                error?.userSessionErrorCode == .addAccountRequested ||
                error?.userSessionErrorCode == .accountDeleted ||
                error?.userSessionErrorCode == .needsAuthenticationAfterMigration,
            let sessionManager = SessionManager.shared
        else {
            completion()
            return
        }

        let navigationController = SpinnerCapableNavigationController(
            navigationBarClass: AuthenticationNavigationBar.self,
            toolbarClass: nil
        )

        authenticationCoordinator?.tearDown()

        authenticationCoordinator = AuthenticationCoordinator(
            presenter: navigationController,
            sessionManager: sessionManager,
            featureProvider: BuildSettingAuthenticationFeatureProvider(),
            statusProvider: AuthenticationStatusProvider()
        )

        guard let authenticationCoordinator = authenticationCoordinator else {
            completion()
            return
        }

        authenticationCoordinator.delegate = appStateCalculator
        authenticationCoordinator.startAuthentication(
            with: error,
            numberOfAccounts: SessionManager.numberOfAccounts
        )

        rootViewController.set(childViewController: navigationController,
                               completion: completion)
    }

    @MainActor
    private func showAuthenticated(
        userSession: UserSession,
        completion: @escaping () -> Void
    ) {
        guard
            let selectedAccount = SessionManager.shared?.accountManager.selectedAccount,
            let authenticatedRouter = buildAuthenticatedRouter(
                account: selectedAccount,
                userSession: userSession
            )
        else {
            completion()
            return
        }

        self.authenticatedRouter = authenticatedRouter
        rootViewController.set(
            childViewController: authenticatedRouter.viewController,
            completion: completion
        )
    }

    private func showSkeleton(fromAccount: Account?, toAccount: Account, completion: @escaping () -> Void) {
        let skeletonViewController = SkeletonViewController(from: fromAccount, to: toAccount)
        rootViewController.set(childViewController: skeletonViewController,
                               completion: completion)
    }

    private func showAppLock(userSession: UserSession, completion: @escaping () -> Void) {
        rootViewController.set(
            childViewController: AppLockModule.build(
                userSession: userSession
            ),
            completion: completion
        )
    }

    private func retryStart(completion: @escaping () -> Void) {
        guard let launchOptions = lastLaunchOptions else { return }
        completion()
        enqueueTransition(to: .headless) { [weak self] in
            self?.sessionManager.start(launchOptions: launchOptions)
        }
    }

    // MARK: - Helpers
    private func configureUnauthenticatedAppearance() {
        rootViewController.view.window?.tintColor = UIColor.Wire.primaryLabel
        ValidatedTextField.appearance(whenContainedInInstancesOf: [AuthenticationStepController.self]).tintColor = UIColor.Team.activeButton
    }

    private func configureAuthenticatedAppearance() {
        rootViewController.view.window?.tintColor = .accent()
        UIColor.setAccentOverride(nil)
    }

    private func setupAnalyticsSharing() {
        guard
            let selfUser = SelfUser.provider?.providedSelfUser,
            selfUser.isTeamMember
        else {
            return
        }

        TrackingManager.shared.disableCrashSharing = true
        TrackingManager.shared.disableAnalyticsSharing = false
        Analytics.shared.provider?.selfUser = selfUser
    }

    @MainActor
    private func buildAuthenticatedRouter(
        account: Account,
        userSession: UserSession
    ) -> AuthenticatedRouter? {
        guard let userSession = ZMUserSession.shared() else { return  nil }

        let isTeamMember: Bool
        if let user = SelfUser.provider?.providedSelfUser {
            isTeamMember = user.isTeamMember
        } else {
            assertionFailure("expected available 'user'!")
            isTeamMember = false
        }

        let needToShowDialog = appStateCalculator.wasUnauthenticated && !isTeamMember
        return AuthenticatedRouter(
            rootViewController: rootViewController,
            account: account,
            userSession: userSession,
            needToShowDataUsagePermissionDialog: needToShowDialog,
            featureRepositoryProvider: userSession,
            featureChangeActionsHandler: E2EINotificationActionsHandler(
                enrollCertificateUseCase: userSession.enrollE2EICertificate,
                snoozeCertificateEnrollmentUseCase: userSession.snoozeCertificateEnrollmentUseCase,
                stopCertificateEnrollmentSnoozerUseCase: userSession.stopCertificateEnrollmentSnoozerUseCase,
                e2eiActivationDateRepository: userSession.e2eiActivationDateRepository,
                e2eiFeature: userSession.e2eiFeature,
                lastE2EIdentityUpdateAlertDateRepository: userSession.lastE2EIUpdateDateRepository,
                e2eIdentityCertificateUpdateStatus: userSession.e2eIdentityUpdateCertificateUpdateStatus(),
                selfClientCertificateProvider: userSession.selfClientCertificateProvider,
                targetVC: rootViewController),
            e2eiActivationDateRepository: userSession.e2eiActivationDateRepository
        )
    }
}

extension AppRootRouter {
    private func applicationWillTransition(to appState: AppState) {
        appStateTransitionGroup.enter()
        configureSelfUserProviderIfNeeded(for: appState)
        configureColorScheme()
    }

    private func applicationDidTransition(to appState: AppState) {
        switch appState {
        case .unauthenticated(error: let error):
            presentAlertForDeletedAccountIfNeeded(error)
            sessionManager.processPendingURLActionDoesNotRequireAuthentication()
        case .authenticated:
            // This is needed to display an ongoing call when coming from the background.
            authenticatedRouter?.updateActiveCallPresentationState()
            urlActionRouter.authenticatedRouter = authenticatedRouter
            ZClientViewController.shared?.legalHoldDisclosureController?.discloseCurrentState(cause: .appOpen)
            sessionManager.processPendingURLActionRequiresAuthentication()
            sessionManager.processPendingURLActionDoesNotRequireAuthentication()
        default:
            break
        }

        urlActionRouter.performPendingActions()
        resetSelfUserProviderIfNeeded(for: appState)
        resetAuthenticatedRouterIfNeeded(for: appState)
        appStateTransitionGroup.leave()
    }

    private func resetAuthenticatedRouterIfNeeded(for appState: AppState) {
        switch appState {
        case .authenticated: break
        default:
            authenticatedRouter = nil
        }
    }

    private func resetSelfUserProviderIfNeeded(for appState: AppState) {
        guard AppDelegate.shared.shouldConfigureSelfUserProvider else { return }

        switch appState {
        case .authenticated: break
        default:
            SelfUser.provider = nil
        }
    }

    private func configureSelfUserProviderIfNeeded(for appState: AppState) {
        guard AppDelegate.shared.shouldConfigureSelfUserProvider else { return }

        if case .authenticated = appState {
            SelfUser.provider = ZMUserSession.shared()
        }
    }

    private func configureColorScheme() {
        let colorScheme = ColorScheme.default
        colorScheme.accentColor = .accent()
        colorScheme.variant = Settings.shared.colorSchemeVariant

        UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = Settings.shared.colorScheme.userInterfaceStyle
        }

    }

    private func presentAlertForDeletedAccountIfNeeded(_ error: NSError?) {
        guard
            error?.userSessionErrorCode == .accountDeleted,
            let reason = error?.userInfo[ZMAccountDeletedReasonKey] as? ZMAccountDeletedReason
        else {
            return
        }

        switch reason {
        case .sessionExpired:
            rootViewController.presentAlertWithOKButton(
                title: L10n.Localizable.AccountDeletedSessionExpiredAlert.title,
                message: L10n.Localizable.AccountDeletedSessionExpiredAlert.message)

        case .biometricPasscodeNotAvailable:
            rootViewController.presentAlertWithOKButton(
                title: L10n.Localizable.AccountDeletedMissingPasscodeAlert.title,
                message: L10n.Localizable.AccountDeletedMissingPasscodeAlert.message)

        case .databaseWiped:
            let wipeCompletionViewController = WipeCompletionViewController()
            wipeCompletionViewController.modalPresentationStyle = .fullScreen
            rootViewController.present(wipeCompletionViewController, animated: true)

        default:
            break
        }
    }
}

// MARK: - URLActionRouterDelegate

extension AppRootRouter: URLActionRouterDelegate {

    func urlActionRouterWillShowCompanyLoginError() {
        authenticationCoordinator?.cancelCompanyLogin()
    }

    func urlActionRouterCanDisplayAlerts() -> Bool {
        switch appStateCalculator.appState {
        case .authenticated, .unauthenticated:
            return true
        default:
            return false
        }
    }

}

// MARK: - ApplicationStateObserving

extension AppRootRouter: ApplicationStateObserving {
    func addObserverToken(_ token: NSObjectProtocol) {
        observerTokens.append(token)
    }

    func applicationDidBecomeActive() {
        updateOverlayWindowFrame()
        teamMetadataRefresher.triggerRefreshIfNeeded()
    }

    func applicationDidEnterBackground() {
        let unreadConversations = sessionManager.accountManager.totalUnreadCount
        UIApplication.shared.applicationIconBadgeNumber = unreadConversations
    }

    func applicationWillEnterForeground() {
        updateOverlayWindowFrame()
        sessionManager.resolveAPIVersion()
    }

    func updateOverlayWindowFrame(size: CGSize? = nil) {
        if let size = size {
            screenCurtain.frame.size = size
        } else {
            screenCurtain.frame = UIApplication.shared.firstKeyWindow?.frame ?? UIScreen.main.bounds
        }
    }
}

// MARK: - ContentSizeCategoryObserving

extension AppRootRouter: ContentSizeCategoryObserving {
    func contentSizeCategoryDidChange() {
        NSAttributedString.invalidateParagraphStyle()
        NSAttributedString.invalidateMarkdownStyle()
        ConversationListCell.invalidateCachedCellSize()
        FontScheme.configure(with: UIApplication.shared.preferredContentSizeCategory)
        AppRootRouter.configureAppearance()
        rootViewController.redrawAllFonts()
    }

    static func configureAppearance() {
        let navigationBarTitleBaselineOffset: CGFloat = 2.5

        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11, weight: .semibold), .baselineOffset: navigationBarTitleBaselineOffset]
        let barButtonItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [DefaultNavigationBar.self])
        barButtonItemAppearance.setTitleTextAttributes(attributes, for: .normal)
        barButtonItemAppearance.setTitleTextAttributes(attributes, for: .highlighted)
        barButtonItemAppearance.setTitleTextAttributes(attributes, for: .disabled)
    }
}

// MARK: - AudioPermissionsObserving

extension AppRootRouter: AudioPermissionsObserving {
    func userDidGrantAudioPermissions() {
        sessionManager.updateCallNotificationStyleFromSettings()
        sessionManager.updateMuteOtherCallsFromSettings()
    }
}
