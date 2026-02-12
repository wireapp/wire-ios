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

import avs
import CallKit
import Foundation
import PushKit
import UserNotifications
import WireAnalytics
import WireDataModel
import WireDomain
import WireFoundation
import WireLogging
import WireNetwork
import WireRequestStrategy
import WireTransport
import WireUtilities

public typealias LaunchOptions = [UIApplication.LaunchOptionsKey: Any]

public extension Bundle {
    @objc var appGroupIdentifier: String? {
        bundleIdentifier.map { "group." + $0 }
    }

    static var developerModeEnabled: Bool {
        Bundle.appMainBundle.infoForKey("EnableDeveloperMenu") == "1"
    }

    private static var appMainBundle: Bundle {
        let mainBundle: Bundle
        let runningInExtension = Bundle.main.bundlePath.hasSuffix(".appex")
        if runningInExtension {
            let extensionBundleURL = Bundle.main.bundleURL
            let mainAppBundleURL = extensionBundleURL.deletingLastPathComponent().deletingLastPathComponent()
            guard let bundle = Bundle(url: mainAppBundleURL) else { fatalError("Failed to find main app bundle") }
            mainBundle = bundle
        } else {
            mainBundle = .main
        }
        return mainBundle
    }
}

@objc
public enum CallNotificationStyle: UInt {
    case pushNotifications
    case callKit
}

public protocol SessionActivationObserver: AnyObject {
    func sessionManagerDidChangeActiveUserSession(userSession: ZMUserSession)
    func sessionManagerDidReportLockChange(forSession session: UserSession)
}

// sourcery: AutoMockable
public protocol SessionManagerDelegate: AnyObject, SessionActivationObserver {
    func sessionManagerWillLogout(
        environment: BackendEnvironment2?,
        error: Error?,
        userSessionCanBeTornDown: (() -> Void)?
    )
    func sessionManagerWillOpenAccount(
        _ account: Account,
        from selectedAccount: Account?,
        userSessionCanBeTornDown: @escaping () -> Void
    )
    func sessionManagerWillMigrateAccount(userSessionCanBeTornDown: @escaping () -> Void)

    func sessionManagerDidFailToLoadSession(
        for account: Account,
        error: SessionManager.SessionLoadingFailure
    )

    func sessionManagerDidFailToLoadDatabase(error: Error)
    func sessionManagerDidBlacklistCurrentVersion(reason: BlacklistReason)
    func sessionManagerDidBlacklistJailbrokenDevice()
    func sessionManagerRequireCertificateEnrollment()
    func sessionManagerDidEnrollCertificate(for activeSession: UserSession?)

    func sessionManagerDidPerformFederationMigration(activeSession: UserSession?)
    func sessionManagerDidPerformAPIMigrations(activeSession: UserSession?)
    func sessionManagerAsksToRetryStart()
    func sessionManagerDidCompleteInitialSync(for activeSession: UserSession?)
    func sessionManagerDidFailSyncing(
        error: any Error,
        retryHandler: @escaping () -> Void
    )
    var isInAuthenticatedAppState: Bool { get }
    var isInUnathenticatedAppState: Bool { get }
}

extension SessionManagerDelegate {

    @MainActor
    func sessionManagerWillMigrateAccount() async {
        await withCheckedContinuation { continuation in
            sessionManagerWillMigrateAccount {
                continuation.resume()
            }
        }
    }

}

/// The public interface for the session manager.

@objc
public protocol SessionManagerType: AnyObject {

    var accountManager: AccountManager { get }

    weak var foregroundNotificationResponder: ForegroundNotificationResponder? { get }

    var callKitManager: CallKitManagerInterface { get }
    var callNotificationStyle: CallNotificationStyle { get }

    func updateAppIconBadge(accountID: UUID, unreadCount: Int)
    func configurePushToken(session: ZMUserSession)

    /// Configure user notification settings. This will ask the user for permission to display notifications.
    func configureUserNotifications()

    /// Switch account and and ask UI to to navigate to a message in a conversation
    ///
    /// - Parameters:
    ///   - conversation: the conversation to switch
    ///   - message: the message to navigate
    ///   - session: the session of the conversation
    func showConversation(
        _ conversation: ZMConversation,
        at message: ZMConversationMessage?,
        in session: ZMUserSession
    )

    /// Switch account and and ask UI to navigate to the conversation list
    func showConversationList(in session: ZMUserSession)

    /// ask UI to open the profile of a user
    func showUserProfile(user: WireDataModel.UserType)

    /// Needs to be called before we try to register another device because API requires password
    func update(credentials: UserCredentials) -> Bool

    func passwordVerificationDidFail(with failCount: Int)

}

@objc
public protocol SessionManagerSwitchingDelegate: AnyObject {
    func confirmSwitchingAccount(completion: @escaping (Bool) -> Void)
}

@objc
public protocol ForegroundNotificationResponder: AnyObject {
    @MainActor
    func shouldPresentNotification(with userInfo: NotificationUserInfo) -> Bool
}

/// Manage the creation of `ZMUserSession` and `UnauthenticatedSession` objects and
/// the switching between them.
///
/// There are multiple things neccessary in order to store (and switch between) multiple accounts on one device, a
/// couple of them are:
/// 1. The folder structure in the app sandbox has to be modeled in a way in which files can be associated with a single
/// account.
/// 2. The login flow should not rely on any persistent state (e.g. no database has to be created on disk before being
/// logged in).
/// 3. There has to be a persistence layer storing information about accounts and the currently selected / active
/// account.
///
/// The wire account database and a couple of other related files are stored in the shared container in a folder named
/// by the accounts
/// `remoteIdentifier`. All information about different accounts on a device are stored by the `AccountManager` (see the
/// documentation
/// of that class for more information). The `SessionManager`s main responsibility at the moment is checking whether
/// there is a selected
/// `Account` or not, and creating an `UnauthenticatedSession` or `ZMUserSession` accordingly. An
/// `UnauthenticatedSession` is used
/// to create requests to either log in existing users or to register new users. It uses its own
/// `UnauthenticatedOperationLoop`,
/// which is a stripped down version of the regular `ZMOperationLoop`. This unauthenticated operation loop only uses a
/// small subset
/// of transcoders needed to perform the login / registration (and related phone number verification) requests. For more
/// information
/// see `UnauthenticatedOperationLoop`.
///
/// The result of using an `UnauthenticatedSession` is retrieving a remoteIdentifier of a logged in user, as well as a
/// valid cookie.
/// Once those became available, the session will notify the session manager, which in turn will create a regular
/// `ZMUserSession`.
/// For more information about the cookie retrieval consult the documentation in `UnauthenticatedSession`.
///
/// The flow creating either an `UnauthenticatedSession` or `ZMUserSession` after creating an instance of
/// `SessionManager`
/// is depicted on a high level in the following diagram:
///
///
/// +-----------------------------------------+
/// |         `SessionManager.init`           |
/// +-----------------------------------------+
///
///                    +
///                    |
///                    |
///                    v
///
/// +-----------------------------------------+        YES           Load the selected Account and its
/// | Is there a stored and selected Account? |   +------------->    cookie from disk.
/// +-----------------------------------------+                      Create a `ZMUserSession` using the cookie.
///
///                    +
///                    |
///                    | NO
///                    |
///                    v
///
/// +------------------+---------------------+
/// | Check if there is a database present   |        YES           Open the existing database, retrieve the user
/// identifier,
/// | in the legacy directory (not keyed by  |  +-------------->    create an account with it and select it. Migrate the
/// existing
/// | the users remoteIdentifier)?           |                      cookie for that account and start at the top again.
/// +----------------------------------------+
///
///                    +
///                    |
///                    | NO
///                    |
///                    v
///
/// +------------------+---------------------+
/// | Create a `UnauthenticatedSession` to   |
/// | start the registration or login flow.  |
/// +----------------------------------------+
///

@objcMembers
public final class SessionManager: NSObject, SessionManagerType {

    static let logger = Logger(subsystem: "VoIP Push", category: "SessionManager")

    public enum AccountError: Error {
        case accountLimitReached
    }

    /// Maximum number of accounts which can be logged in simultanously
    public let maxNumberAccounts: Int

    /// Default Maximum number of accounts which can be logged in simultanously
    public static let defaultMaxNumberAccounts: Int = 3

    public let currentAppVersion: String
    public let currentBuildNumber: String
    var isAppVersionBlacklisted = false
    public weak var delegate: SessionManagerDelegate?
    public let accountManager: AccountManager
    public let environmentStore: BackendEnvironmentStore
    public weak var loginDelegate: LoginDelegate?

    public internal(set) var activeUserSession: ZMUserSession? {
        willSet {
            guard activeUserSession != newValue else { return }
            activeUserSession?.appLockController.beginTimer()
            activeUserSession?.setAnalyticsEventTracker(nil)
        }
    }

    public private(set) var backgroundUserSessions = [UUID: ZMUserSession]()

    public internal(set) var unauthenticatedSession: UnauthenticatedSession? {
        willSet {
            unauthenticatedSession?.tearDown()
        }
        didSet {
            if let session = unauthenticatedSession {

                NotificationInContext(
                    name: sessionManagerCreatedUnauthenticatedSessionNotificationName,
                    context: self,
                    object: session
                ).post()
            }
        }

    }

    public weak var presentationDelegate: PresentationDelegate?
    public weak var foregroundNotificationResponder: ForegroundNotificationResponder?
    public weak var switchingDelegate: SessionManagerSwitchingDelegate?
    public let groupQueue: GroupQueue = DispatchGroupQueue(queue: .main)

    let application: ZMApplication
    var deleteAccountToken: Any?
    var callCenterObserverToken: Any?
    let configuration: SessionManagerConfiguration
    var pendingURLAction: URLAction?

    var notificationCenter: UserNotificationCenterAbstraction = .wrapper(.current())

    var authenticatedSessionFactory: AuthenticatedSessionFactory
    let unauthenticatedSessionFactory: UnauthenticatedSessionFactory

    private let sessionLoadingQueue: DispatchQueue = .init(label: "sessionLoadingQueue")

    private(set) var reachability: ReachabilityWrapper

    public internal(set) var environment: WireTransport.BackendEnvironment {
        didSet {
            reachability.tearDown()
            reachability = environment.reachabilityWrapper()
            authenticatedSessionFactory.environment = environment
            unauthenticatedSessionFactory.environment = environment
            unauthenticatedSessionFactory.reachability = reachability
            authenticatedSessionFactory.reachability = reachability
        }
    }

    // closure injected to remove all user related logs
    var deleteUserLogs: (() -> Void)?

    let sharedContainerURL: URL
    let dispatchGroup: ZMSDispatchGroup
    let jailbreakDetector: JailbreakDetectorProtocol?
    fileprivate var accountTokens: [UUID: [Any]] = [:]
    fileprivate var memoryWarningObserver: NSObjectProtocol?
    fileprivate var isSelectingAccount: Bool = false

    var proxyCredentials: WireTransport.ProxyCredentials?

    public let callKitManager: CallKitManagerInterface
    private let logFilesProvider: LogFilesProviding

    public var isSelectedAccountAuthenticated: Bool {
        guard let selectedAccount = accountManager.selectedAccount else {
            return false
        }

        return environment.isAuthenticated(selectedAccount)
    }

    public var activeUnauthenticatedSession: UnauthenticatedSession {
        unauthenticatedSession ?? createUnauthenticatedSession()
    }

    private static var avsLogObserver: AVSLogObserver?

    private(set) var isUnauthenticatedTransportSessionReady: Bool

    let isDeveloperModeEnabled: Bool

    let pushTokenService: PushTokenServiceInterface

    var cachesDirectory: URL? {
        let manager = FileManager.default
        return manager.urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    private let minTLSVersion: String?

    let analyticsService: AnalyticsService?

    private let sharedUserDefaults: UserDefaults

    /// Used by `withSession(for:newEnvironment:notifyAboutMigration:)` to avoid creating & loading multiple sessions
    /// for the same account concurrently.
    private let withSessionTaskManager = NonReentrantTaskManager<ZMUserSession?, Never>()

    // MARK: - Life cycle

    public override init() {
        fatal("init() not implemented")
    }

    @MainActor
    public convenience init(
        maxNumberAccounts: Int = defaultMaxNumberAccounts,
        currentAppVersion: String,
        currentBuildNumber: String,
        mediaManager: MediaManagerType,
        delegate: SessionManagerDelegate?,
        application: ZMApplication,
        dispatchGroup: ZMSDispatchGroup? = nil,
        environment: WireTransport.BackendEnvironment,
        configuration: SessionManagerConfiguration = SessionManagerConfiguration(),
        detector: JailbreakDetectorProtocol = JailbreakDetector(),
        pushTokenService: PushTokenServiceInterface = PushTokenService(),
        callKitManager: CallKitManagerInterface,
        isDeveloperModeEnabled: Bool = false,
        isUnauthenticatedTransportSessionReady: Bool = false,
        sharedUserDefaults: UserDefaults,
        minTLSVersion: String?,
        deleteUserLogs: @escaping () -> Void,
        analyticsServiceConfiguration: AnalyticsServiceConfiguration?,
        countlyProvider: @escaping () -> CountlyProtocol,
        logFilesProvider: LogFilesProviding
    ) throws {
        let flowManager = FlowManager(mediaManager: mediaManager)
        let reachability = environment.reachabilityWrapper()

        var proxyCredentials: WireTransport.ProxyCredentials?

        if let proxy = environment.proxy {
            proxyCredentials = ProxyCredentials.retrieve(for: proxy)
        }

        let dispatchGroup = dispatchGroup ?? ZMSDispatchGroup(label: "WireSyncEngine.SessionManager.private")

        let unauthenticatedSessionFactory = UnauthenticatedSessionFactory(
            appVersion: currentBuildNumber,
            environment: environment,
            proxyUsername: proxyCredentials?.username,
            proxyPassword: proxyCredentials?.password,
            reachability: reachability
        )

        let authenticatedSessionFactory = AuthenticatedSessionFactory(
            currentAppVersion: currentAppVersion,
            currentBuildNumber: currentBuildNumber,
            application: application,
            mediaManager: mediaManager,
            flowManager: flowManager,
            environment: environment,
            proxyUsername: proxyCredentials?.username,
            proxyPassword: proxyCredentials?.password,
            reachability: reachability,
            minTLSVersion: minTLSVersion
        )

        try self.init(
            maxNumberAccounts: maxNumberAccounts,
            currentAppVersion: currentAppVersion,
            currentBuildNumber: currentBuildNumber,
            authenticatedSessionFactory: authenticatedSessionFactory,
            unauthenticatedSessionFactory: unauthenticatedSessionFactory,
            reachability: reachability,
            delegate: delegate,
            application: application,
            dispatchGroup: dispatchGroup,
            environment: environment,
            configuration: configuration,
            detector: detector,
            pushTokenService: pushTokenService,
            callKitManager: callKitManager,
            isDeveloperModeEnabled: isDeveloperModeEnabled,
            proxyCredentials: proxyCredentials,
            isUnauthenticatedTransportSessionReady: isUnauthenticatedTransportSessionReady,
            sharedUserDefaults: sharedUserDefaults,
            minTLSVersion: minTLSVersion,
            deleteUserLogs: deleteUserLogs,
            analyticsServiceConfiguration: analyticsServiceConfiguration,
            countlyProvider: countlyProvider,
            logFilesProvider: logFilesProvider
        )

        self.memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            WireLogger.sessionManager.debug("Received memory warning, tearing down background user sessions.")
            self?.tearDownAllBackgroundSessions()
        }

        NotificationCenter
            .default
            .addObserver(
                self,
                selector: #selector(applicationWillEnterForeground(_:)),
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
        NotificationCenter
            .default
            .addObserver(
                self,
                selector: #selector(applicationWillResignActive(_:)),
                name: UIApplication.willResignActiveNotification,
                object: nil
            )
        NotificationCenter
            .default
            .addObserver(
                self,
                selector: #selector(applicationDidBecomeActive(_:)),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )

    }

    @MainActor
    init(
        maxNumberAccounts: Int = defaultMaxNumberAccounts,
        currentAppVersion: String,
        currentBuildNumber: String,
        authenticatedSessionFactory: AuthenticatedSessionFactory,
        unauthenticatedSessionFactory: UnauthenticatedSessionFactory,
        reachability: ReachabilityWrapper,
        delegate: SessionManagerDelegate?,
        application: ZMApplication,
        dispatchGroup: ZMSDispatchGroup,
        environment: WireTransport.BackendEnvironment,
        configuration: SessionManagerConfiguration = SessionManagerConfiguration(),
        detector: JailbreakDetectorProtocol = JailbreakDetector(),
        pushTokenService: PushTokenServiceInterface = PushTokenService(),
        callKitManager: CallKitManagerInterface,
        isDeveloperModeEnabled: Bool = false,
        proxyCredentials: WireTransport.ProxyCredentials?,
        isUnauthenticatedTransportSessionReady: Bool = false,
        sharedUserDefaults: UserDefaults,
        minTLSVersion: String? = nil,
        deleteUserLogs: (() -> Void)? = nil,
        analyticsServiceConfiguration: AnalyticsServiceConfiguration?,
        countlyProvider: @escaping () -> CountlyProtocol,
        logFilesProvider: LogFilesProviding
    ) throws {
        SessionManager.enableLogsByEnvironmentVariable()
        self.environment = environment
        self.currentAppVersion = currentAppVersion
        self.currentBuildNumber = currentBuildNumber
        self.application = application
        self.delegate = delegate
        self.dispatchGroup = dispatchGroup
        self.configuration = configuration.copy() as! SessionManagerConfiguration
        self.jailbreakDetector = detector
        self.pushTokenService = pushTokenService
        self.callKitManager = callKitManager
        self.proxyCredentials = proxyCredentials
        self.isUnauthenticatedTransportSessionReady = isUnauthenticatedTransportSessionReady
        self.sharedUserDefaults = sharedUserDefaults
        self.minTLSVersion = minTLSVersion
        self.deleteUserLogs = deleteUserLogs
        self.logFilesProvider = logFilesProvider

        guard let sharedContainerURL = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else {
            preconditionFailure("Unable to get shared container URL")
        }

        self.sharedContainerURL = sharedContainerURL
        let accountURLs = AccountURLs(root: sharedContainerURL)
        self.accountManager = try AccountManager(
            currentAppVersion: currentAppVersion,
            directory: accountURLs.accounts
        )
        self.environmentStore = try BackendEnvironmentStore(directory: accountURLs.accountData)

        WireLogger.sessionManager.debug("Starting the session manager:")

        if accountManager.hasAccounts {
            WireLogger.sessionManager.debug("Known accounts:")
            accountManager.accounts.forEach { account in
                WireLogger.sessionManager
                    .debug("\(account.userName) -- \(account.userIdentifier) -- \(account.teamName ?? "no team")")
            }

            if let selectedAccount = accountManager.selectedAccount {
                WireLogger.sessionManager.debug("Default account: \(selectedAccount.userIdentifier)")
            }
        } else {
            WireLogger.sessionManager.debug("No known accounts.")
        }

        self.authenticatedSessionFactory = authenticatedSessionFactory
        self.unauthenticatedSessionFactory = unauthenticatedSessionFactory
        self.reachability = reachability
        self.maxNumberAccounts = maxNumberAccounts
        self.isDeveloperModeEnabled = isDeveloperModeEnabled

        // we must set these before initializing the PushDispatcher b/c if the app
        // received a push from terminated state, it requires these properties to be
        // non nil in order to process the notification
        BackgroundActivityFactory.shared.activityManager = UIApplication.shared

        self.analyticsService = analyticsServiceConfiguration.map { config in
            AnalyticsService(
                config: CountlyConfiguration(appKey: config.secretKey, host: config.serverHost),
                deviceModel: UIDevice.current.model,
                osVersion: UIDevice.current.systemVersion,
                countlyProvider: countlyProvider
            )
        }

        super.init()

        callKitManager.setDelegate(self)
        updateCallNotificationStyle()

        pushTokenService.onTokenChange = { [weak self] _ in
            guard
                let self,
                let session = activeUserSession
            else {
                return
            }

            syncLocalTokenWithRemote(session: session)
        }

        self.deleteAccountToken = AccountDeletedNotification.addObserver(observer: self, queue: groupQueue)
        self.callCenterObserverToken = WireCallCenterV3.addGlobalCallStateObserver(observer: self)

        checkJailbreakIfNeeded()
    }

    @MainActor
    public func start(launchOptions: LaunchOptions) async {
        if
            let url = launchOptions[UIApplication.LaunchOptionsKey.url] as? URL,
            let urlAction = try? URLAction(url: url),
            urlAction.causesLogout {
            // If a logout is coming, then no need to start.
            return
        }

        if shouldPerformPostRebootLogout() {
            performPostRebootLogout()
            return
        }

        if let account = accountManager.selectedAccount {
            if let session = await loadSession(for: account) {
                updateCurrentAccount(in: session.managedObjectContext)
                session.application(application, didFinishLaunching: launchOptions)
            }
        } else {
            createUnauthenticatedSession()
            delegate?.sessionManagerWillLogout(
                environment: nil,
                error: nil,
                userSessionCanBeTornDown: nil
            )
        }
    }

    public func removeProxyCredentials() {
        guard let proxy = environment.proxy else { return }
        _ = ProxyCredentials.destroy(for: proxy)
    }

    public func saveProxyCredentials(username: String, password: String) {
        guard let proxy = environment.proxy else { return }
        proxyCredentials = ProxyCredentials(username: username, password: password, proxy: proxy)
        do {
            try proxyCredentials?.persist()
            authenticatedSessionFactory.updateProxy(username: username, password: password)
            unauthenticatedSessionFactory.updateProxy(username: username, password: password)
        } catch {
            Logging.network.error("proxy credentials could not be saved - \(error.localizedDescription)")
        }
    }

    public func markNetworkSessionsAsReady(_ ready: Bool) {
        markSessionsAsReady(ready)
        createUnauthenticatedSession()
    }

    private func markSessionsAsReady(_ ready: Bool) {
        reachability.enabled = ready

        // force creation of transport sessions using isUnauthenticatedTransportSessionReady
        isUnauthenticatedTransportSessionReady = ready

        // force creation of unauthenticatedSession
        unauthenticatedSessionFactory.readyForRequests = ready
    }

    public func removeDatabaseFromDisk() {
        guard let account = accountManager.selectedAccount else {
            return
        }
        delete(account: account)
    }

    /// Select the account to be the active account.
    /// - completion: runs when the user session was loaded
    /// - tearDownCompletion: runs when the UI no longer holds any references to the previous user session.
    public func select(
        _ account: Account,
        completion: ((ZMUserSession?) -> Void)? = nil,
        tearDownCompletion: (() -> Void)? = nil
    ) {
        guard !isSelectingAccount else {
            completion?(nil)
            return
        }

        confirmSwitchingAccount { [weak self] isConfirmed in

            guard isConfirmed else {
                completion?(nil)
                return
            }

            self?.isSelectingAccount = true
            let selectedAccount = self?.accountManager.selectedAccount

            guard let delegate = self?.delegate else {
                completion?(nil)
                return
            }
            delegate.sessionManagerWillOpenAccount(
                account,
                from: selectedAccount,
                userSessionCanBeTornDown: { [weak self] in
                    self?.activeUserSession = nil
                    tearDownCompletion?()

                    Task { @MainActor [weak self] in
                        guard let self else {
                            completion?(nil)
                            return
                        }

                        accountManager.select(account)
                        let session = await loadSession(for: account)
                        isSelectingAccount = false

                        if let session {
                            completion?(session)
                        } else {
                            completion?(nil)
                        }
                    }
                }
            )
        }
    }

    public func addAccount(userInfo: [String: Any]? = nil, completion: (() -> Void)? = nil) {
        confirmSwitchingAccount { [weak self] isConfirmed in
            guard isConfirmed else { return }
            let error = NSError(userSessionErrorCode: .addAccountRequested, userInfo: userInfo)
            self?.delegate?.sessionManagerWillLogout(
                environment: nil,
                error: error
            ) { [weak self] in
                self?.activeUserSession = nil
                completion?()
            }
        }
    }

    public func delete(account: Account, eraseData: Bool = true) {
        delete(account: account, reason: .userInitiated, eraseData: eraseData)
    }

    public func wipeDatabase(for account: Account) {
        delete(account: account, reason: .databaseWiped)
    }

    fileprivate func deleteAllAccounts(reason: ZMAccountDeletedReason) {
        accountManager.inactiveAccounts.forEach {
            delete(account: $0, reason: reason)
        }

        if let activeAccount = accountManager.selectedAccount {
            delete(account: activeAccount, reason: reason)
        }
    }

    func delete(account: Account, reason: ZMAccountDeletedReason, eraseData: Bool = true) {
        WireLogger.sessionManager.debug("Deleting account \(account.userIdentifier)...")
        if let secondAccount = accountManager.inactiveAccounts.first {
            // Deleted an account but we can switch to another account
            select(secondAccount, tearDownCompletion: { [weak self] in
                self?.tearDownSessionAndDelete(account: account, eraseData: eraseData)
            })
        } else if accountManager.selectedAccount != account {
            // Deleted an inactive account, there's no need notify the UI
            tearDownSessionAndDelete(account: account, eraseData: eraseData)
        } else {
            // Deleted the last account so we need to return to the logged out area
            logoutCurrentSession(
                deleteCookie: eraseData,
                deleteAccount: eraseData,
                error: NSError(userSessionErrorCode: .accountDeleted, userInfo: [ZMAccountDeletedReasonKey: reason])
            )
        }
    }

    fileprivate func tearDownSessionAndDelete(account: Account, eraseData: Bool) {
        tearDownBackgroundSession(for: account.userIdentifier) {
            if eraseData {
                self.deleteAccountData(for: account)
            }
        }
    }

    public func logout(account: Account, error: Error? = nil) {
        WireLogger.sessionManager.debug("Logging out account \(account.userIdentifier)...")

        if let session = backgroundUserSessions[account.userIdentifier] {
            if session == activeUserSession {
                logoutCurrentSession(deleteCookie: true, deleteAccount: false, error: error)
            } else {
                tearDownBackgroundSession(for: account.userIdentifier)
            }
        }
    }

    public func logoutCurrentSession() {
        logoutCurrentSession(deleteCookie: true, deleteAccount: false, error: nil)
    }

    #if DEBUG
        /// This method is only used in tests and should be deleted. See [WPB-10404].
        func logoutCurrentSessionWithoutDeletingCookie() {
            logoutCurrentSession(deleteCookie: false, deleteAccount: false, error: nil)
        }
    #endif

    fileprivate func deleteTemporaryData() {
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: [F] replace with TemporaryFileServiceInterface
        guard let tmpDirectoryPath = URL(string: NSTemporaryDirectory()) else { return }
        let manager = FileManager.default
        try? manager
            .contentsOfDirectory(
                at: tmpDirectoryPath,
                includingPropertiesForKeys: nil,
                options: .skipsSubdirectoryDescendants
            )
            .forEach { file in
                try? manager.removeItem(atPath: file.path)
            }
    }

    /// Logs out current session optionally deleting account data
    ///
    /// - Note: `deleteCookie == false` is only used for testing. It is not a valid production value and should be
    /// removed. See [WPB-10404].
    fileprivate func logoutCurrentSession(deleteCookie: Bool, deleteAccount: Bool, error: Error?) {
        guard let account = accountManager.selectedAccount else {
            WireLogger.sessionManager.critical("No selected account")
            return
        }

        WireLogger.sessionManager.info("Removing session \(account.userIdentifier) from backgroundUserSessions (count: \(backgroundUserSessions.count))")
        backgroundUserSessions[account.userIdentifier] = nil
        WireLogger.sessionManager.info("After removal, backgroundUserSessions count: \(backgroundUserSessions.count)")
        tearDownObservers(account: account.userIdentifier)
        notifyUserSessionDestroyed(account.userIdentifier)

        createUnauthenticatedSession(accountId: deleteAccount ? nil : account.userIdentifier)

        guard let activeUserSession else {
            WireLogger.sessionManager.critical("No active user session")
            delegate?.sessionManagerWillLogout(
                environment: nil,
                error: error,
                userSessionCanBeTornDown: nil
            )

            if deleteAccount {
                deleteAccountData(for: account)
            }
            return
        }

        requireInternal(activeUserSession.userId == account.userIdentifier, "User session and account are different")

        // TODO: [WPB-19941] Better error handling
        let environment = try? environmentStore.fetchBackendEnvironment(accountID: account.userIdentifier)

        // Store session locally, clear from properties immediately
        let sessionToClose = activeUserSession
        self.activeUserSession = nil

        // Close the session, then notify delegate when done
        sessionToClose.close(deleteCookie: deleteCookie) { [weak self] in
            if deleteAccount {
                self?.deleteAccountData(for: account)
            }

            // Notify delegate that teardown is complete - session should deallocate after this
            self?.delegate?.sessionManagerWillLogout(
                environment: environment,
                error: error,
                userSessionCanBeTornDown: nil
            )
        }
    }

    /// Loads a session for a given account
    ///
    /// - Parameters:
    /// - account: account for which to load the session
    /// - completion: called when session is loaded or when session fails to load

    func loadSession(for account: Account) async -> ZMUserSession? {
        if environment.isAuthenticated(account) {
            return await activateSession(for: account)
        } else if configuration.wipeOnCookieInvalid {
            delete(account: account, reason: .sessionExpired)
        } else {
            createUnauthenticatedSession(accountId: account.userIdentifier)

            let error = NSError(
                userSessionErrorCode: .accessTokenExpired,
                userInfo: account.loginCredentials?.dictionaryRepresentation
            )

            let environment = try? environmentStore.fetchBackendEnvironment(accountID: account.userIdentifier)

            delegate?.sessionManagerWillLogout(
                environment: environment,
                error: error,
                userSessionCanBeTornDown: nil
            )
        }

        return nil
    }

    @MainActor
    fileprivate func activateSession(
        for account: Account,
        newEnvironment: NewEnvironment? = nil
    ) async -> ZMUserSession? {
        guard let session = await withSession(
            for: account,
            newEnvironment: newEnvironment,
            notifyAboutMigration: true
        ) else {
            return nil
        }

        activeUserSession = session

        WireLogger.sessionManager.debug(
            "Activated ZMUserSession for account - "
                + account.userIdentifier.safeForLoggingDescription
        )

        delegate?.sessionManagerDidChangeActiveUserSession(userSession: session)
        configureUserNotifications()

        // If the user isn't logged in it's because they still need
        // to complete the login flow, which will be handle elsewhere.
        if session.isLoggedIn {
            delegate?.sessionManagerDidReportLockChange(forSession: session)
            performPostUnlockActionsIfPossible(for: session)

            await configureAnalytics(for: session)
            await requestCertificateEnrollmentIfNeeded()
        } else {
            WireLogger.sessionManager.debug("User is not logged in, complete login elsewhere")
        }

        return session
    }

    @MainActor
    func configureAnalytics(for userSession: ZMUserSession) async {
        guard let isTrackingEnabled = analyticsService?.isTrackingEnabled, isTrackingEnabled else {
            return
        }

        do {
            WireLogger.analytics.debug("configuring analytics for user session")
            let user = try await userSession.createAnalyticsUser()
            try analyticsService?.switchUser(user)

            userSession.setAnalyticsEventTracker(analyticsService)
        } catch {
            WireLogger.analytics.error("failed to configure analytics for user session: \(error)")
        }
    }

    func performPostUnlockActionsIfPossible(for session: ZMUserSession) {
        guard session.lock == .none else { return }
        processPendingURLActionRequiresAuthentication()
    }

    @MainActor
    func withSession(
        for account: Account,
        newEnvironment: NewEnvironment? = nil,
        notifyAboutMigration: Bool = false
    ) async -> ZMUserSession? {
        WireLogger.sessionManager.debug("Request to load session for \(account)")

        if let session = backgroundUserSessions[account.userIdentifier] {
            WireLogger.sessionManager.debug("Session for \(account) is already loaded")
            return session
        }

        return await withSessionTaskManager.performIfNeeded { @MainActor [self] in
            do {
                let loader = try UserSessionLoader(
                    account: account,
                    accountManager: accountManager,
                    sharedContainerURL: sharedContainerURL,
                    legacyEnvironment: environment,
                    minTLSVersion: minTLSVersion,
                    dispatchGroup: dispatchGroup,
                    sharedUserDefaults: sharedUserDefaults,
                    application: application,
                    appVersion: currentAppVersion,
                    buildNumber: currentBuildNumber,
                    mediaManager: authenticatedSessionFactory.mediaManager,
                    flowManager: authenticatedSessionFactory.flowManager,
                    logFilesProvider: logFilesProvider,
                    isDeveloperModeEnabled: isDeveloperModeEnabled,
                    faultyMLSRemovalKeysByDomain: configuration.faultyMLSRemovalKeysByDomain
                )

                let userSession = try await loader.load(newEnvironment: newEnvironment)
                finishSettingUpUserSession(
                    account: account,
                    newSession: userSession,
                    coreDataStack: userSession.coreDataStack
                )
                return userSession

            } catch UserSessionLoader.Failure.buildIsBlacklisted {
                WireLogger.sessionManager.warn(
                    "build is blacklisted: \(currentBuildNumber)",
                    attributes: .safePublic
                )
                delegate?.sessionManagerDidFailToLoadSession(
                    for: account,
                    error: .buildIsBlacklisted
                )
                return nil
            } catch NetworkStackError.backendAPIVersionObsolete {
                WireLogger.sessionManager.warn(
                    "backend API version is obsolete",
                    attributes: .safePublic
                )
                delegate?.sessionManagerDidFailToLoadSession(
                    for: account,
                    error: .backendIsObsolete
                )
                return nil
            } catch NetworkStackError.clientAPIVersionObsolete {
                WireLogger.sessionManager.warn(
                    "client API version is obsolete",
                    attributes: .safePublic
                )
                delegate?.sessionManagerDidFailToLoadSession(
                    for: account,
                    error: .clientIsObsolete
                )
                return nil
            } catch let error as URLError {
                WireLogger.sessionManager.error(
                    "failed to load user session due to url error code: \(error.errorCode)",
                    attributes: .safePublic
                )
                delegate?.sessionManagerDidFailToLoadSession(
                    for: account,
                    error: .networkError(code: error.errorCode)
                )
                return nil
            } catch let UserSessionLoader.Failure.failedToLoadPersistenceStack(error) {
                WireLogger.sessionManager.error(
                    "failed to load user session: \(String(describing: error))",
                    attributes: .safePublic
                )
                delegate?.sessionManagerDidFailToLoadSession(
                    for: account,
                    error: .databaseError(error)
                )
                return nil
            } catch let error as SafeForLoggingStringConvertible {
                WireLogger.sessionManager.error(
                    "failed to load user session: \(error.safeForLoggingDescription)",
                    attributes: .safePublic
                )
                delegate?.sessionManagerDidFailToLoadSession(
                    for: account,
                    error: .genericError
                )
                return nil
            } catch {
                WireLogger.sessionManager.error(
                    "failed to load user session",
                    attributes: .safePublic
                )
                delegate?.sessionManagerDidFailToLoadSession(
                    for: account,
                    error: .genericError
                )
                return nil
            }
        }
    }

    public func retryStart() {
        delegate?.sessionManagerAsksToRetryStart()
    }

    /// The active user session will be torn down and the app goes into migration state.
    public func prepareForRestoreWithMigration(completion: @escaping () -> Void) {
        guard let delegate else {
            WireLogger.sessionManager.debug("SessionManager.delegate is nil, aborting migration preparation")
            return completion()
        }

        WireLogger.sessionManager.debug("SessionManager.delegate.sessionManagerWillMigrateAccount ...")
        delegate.sessionManagerWillMigrateAccount { [self] in

            WireLogger.sessionManager.debug("... userSessionCanBeTornDown { ... }")

            if let accountID = activeUserSession?.account.userIdentifier {
                tearDownBackgroundSession(for: accountID) { [self] in
                    activeUserSession = nil
                    accountTokens.removeValue(forKey: accountID)
                    completion()
                }
            } else {
                activeUserSession = nil
                completion()
            }
        }
    }

    private func clearCRLExpirationDates(for account: Account) {
        let repository = CRLExpirationDatesRepository(userID: account.userIdentifier)
        repository.removeAllExpirationDates()
    }

    private func clearCacheDirectory() {
        guard let cachesDirectoryPath = cachesDirectory else { return }
        let manager = FileManager.default
        try? manager.removeItem(at: cachesDirectoryPath)
    }

    fileprivate func deleteAccountData(for account: Account) {
        WireLogger.sessionManager.debug("Deleting the data for \(account.userName) -- \(account.userIdentifier)")
        WireLogger.session.debug("Deleting the data for account \(account)")
        environment.cookieStorage(for: account).deleteKeychainItems()
        account.deleteKeychainItems()

        clearCRLExpirationDates(for: account)

        deleteUserLogs?()

        // also deletes ZMSLogs from cache
        clearCacheDirectory()

        // Clear tmp directory when the user logout from the session.
        deleteTemporaryData()

        Journal(userID: account.userIdentifier, storage: sharedUserDefaults).erase()
        PrivateUserDefaults.removeAll(forUserID: account.userIdentifier, in: sharedUserDefaults)
        PrivateUserDefaults.removeAll(forUserID: account.userIdentifier, in: .standard)

        let accountID = account.userIdentifier
        accountManager.remove(account)

        do {
            try FileManager.default.removeItem(at: CoreDataStack.accountDataFolder(
                accountIdentifier: accountID,
                applicationContainer: sharedContainerURL
            ))
        } catch {
            WireLogger.sessionManager.critical("Impossible to delete the account \(account): \(error)")
        }
    }

    fileprivate func registerObservers(account: Account, session: ZMUserSession) {

        let selfUser = ZMUser.selfUser(in: session.viewContext)
        let teamObserver = TeamChangeInfo.add(
            observer: self,
            for: nil,
            managedObjectContext: session.managedObjectContext
        )
        let selfObserver = UserChangeInfo.add(observer: self, for: selfUser, in: session.managedObjectContext)
        let conversationListObserver = ConversationListChangeInfo.add(
            observer: self,
            for: ConversationList.conversations(inUserSession: session)!,
            userSession: session
        )
        let connectionRequestObserver = ConversationListChangeInfo.add(
            observer: self,
            for: ConversationList.pendingConnectionConversations(inUserSession: session)!,
            userSession: session
        )

        let databaseEncryptionObserverToken = session.registerDatabaseLockedHandler { [weak self] _ in
            guard session == self?.activeUserSession else { return }
            self?.delegate?.sessionManagerDidReportLockChange(forSession: session)
        }

        accountTokens[account.userIdentifier] = [
            teamObserver,
            selfObserver!,
            conversationListObserver,
            connectionRequestObserver,
            databaseEncryptionObserverToken
        ]
    }

    @discardableResult
    func createUnauthenticatedSession(accountId: UUID? = nil) -> UnauthenticatedSession {
        WireLogger.sessionManager.debug("Creating unauthenticated session")
        let unauthenticatedSession = unauthenticatedSessionFactory.session(
            delegate: self,
            authenticationStatusDelegate: self
        )
        unauthenticatedSession.accountId = accountId
        self.unauthenticatedSession = unauthenticatedSession
        return unauthenticatedSession
    }

    fileprivate func configure(session userSession: ZMUserSession, for account: Account) {
        // we can go and activate Reachability
        markSessionsAsReady(true)
        userSession.sessionManager = self
        userSession.delegate = self
        require(backgroundUserSessions[account.userIdentifier] == nil, "User session is already loaded")
        backgroundUserSessions[account.userIdentifier] = userSession
        userSession.useConstantBitRateAudio = useConstantBitRateAudio
        userSession.usePackagingFeatureConfig = usePackagingFeatureConfig
        configurePushToken(session: userSession)
        registerObservers(account: account, session: userSession)
    }

    private func deleteMessagesOlderThanRetentionLimit(contextProvider: ContextProvider) {
        guard let messageRetentionInternal = configuration.messageRetentionInterval else { return }

        WireLogger.sessionManager
            .debug("Deleting messages older than the retention limit = \(messageRetentionInternal)")

        contextProvider.syncContext.performGroupedBlock {
            do {
                try ZMMessage.deleteMessagesOlderThan(
                    Date(timeIntervalSinceNow: -messageRetentionInternal),
                    context: contextProvider.syncContext
                )
            } catch {
                WireLogger.sessionManager.error("Failed to delete messages older than the retention limit")
            }
        }
    }

    // Creates the user session for @c account given, calls @c completion when done.
    @MainActor
    private func startBackgroundSession(
        for account: Account,
        with coreDataStack: CoreDataStack,
        journal: Journal,
        logFilesProvider: LogFilesProviding
    ) -> ZMUserSession {
        guard let newSession = createUserSession(
            for: account,
            with: coreDataStack,
            journal: journal,
            logFilesProvider: logFilesProvider
        ) else {
            preconditionFailure("Unable to create session for \(account)")
        }

        finishSettingUpUserSession(
            account: account,
            newSession: newSession,
            coreDataStack: coreDataStack
        )

        return newSession
    }

    @MainActor
    private func createUserSession(
        for account: Account,
        with coreDataStack: CoreDataStack,
        journal: Journal,
        logFilesProvider: LogFilesProviding
    ) -> ZMUserSession? {
        let sessionConfig = ZMUserSession.Configuration(
            appLockConfig: configuration.legacyAppLockConfig
        )

        return authenticatedSessionFactory.session(
            for: account,
            coreDataStack: coreDataStack,
            configuration: sessionConfig,
            sharedUserDefaults: sharedUserDefaults,
            isDeveloperModeEnabled: isDeveloperModeEnabled,
            journal: journal,
            logFilesProvider: logFilesProvider,
            faultyMLSRemovalKeysByDomain: configuration.faultyMLSRemovalKeysByDomain
        )
    }

    @MainActor
    private func finishSettingUpUserSession(
        account: Account,
        newSession: ZMUserSession,
        coreDataStack: CoreDataStack
    ) {
        configure(session: newSession, for: account)
        deleteMessagesOlderThanRetentionLimit(contextProvider: coreDataStack)
        updateSystemBootTimeIfNeeded()

        WireLogger.sessionManager
            .debug(
                "Created ZMUserSession for account \(String(describing: account.userName)) — \(account.userIdentifier)"
            )
        notifyNewUserSessionCreated(newSession)
    }

    func tearDownBackgroundSession(for accountId: UUID, completion: (() -> Void)? = nil) {
        guard let userSession = backgroundUserSessions[accountId] else {
            WireLogger.sessionManager
                .error("No session to tear down for \(accountId), known sessions: \(backgroundUserSessions)")
            completion?()
            return
        }
        tearDownObservers(account: accountId)
        backgroundUserSessions[accountId] = nil

        dispatchGroup.enter()
        userSession.close(deleteCookie: false) { [weak self] in
            self?.notifyUserSessionDestroyed(accountId)
            completion?()
            self?.dispatchGroup.leave()
        }

    }

    // Tears down and releases all background user sessions.
    func tearDownAllBackgroundSessions() {
        let backgroundSessions = backgroundUserSessions.filter { _, session in
            activeUserSession != session
        }

        backgroundSessions.keys.forEach {
            tearDownBackgroundSession(for: $0)
        }
    }

    fileprivate func tearDownObservers(account: UUID) {
        accountTokens.removeValue(forKey: account)
    }

    deinit {
        DispatchQueue
            .main
            .async { [backgroundUserSessions, unauthenticatedSession, reachability] in
                backgroundUserSessions.values.forEach { session in
                    session.tearDown()
                }
                unauthenticatedSession?.tearDown()
                reachability.tearDown()
            }

        if let memoryWarningObserver {
            NotificationCenter.default.removeObserver(memoryWarningObserver)
        }
    }

    public var isUserSessionActive: Bool {
        activeUserSession != nil
    }

    public var callNotificationStyle: CallNotificationStyle = .callKit {
        didSet {
            updateCallNotificationStyle()

        }
    }

    public func updateCallKitConfiguration() {
        callKitManager.updateConfiguration()
    }

    private func updateCallNotificationStyle() {
        switch callNotificationStyle {
        case .pushNotifications:
            authenticatedSessionFactory.mediaManager.setUiStartsAudio(false)
            callKitManager.isEnabled = false

        case .callKit:
            // Should be set to true when CallKit is used. Then AVS will not start
            // the audio before the audio session is active
            authenticatedSessionFactory.mediaManager.setUiStartsAudio(true)
            callKitManager.isEnabled = true
        }
    }

    public var useConstantBitRateAudio: Bool = false {
        didSet {
            activeUserSession?.useConstantBitRateAudio = useConstantBitRateAudio
        }
    }

    public var usePackagingFeatureConfig: Bool = false {
        didSet {
            activeUserSession?.usePackagingFeatureConfig = usePackagingFeatureConfig
        }
    }

    func checkJailbreakIfNeeded() {
        guard configuration.blockOnJailbreakOrRoot || configuration.wipeOnJailbreakOrRoot else { return }

        if jailbreakDetector?.isJailbroken() == true {

            if configuration.wipeOnJailbreakOrRoot {
                deleteAllAccounts(reason: .jailbreakDetected)
            }

            delegate?.sessionManagerDidBlacklistJailbrokenDevice()
            // When the device is jailbroken we don't want have a
            // transition to any other state in the UI, so we won't inform it
            // anymore by setting the delegate to nil.
            delegate = nil
        }
    }

    func shouldPerformPostRebootLogout() -> Bool {
        guard configuration.authenticateAfterReboot,
              accountManager.selectedAccount != nil,
              let systemBootTime = ProcessInfo.processInfo.bootTime(),
              let previousSystemBootTime = SessionManager.previousSystemBootTime,
              abs(systemBootTime.timeIntervalSince(previousSystemBootTime)) > 1.0
        else { return false }

        WireLogger.sessionManager
            .debug(
                "Will logout due to device reboot. Previous boot time: \(previousSystemBootTime). Current boot time: \(systemBootTime)"
            )
        return true
    }

    func performPostRebootLogout() {
        let error = NSError(
            userSessionErrorCode: .needsAuthenticationAfterReboot,
            userInfo: accountManager.selectedAccount?.loginCredentials?.dictionaryRepresentation
        )
        logoutCurrentSession(deleteCookie: true, deleteAccount: false, error: error)
        WireLogger.sessionManager.debug("Logout caused by device reboot.")
    }

    func updateSystemBootTimeIfNeeded() {
        guard configuration.authenticateAfterReboot, let bootTime = ProcessInfo.processInfo.bootTime() else {
            return
        }

        SessionManager.previousSystemBootTime = bootTime
        WireLogger.sessionManager.debug("Updated system boot time: \(bootTime)")
    }

    public func passwordVerificationDidFail(with failCount: Int) {
        guard let count = configuration.failedPasswordThresholdBeforeWipe,
              failCount >= count, let account = accountManager.selectedAccount else {
            return
        }
        delete(account: account, reason: .failedPasswordLimitReached)
    }
}

// MARK: - TeamObserver

extension SessionManager {
    func updateCurrentAccount(in managedObjectContext: NSManagedObjectContext) {
        let selfUser = ZMUser.selfUser(in: managedObjectContext)

        // Nothing to update if the user hasn't been registerd yet.
        guard let id = selfUser.remoteIdentifier else {
            return
        }

        if let account = accountManager.account(with: id) {
            if let name = selfUser.team?.name {
                account.teamName = name
            }
            if let userName = selfUser.name {
                account.userName = userName
            }
            if let userProfileImage = selfUser.imageSmallProfileData {
                account.imageData = userProfileImage
            }
            if let teamImageData = selfUser.team?.imageData {
                account.teamImageData = teamImageData
            }
            if let handle = selfUser.handle {
                account.handle = handle
            }

            account.loginCredentials = selfUser.loginCredentials

            // an optional `teamImageData` image could be saved here
            accountManager.addOrUpdate(account)
        }
    }
}

extension SessionManager: TeamObserver {
    public func teamDidChange(_ changeInfo: TeamChangeInfo) {
        let team = changeInfo.team
        guard let managedObjectContext = (team as? WireDataModel.Team)?.managedObjectContext else {
            return
        }
        updateCurrentAccount(in: managedObjectContext)
    }
}

// MARK: - ZMUserObserving

extension SessionManager: UserObserving {
    public func userDidChange(_ changeInfo: UserChangeInfo) {
        if changeInfo.teamsChanged || changeInfo.nameChanged || changeInfo.imageSmallProfileDataChanged {
            guard let user = changeInfo.user as? ZMUser,
                  let managedObjectContext = user.managedObjectContext else {
                return
            }
            updateCurrentAccount(in: managedObjectContext)
        }

        if changeInfo.analyticsIdentifierChanged {
            guard
                let isTrackingEnabled = analyticsService?.isTrackingEnabled,
                isTrackingEnabled,
                changeInfo.user.isSelfUser,
                let userSession = activeUserSession
            else {
                return
            }

            Task {
                do {
                    try await analyticsService?.updateCurrentUser(userSession.createAnalyticsUser())
                } catch {
                    WireLogger.analytics.error("failed to update current user: \(error)")
                }
            }
        }
    }
}

// MARK: - UnauthenticatedSessionDelegate

public extension SessionManager {

    /// Needs to be called before we try to register another device because API requires password
    func update(credentials: UserCredentials) -> Bool {
        guard let userSession = activeUserSession,
              let emailCredentials = credentials as? UserEmailCredentials else { return false }

        userSession.setEmailCredentials(emailCredentials)
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
        return true
    }
}

extension SessionManager: UnauthenticatedSessionDelegate {

    public func sessionIsAllowedToCreateNewAccount(
        _ session: UnauthenticatedSession
    ) -> Bool {
        accountManager.numberOfAccounts < maxNumberAccounts
    }

    public func session(
        session: UnauthenticatedSession,
        isExistingAccount account: Account
    ) -> Bool {
        accountManager.account(with: account.userIdentifier) != nil
    }

    public func session(
        session: UnauthenticatedSession,
        updatedCredentials credentials: UserCredentials
    ) -> Bool {
        update(credentials: credentials)
    }

    public func session(
        session: UnauthenticatedSession,
        createdAccount account: Account,
        newEnvironment: NewEnvironment? = nil
    ) {
        let numberOfExistingAccounts = accountManager.numberOfAccounts
        let createdAccountIsKnown = accountManager.account(with: account.userIdentifier) != nil

        guard
            numberOfExistingAccounts < maxNumberAccounts || createdAccountIsKnown
        else {
            let error = NSError(userSessionErrorCode: .accountLimitReached, userInfo: nil)
            loginDelegate?.authenticationDidFail(error)
            return
        }

        accountManager.addAndSelect(account)

        Task { @MainActor in
            guard let userSession = await activateSession(
                for: account,
                newEnvironment: newEnvironment
            ) else {
                return
            }

            updateCurrentAccount(in: userSession.managedObjectContext)

            switch session.backupImportDidSucceed {
            case true?:
                userSession.trackAnalyticsEvent(.Backup.restored)
            case false?:
                userSession.trackAnalyticsEvent(.Backup.restoredFailed)
            case nil:
                break
            }

            let registered = session.authenticationStatus.completedRegistration || session.registrationStatus
                .completedRegistration
            let emailCredentials = session.authenticationStatus.emailCredentials()

            userSession.syncManagedObjectContext.performGroupedBlock {
                userSession.setEmailCredentials(emailCredentials)
                userSession.syncManagedObjectContext.registeredOnThisDevice = registered
                ZMMessage.deleteOldEphemeralMessages(userSession.syncManagedObjectContext)
            }
        }
    }
}

// MARK: AccountDeletedObserver

extension SessionManager: AccountDeletedObserver {
    public func accountDeleted(accountId: UUID) {
        WireLogger.sessionManager.debug("\(accountId): Account was deleted")

        if let account = accountManager.account(with: accountId) {
            delete(account: account, reason: .sessionExpired)
        }
    }
}

// MARK: - Application lifetime notifications

extension SessionManager {
    @objc
    private func applicationWillEnterForeground(_ note: Notification) {

        BackgroundActivityFactory.shared.resume()

        updateAllUnreadCounts()
        checkJailbreakIfNeeded()

        // Delete expired url scheme verification tokens
        CompanyLoginVerificationToken.flushIfNeeded()

        if let session = activeUserSession {
            // If the user isn't logged in it's because they still need
            // to complete the login flow, which will be handle elsewhere.
            if session.isLoggedIn {
                session.trackAppOpenAnalyticEventWhenAppBecomesActive()
                delegate?.sessionManagerDidReportLockChange(forSession: session)
                Task {
                    await self.requestCertificateEnrollmentIfNeeded()
                }
            }
        }
    }

    @objc
    func applicationWillResignActive(_ note: Notification) {
        activeUserSession?.appLockController.beginTimer()
    }

    @objc
    private func applicationDidBecomeActive(_ note: Notification) {
        guard let session = activeUserSession, session.isLoggedIn else { return }
        session.checkE2EICertificateExpiryStatus()
    }

}

// MARK: - Unread Conversation Count

extension SessionManager: ZMConversationListObserver {

    public func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {

        // find which account/session the conversation list belongs to & update count
        guard let moc = changeInfo.conversationList.managedObjectContext else { return }

        for (accountId, session) in backgroundUserSessions where session.managedObjectContext == moc {
            updateUnreadCount(for: accountId)
        }
    }

    fileprivate func updateUnreadCount(for accountID: UUID) {
        guard
            let account = accountManager.account(with: accountID),
            let session = backgroundUserSessions[accountID]
        else {
            return
        }

        account.unreadConversationCount = Int(ZMConversation.unreadConversationCount(in: session.managedObjectContext))
        accountManager.addOrUpdate(account)
    }

    fileprivate func updateAllUnreadCounts() {
        for accountID in backgroundUserSessions.keys {
            updateUnreadCount(for: accountID)
        }
    }

    public func updateAppIconBadge(accountID: UUID, unreadCount: Int) {
        DispatchQueue.main.async {
            if let account = self.accountManager.account(with: accountID) {
                account.unreadConversationCount = unreadCount
                self.accountManager.addOrUpdate(account)
            }

            let totalUnreadCount = self.accountManager.totalUnreadCount
            self.application.applicationIconBadgeNumber = totalUnreadCount
            WireLogger.notifications
                .debug("Updated badge count to \(SanitizedString(stringLiteral: String(totalUnreadCount)))")
        }
    }
}

extension SessionManager: WireCallCenterCallStateObserver {

    public func callCenterDidChange(
        callState: CallState,
        conversation: ZMConversation,
        caller: WireDataModel.UserType,
        timestamp: Date?,
        previousCallState: CallState?
    ) {
        guard let moc = conversation.managedObjectContext else { return }

        switch callState {
        case .answered, .outgoing:
            for (_, session) in backgroundUserSessions
                where session.managedObjectContext == moc && activeUserSession != session {
                showConversation(conversation, at: nil, in: session)
            }
        default:
            return
        }
    }

}

public extension SessionManager {

    /// The SSO code provided by the user when clicking their company link. Points to a UUID object.
    static var companyLoginCodeKey: String {
        "WireCompanyLoginCode"
    }

    /// The timestamp when the user initiated the request.
    static var companyLoginRequestTimestampKey: String {
        "WireCompanyLoginTimesta;p"
    }
}

// MARK: - End-to-end Identity

extension SessionManager {

    public func didEnrollCertificateSuccessfully() {
        delegate?.sessionManagerDidEnrollCertificate(for: activeUserSession)
    }

    private func requestCertificateEnrollmentIfNeeded() async {
        guard let userSession = activeUserSession else { return }

        do {
            let isE2EICertificateEnrollmentRequired = try await userSession.isE2EICertificateEnrollmentRequired.invoke()
            if isE2EICertificateEnrollmentRequired {
                delegate?.sessionManagerRequireCertificateEnrollment()
            }
        } catch {
            WireLogger.e2ei.warn("Can't get certificate enrollment status: \(error)")
        }
    }

}

// MARK: - Session manager observer

@objc
public protocol SessionManagerCreatedSessionObserver: AnyObject {
    /// Invoked when the SessionManager creates a user session either by
    /// activating one or creating one in the background. No assumption should
    /// be made that the session is active.
    func sessionManagerCreated(userSession: ZMUserSession)

    /// Invoked when the SessionManager creates a new unauthenticated session.
    func sessionManagerCreated(unauthenticatedSession: UnauthenticatedSession)
}

@objc
public protocol SessionManagerDestroyedSessionObserver: AnyObject {
    /// Invoked when the SessionManager tears down the user session associated
    /// with the accountId.
    func sessionManagerDestroyedUserSession(for accountId: UUID)
}

private let sessionManagerCreatedUnauthenticatedSessionNotificationName = Notification
    .Name(rawValue: "ZMSessionManagerCreatedUnauthenticatedSessionNotification")
private let sessionManagerCreatedSessionNotificationName = Notification
    .Name(rawValue: "ZMSessionManagerCreatedSessionNotification")
private let sessionManagerDestroyedSessionNotificationName = Notification
    .Name(rawValue: "ZMSessionManagerDestroyedSessionNotification")

extension SessionManager: NotificationContext {

    public func addUnauthenticatedSessionManagerCreatedSessionObserver(_ observer: SessionManagerCreatedSessionObserver)
        -> Any {
        NotificationInContext.addObserver(
            name: sessionManagerCreatedUnauthenticatedSessionNotificationName,
            context: self
        ) { [weak observer] note in observer?
            .sessionManagerCreated(unauthenticatedSession: note.object as! UnauthenticatedSession)
        }
    }

    public func addSessionManagerCreatedSessionObserver(_ observer: SessionManagerCreatedSessionObserver) -> Any {
        NotificationInContext.addObserver(
            name: sessionManagerCreatedSessionNotificationName,
            context: self
        ) { [weak observer] note in observer?
            .sessionManagerCreated(userSession: note.object as! ZMUserSession)
        }
    }

    public func addSessionManagerDestroyedSessionObserver(_ observer: SessionManagerDestroyedSessionObserver) -> Any {
        NotificationInContext.addObserver(
            name: sessionManagerDestroyedSessionNotificationName,
            context: self
        ) { [weak observer] note in observer?
            .sessionManagerDestroyedUserSession(for: note.object as! UUID)
        }
    }

    fileprivate func notifyNewUserSessionCreated(_ userSession: ZMUserSession) {
        NotificationInContext(name: sessionManagerCreatedSessionNotificationName, context: self, object: userSession)
            .post()
    }

    fileprivate func notifyUserSessionDestroyed(_ accountId: UUID) {
        NotificationInContext(
            name: sessionManagerDestroyedSessionNotificationName,
            context: self,
            object: accountId as AnyObject
        ).post()
    }
}

public extension SessionManager {

    func confirmSwitchingAccount(completion: @escaping (_ isConfirmed: Bool) -> Void) {
        guard
            let switchingDelegate,
            let activeUserSession,
            activeUserSession.isCallOngoing
        else {
            // no confirmation to show if no call is ongoing
            return completion(true)
        }

        switchingDelegate.confirmSwitchingAccount { confirmed in
            if confirmed {
                activeUserSession.callCenter?.endAllCalls()
            }
            completion(confirmed)
        }
    }
}

// MARK: - AVS Logging

public extension SessionManager {

    static func startAVSLogging() {
        avsLogObserver = AVSLogObserver()
    }

    static func stopAVSLogging() {
        avsLogObserver = nil
    }
}

// MARK: - User session delegate

extension SessionManager: UserSessionDelegate {

    func userSessionDidDiscoverBuildIsBlacklisted() {
        delegate?.sessionManagerDidBlacklistCurrentVersion(reason: .appVersionBlacklisted)
    }

}

// MARK: - Failures

public extension SessionManager {

    enum SessionLoadingFailure: Error {

        case buildIsBlacklisted
        case backendIsObsolete
        case clientIsObsolete
        case networkError(code: Int)
        case genericError
        case databaseError(Error)

    }

}
