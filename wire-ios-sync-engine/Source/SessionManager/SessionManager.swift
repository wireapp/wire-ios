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
import CallKit
import Foundation
import PushKit
import UserNotifications
import WireAnalytics
import WireDataModel
import WireRequestStrategy
import WireTransport
import WireUtilities

public typealias LaunchOptions = [UIApplication.LaunchOptionsKey: Any]

public extension Bundle {
    @objc var appGroupIdentifier: String? {
        return bundleIdentifier.map { "group." + $0 }
    }
}

@objc public enum CallNotificationStyle: UInt {
    case pushNotifications
    case callKit
}

public protocol SessionActivationObserver: AnyObject {
    func sessionManagerDidChangeActiveUserSession(userSession: ZMUserSession)
    func sessionManagerDidReportLockChange(forSession session: UserSession)
}

// sourcery: AutoMockable
public protocol SessionManagerDelegate: AnyObject, SessionActivationObserver {
    func sessionManagerDidFailToLogin(error: Error?)
    func sessionManagerWillLogout(error: Error?, userSessionCanBeTornDown: (() -> Void)?)
    func sessionManagerWillOpenAccount(_ account: Account,
                                       from selectedAccount: Account?,
                                       userSessionCanBeTornDown: @escaping () -> Void)
    func sessionManagerWillMigrateAccount(userSessionCanBeTornDown: @escaping () -> Void)
    func sessionManagerDidFailToLoadDatabase(error: Error)
    func sessionManagerDidBlacklistCurrentVersion(reason: BlacklistReason)
    func sessionManagerDidBlacklistJailbrokenDevice()
    func sessionManagerRequireCertificateEnrollment()
    func sessionManagerDidEnrollCertificate(for activeSession: UserSession?)

    func sessionManagerDidPerformFederationMigration(activeSession: UserSession?)
    func sessionManagerDidPerformAPIMigrations(activeSession: UserSession?)
    func sessionManagerAsksToRetryStart()
    func sessionManagerDidCompleteInitialSync(for activeSession: UserSession?)

    var isInAuthenticatedAppState: Bool { get }
    var isInUnathenticatedAppState: Bool { get }
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
    func showConversation(_ conversation: ZMConversation,
                          at message: ZMConversationMessage?,
                          in session: ZMUserSession)

    /// Switch account and and ask UI to navigate to the conversatio list
    func showConversationList(in session: ZMUserSession)

    /// ask UI to open the profile of a user
    func showUserProfile(user: UserType)

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
    func shouldPresentNotification(with userInfo: NotificationUserInfo) -> Bool
}

/// Manage the creation of `ZMUserSession` and `UnauthenticatedSession` objects and
/// the switching between them.
///
/// There are multiple things neccessary in order to store (and switch between) multiple accounts on one device, a couple of them are:
/// 1. The folder structure in the app sandbox has to be modeled in a way in which files can be associated with a single account.
/// 2. The login flow should not rely on any persistent state (e.g. no database has to be created on disk before being logged in).
/// 3. There has to be a persistence layer storing information about accounts and the currently selected / active account.
///
/// The wire account database and a couple of other related files are stored in the shared container in a folder named by the accounts
/// `remoteIdentifier`. All information about different accounts on a device are stored by the `AccountManager` (see the documentation
/// of that class for more information). The `SessionManager`s main responsibility at the moment is checking whether there is a selected
/// `Account` or not, and creating an `UnauthenticatedSession` or `ZMUserSession` accordingly. An `UnauthenticatedSession` is used
/// to create requests to either log in existing users or to register new users. It uses its own `UnauthenticatedOperationLoop`,
/// which is a stripped down version of the regular `ZMOperationLoop`. This unauthenticated operation loop only uses a small subset
/// of transcoders needed to perform the login / registration (and related phone number verification) requests. For more information
/// see `UnauthenticatedOperationLoop`.
///
/// The result of using an `UnauthenticatedSession` is retrieving a remoteIdentifier of a logged in user, as well as a valid cookie.
/// Once those became available, the session will notify the session manager, which in turn will create a regular `ZMUserSession`.
/// For more information about the cookie retrieval consult the documentation in `UnauthenticatedSession`.
///
/// The flow creating either an `UnauthenticatedSession` or `ZMUserSession` after creating an instance of `SessionManager`
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
/// | Check if there is a database present   |        YES           Open the existing database, retrieve the user identifier,
/// | in the legacy directory (not keyed by  |  +-------------->    create an account with it and select it. Migrate the existing
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

    public let appVersion: String
    var isAppVersionBlacklisted = false
    public weak var delegate: SessionManagerDelegate?
    public let accountManager: AccountManager
    public weak var loginDelegate: LoginDelegate?

    public internal(set) var activeUserSession: ZMUserSession? {
        willSet {
            guard activeUserSession != newValue else { return }
            activeUserSession?.appLockController.beginTimer()
            activeUserSession?.setAnalyticsEventTracker(nil)
        }
    }

    public private(set) var backgroundUserSessions = [UUID: ZMUserSession]() {
        didSet {
            VoIPPushHelper.setLoadedUserSessions(
                accountIDs: Array(backgroundUserSessions.keys)
            )
        }
    }

    public internal(set) var unauthenticatedSession: UnauthenticatedSession? {
        willSet {
            self.unauthenticatedSession?.tearDown()
        }
        didSet {
            if let session = self.unauthenticatedSession {

                NotificationInContext(name: sessionManagerCreatedUnauthenticatedSessionNotificationName, context: self, object: session).post()
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
    var blacklistVerificator: ZMBlacklistVerificator?
    var pushRegistry: PushRegistry
    let configuration: SessionManagerConfiguration
    var pendingURLAction: URLAction?
    let apiMigrationManager: APIMigrationManager

    var notificationCenter: UserNotificationCenterAbstraction = .wrapper(.current())

    var authenticatedSessionFactory: AuthenticatedSessionFactory
    let unauthenticatedSessionFactory: UnauthenticatedSessionFactory

    private let sessionLoadingQueue: DispatchQueue = DispatchQueue(label: "sessionLoadingQueue")

    private(set) var reachability: ReachabilityWrapper

    public internal(set) var environment: BackendEnvironmentProvider {
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

    var proxyCredentials: ProxyCredentials?

    public let callKitManager: CallKitManagerInterface

    public var isSelectedAccountAuthenticated: Bool {
        guard let selectedAccount = accountManager.selectedAccount else {
            return false
        }

        return environment.isAuthenticated(selectedAccount)
    }

    public var activeUnauthenticatedSession: UnauthenticatedSession {
        return unauthenticatedSession ?? createUnauthenticatedSession()
    }

    private static var avsLogObserver: AVSLogObserver?

    var apiVersionResolver: APIVersionResolver?

    private(set) var isUnauthenticatedTransportSessionReady: Bool

    public var requiredPushTokenType: PushToken.TokenType

    let isDeveloperModeEnabled: Bool

    let pushTokenService: PushTokenServiceInterface

    var cachesDirectory: URL? {
        let manager = FileManager.default
        return manager.urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    private let minTLSVersion: String?

    let analyticsService: AnalyticsService

    public override init() {
        fatal("init() not implemented")
    }

    private let sharedUserDefaults: UserDefaults

    public convenience init(
        maxNumberAccounts: Int = defaultMaxNumberAccounts,
        appVersion: String,
        mediaManager: MediaManagerType,
        delegate: SessionManagerDelegate?,
        application: ZMApplication,
        dispatchGroup: ZMSDispatchGroup? = nil,
        environment: BackendEnvironmentProvider,
        configuration: SessionManagerConfiguration = SessionManagerConfiguration(),
        detector: JailbreakDetectorProtocol = JailbreakDetector(),
        requiredPushTokenType: PushToken.TokenType,
        pushTokenService: PushTokenServiceInterface = PushTokenService(),
        callKitManager: CallKitManagerInterface,
        isDeveloperModeEnabled: Bool = false,
        isUnauthenticatedTransportSessionReady: Bool = false,
        sharedUserDefaults: UserDefaults,
        minTLSVersion: String?,
        deleteUserLogs: @escaping () -> Void,
        analyticsServiceConfiguration: AnalyticsServiceConfiguration?
    ) {
        let flowManager = FlowManager(mediaManager: mediaManager)
        let reachability = environment.reachabilityWrapper()

        var proxyCredentials: ProxyCredentials?

        if let proxy = environment.proxy {
            proxyCredentials = ProxyCredentials.retrieve(for: proxy)
        }

        let dispatchGroup = dispatchGroup ?? ZMSDispatchGroup(label: "WireSyncEngine.SessionManager.private")

        let unauthenticatedSessionFactory = UnauthenticatedSessionFactory(
            appVersion: appVersion,
            environment: environment,
            proxyUsername: proxyCredentials?.username,
            proxyPassword: proxyCredentials?.password,
            reachability: reachability
        )

        let authenticatedSessionFactory = AuthenticatedSessionFactory(
            appVersion: appVersion,
            application: application,
            mediaManager: mediaManager,
            flowManager: flowManager,
            environment: environment,
            proxyUsername: proxyCredentials?.username,
            proxyPassword: proxyCredentials?.password,
            reachability: reachability,
            minTLSVersion: minTLSVersion
        )

        self.init(
            maxNumberAccounts: maxNumberAccounts,
            appVersion: appVersion,
            authenticatedSessionFactory: authenticatedSessionFactory,
            unauthenticatedSessionFactory: unauthenticatedSessionFactory,
            reachability: reachability,
            delegate: delegate,
            application: application,
            pushRegistry: PKPushRegistry(queue: nil),
            dispatchGroup: dispatchGroup,
            environment: environment,
            configuration: configuration,
            detector: detector,
            requiredPushTokenType: requiredPushTokenType,
            pushTokenService: pushTokenService,
            callKitManager: callKitManager,
            isDeveloperModeEnabled: isDeveloperModeEnabled,
            proxyCredentials: proxyCredentials,
            isUnauthenticatedTransportSessionReady: isUnauthenticatedTransportSessionReady,
            sharedUserDefaults: sharedUserDefaults,
            minTLSVersion: minTLSVersion,
            deleteUserLogs: deleteUserLogs,
            analyticsServiceConfiguration: analyticsServiceConfiguration
        )

        configureBlacklistDownload()

        memoryWarningObserver = NotificationCenter.default.addObserver(
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

    init(maxNumberAccounts: Int = defaultMaxNumberAccounts,
         appVersion: String,
         authenticatedSessionFactory: AuthenticatedSessionFactory,
         unauthenticatedSessionFactory: UnauthenticatedSessionFactory,
         reachability: ReachabilityWrapper,
         delegate: SessionManagerDelegate?,
         application: ZMApplication,
         pushRegistry: PushRegistry,
         dispatchGroup: ZMSDispatchGroup,
         environment: BackendEnvironmentProvider,
         configuration: SessionManagerConfiguration = SessionManagerConfiguration(),
         detector: JailbreakDetectorProtocol = JailbreakDetector(),
         requiredPushTokenType: PushToken.TokenType,
         pushTokenService: PushTokenServiceInterface = PushTokenService(),
         callKitManager: CallKitManagerInterface,
         isDeveloperModeEnabled: Bool = false,
         proxyCredentials: ProxyCredentials?,
         isUnauthenticatedTransportSessionReady: Bool = false,
         sharedUserDefaults: UserDefaults,
         minTLSVersion: String? = nil,
         deleteUserLogs: (() -> Void)? = nil,
         analyticsServiceConfiguration: AnalyticsServiceConfiguration?
    ) {
        SessionManager.enableLogsByEnvironmentVariable()
        self.environment = environment
        self.appVersion = appVersion
        self.application = application
        self.delegate = delegate
        self.dispatchGroup = dispatchGroup
        self.configuration = configuration.copy() as! SessionManagerConfiguration
        self.jailbreakDetector = detector
        self.requiredPushTokenType = requiredPushTokenType
        self.pushTokenService = pushTokenService
        self.callKitManager = callKitManager
        self.proxyCredentials = proxyCredentials
        self.isUnauthenticatedTransportSessionReady = isUnauthenticatedTransportSessionReady
        self.sharedUserDefaults = sharedUserDefaults
        self.minTLSVersion = minTLSVersion
        self.deleteUserLogs = deleteUserLogs

        guard let sharedContainerURL = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else {
            preconditionFailure("Unable to get shared container URL")
        }

        self.sharedContainerURL = sharedContainerURL
        self.accountManager = AccountManager(sharedDirectory: sharedContainerURL)

        WireLogger.sessionManager.debug("Starting the session manager:")

        if self.accountManager.accounts.count > 0 {
            WireLogger.sessionManager.debug("Known accounts:")
            self.accountManager.accounts.forEach { account in
                WireLogger.sessionManager.debug("\(account.userName) -- \(account.userIdentifier) -- \(account.teamName ?? "no team")")
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
        self.pushRegistry = pushRegistry
        self.maxNumberAccounts = maxNumberAccounts
        self.isDeveloperModeEnabled = isDeveloperModeEnabled
        self.apiMigrationManager = APIMigrationManager(
            migrations: [AccessTokenMigration()]
        )

        // we must set these before initializing the PushDispatcher b/c if the app
        // received a push from terminated state, it requires these properties to be
        // non nil in order to process the notification
        BackgroundActivityFactory.shared.activityManager = UIApplication.shared

        let analyticsConfig = analyticsServiceConfiguration.map {
            AnalyticsService.Config(
                secretKey: $0.secretKey,
                serverHost: $0.serverHost
            )
        }

        analyticsService = AnalyticsService(
            config: analyticsConfig,
            logger: { WireLogger.analytics.debug($0) }
        )

        if analyticsServiceConfiguration?.didUserGiveTrackingConsent == true {
            Task { [analyticsService] in
                do {
                    try await analyticsService.enableTracking()
                } catch {
                    WireLogger.analytics.error("failed to enable tracking: \(error)")
                }
            }
        }

        super.init()

        callKitManager.setDelegate(self)
        updateCallNotificationStyle()

        pushTokenService.onTokenChange = { [weak self] _ in
            guard
                let self,
                let session = self.activeUserSession
            else {
                return
            }

            self.syncLocalTokenWithRemote(session: session)
        }

        deleteAccountToken = AccountDeletedNotification.addObserver(observer: self, queue: groupQueue)
        callCenterObserverToken = WireCallCenterV3.addGlobalCallStateObserver(observer: self)

        checkJailbreakIfNeeded()
    }

    private func configureBlacklistDownload() {
        if configuration.blacklistDownloadInterval > 0 {
            self.blacklistVerificator?.tearDown()
            self.blacklistVerificator = ZMBlacklistVerificator(
                checkInterval: configuration.blacklistDownloadInterval,
                version: appVersion,
                environment: environment,
                proxyUsername: proxyCredentials?.username,
                proxyPassword: proxyCredentials?.password,
                readyForRequests: self.isUnauthenticatedTransportSessionReady,
                working: nil,
                application: application,
                minTLSVersion: minTLSVersion,
                blacklistCallback: { [weak self] blacklisted in
                    guard let self, !self.isAppVersionBlacklisted else { return }

                    if blacklisted {
                        self.isAppVersionBlacklisted = true
                        self.delegate?.sessionManagerDidBlacklistCurrentVersion(reason: .appVersionBlacklisted)
                        // When the application version is blacklisted we don't want have a
                        // transition to any other state in the UI, so we won't inform it
                        // anymore by setting the delegate to nil.
                        self.delegate = nil
                    }
                })
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
        apiVersionResolver = createAPIVersionResolver()

        if blacklistVerificator != nil {
            configureBlacklistDownload()
        }
        // force creation of unauthenticatedSession
        unauthenticatedSessionFactory.readyForRequests = ready
    }

    public func start(launchOptions: LaunchOptions) {
        if let account = accountManager.selectedAccount {
            selectInitialAccount(account, launchOptions: launchOptions)
            // swiftlint:disable todo_requires_jira_link
            // TODO: this might need to happen with a completion handler.
            // TODO: register as voip delegate?
            // TODO: process voip actions pending actions
            // swiftlint:enable todo_requires_jira_link
        } else {
            createUnauthenticatedSession()
            delegate?.sessionManagerDidFailToLogin(error: nil)
        }
    }

    public func removeDatabaseFromDisk() {
        guard let account = accountManager.selectedAccount else {
            return
        }
        delete(account: account)
    }

    /// Creates an account with the given identifier and migrates its cookie storage.
    private func migrateAccount(with identifier: UUID) -> Account {
        let account = Account(userName: "", userIdentifier: identifier)
        accountManager.addAndSelect(account)
        let migrator = ZMPersistentCookieStorageMigrator(userIdentifier: identifier, serverName: authenticatedSessionFactory.environment.backendURL.host!)
        _ = migrator.createStoreMigratingLegacyStoreIfNeeded()
        return account
    }

    private func selectInitialAccount(
        _ account: Account,
        launchOptions: LaunchOptions
    ) {
        if let url = launchOptions[UIApplication.LaunchOptionsKey.url] as? URL {
            if (try? URLAction(url: url))?.causesLogout == true {
                // Do not log in if the launch URL action causes a logout
                return
            }
        }

        guard !shouldPerformPostRebootLogout() else {
            performPostRebootLogout()
            return
        }

        loadSession(for: account) { [weak self] session in
            guard
                let self,
                let session
            else {
                return
            }

            self.updateCurrentAccount(in: session.managedObjectContext)
            session.application(self.application, didFinishLaunching: launchOptions)
        }
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
                    guard let self else {
                        completion?(nil)
                        return
                    }
                    loadSession(for: account) { [weak self] session in
                        self?.isSelectingAccount = false

                        if let session {
                            self?.accountManager.select(account)
                            completion?(session)
                        } else {
                            completion?(nil)
                        }
                    }
                }
            )
        }
    }

    public func addAccount(userInfo: [String: Any]? = nil) {
        confirmSwitchingAccount { [weak self] isConfirmed in
            guard isConfirmed else { return }
            let error = NSError(userSessionErrorCode: .addAccountRequested, userInfo: userInfo)
            self?.delegate?.sessionManagerWillLogout(error: error, userSessionCanBeTornDown: { [weak self] in
                self?.activeUserSession = nil
            })
        }
    }

    public func delete(account: Account) {
        delete(account: account, reason: .userInitiated)
    }

    public func wipeDatabase(for account: Account) {
        delete(account: account, reason: .databaseWiped)
    }

    fileprivate func deleteAllAccounts(reason: ZMAccountDeletedReason) {
        let inactiveAccounts = accountManager.accounts.filter({ $0 != accountManager.selectedAccount })
        inactiveAccounts.forEach({ delete(account: $0, reason: reason) })

        if let activeAccount = accountManager.selectedAccount {
            delete(account: activeAccount, reason: reason)
        }
    }

    func delete(account: Account, reason: ZMAccountDeletedReason) {
        WireLogger.sessionManager.debug("Deleting account \(account.userIdentifier)...")
        if let secondAccount = accountManager.accounts.first(where: { $0.userIdentifier != account.userIdentifier }) {
            // Deleted an account but we can switch to another account
            select(secondAccount, tearDownCompletion: { [weak self] in
                self?.tearDownSessionAndDelete(account: account)
            })
        } else if accountManager.selectedAccount != account {
            // Deleted an inactive account, there's no need notify the UI
            self.tearDownSessionAndDelete(account: account)
        } else {
            // Deleted the last account so we need to return to the logged out area
            logoutCurrentSession(deleteCookie: true, deleteAccount: true, error: NSError(userSessionErrorCode: .accountDeleted, userInfo: [ZMAccountDeletedReasonKey: reason]))
        }
    }

    fileprivate func tearDownSessionAndDelete(account: Account) {
        self.tearDownBackgroundSession(for: account.userIdentifier) {
            self.deleteAccountData(for: account)
        }
    }

    func logout(account: Account, error: Error? = nil) {
        WireLogger.session.debug("Logging out account \(account.userIdentifier)...")
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
        // swiftlint:disable todo_requires_jira_link
        // TODO: [F] replace with TemporaryFileServiceInterface
        // swiftlint:enable todo_requires_jira_link
        guard let tmpDirectoryPath = URL(string: NSTemporaryDirectory()) else { return }
        let manager = FileManager.default
        try? manager
            .contentsOfDirectory(at: tmpDirectoryPath, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
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

        backgroundUserSessions[account.userIdentifier] = nil
        tearDownObservers(account: account.userIdentifier)
        notifyUserSessionDestroyed(account.userIdentifier)

        self.createUnauthenticatedSession(accountId: deleteAccount ? nil : account.userIdentifier)

        guard let activeUserSession else {
            WireLogger.sessionManager.critical("No active user session")
            delegate?.sessionManagerWillLogout(error: error, userSessionCanBeTornDown: nil)

            if deleteAccount {
                deleteAccountData(for: account)
            }
            return
        }

        requireInternal(activeUserSession.userId == account.userIdentifier, "User session and account are different")

        delegate?.sessionManagerWillLogout(error: error, userSessionCanBeTornDown: { [dispatchGroup] in
            dispatchGroup.enter()

            activeUserSession.close(deleteCookie: deleteCookie) {
                if deleteAccount {
                    self.deleteAccountData(for: account)
                }
                dispatchGroup.leave()
            }
            self.activeUserSession = nil
        })
    }

    /**
     Loads a session for a given account

     - Parameters:
     - account: account for which to load the session
     - completion: called when session is loaded or when session fails to load
     */
    func loadSession(for account: Account, completion: @escaping (ZMUserSession?) -> Void) {
        guard environment.isAuthenticated(account) else {
            completion(nil)

            if configuration.wipeOnCookieInvalid {
                delete(account: account, reason: .sessionExpired)
            } else {
                createUnauthenticatedSession(accountId: account.userIdentifier)

                let error = NSError(userSessionErrorCode: .accessTokenExpired,
                                    userInfo: account.loginCredentials?.dictionaryRepresentation)
                delegate?.sessionManagerDidFailToLogin(error: error)
            }

            return
        }

        activateSession(for: account, completion: completion)
    }

    fileprivate func activateSession(for account: Account, completion: @escaping (ZMUserSession) -> Void) {
        withSession(for: account, notifyAboutMigration: true) { session in
            self.activeUserSession = session
            WireLogger.sessionManager.debug("Activated ZMUserSession for account - \(account.userIdentifier.safeForLoggingDescription)")

            self.delegate?.sessionManagerDidChangeActiveUserSession(userSession: session)
            self.configureUserNotifications()

            completion(session)

            // If the user isn't logged in it's because they still need
            // to complete the login flow, which will be handle elsewhere.
            if session.isLoggedIn {
                self.delegate?.sessionManagerDidReportLockChange(forSession: session)
                self.performPostUnlockActionsIfPossible(for: session)

                Task {
                    await self.configureAnalytics(for: session)
                    await self.requestCertificateEnrollmentIfNeeded()
                }
            }
        }
    }

    func configureAnalytics(for userSession: ZMUserSession) async {
        guard analyticsService.isTrackingEnabled else {
            return
        }

        do {
            WireLogger.analytics.debug("configuring analytics for user session")
            let user = try await userSession.createAnalyticsUser()
            try analyticsService.switchUser(user)
            userSession.setAnalyticsEventTracker(analyticsService)
        } catch {
            WireLogger.analytics.error("failed to configure analytics for user session: \(error)")
        }
    }

    func performPostUnlockActionsIfPossible(for session: ZMUserSession) {
        guard session.lock == .none else { return }
        processPendingURLActionRequiresAuthentication()
    }

    /// Loads user session for @c account given and executes the @c action block.

    func withSession(
        for account: Account,
        notifyAboutMigration: Bool = false,
        perform completion: @escaping (ZMUserSession) -> Void
    ) {
        WireLogger.sessionManager.debug("Request to load session for \(account)")
        let group = self.dispatchGroup

        group.enter()
        self.sessionLoadingQueue.serialAsync { onWorkDone in
            if let session = self.backgroundUserSessions[account.userIdentifier] {
                WireLogger.sessionManager.debug("Session for \(account) is already loaded")
                completion(session)
                onWorkDone()
                group.leave()
            } else {
                self.setupUserSession(account: account) { userSession in
                    if let userSession {
                        completion(userSession)
                    }

                    onWorkDone()
                    group.leave()
                }
            }
        }
    }

    public func retryStart() {
        self.delegate?.sessionManagerAsksToRetryStart()
    }

    private func setupUserSession(
        account: Account,
        onCompletion: @escaping (ZMUserSession?) -> Void
    ) {
        let coreDataStack = CoreDataStack(
            account: account,
            applicationContainer: sharedContainerURL,
            dispatchGroup: dispatchGroup
        )
        coreDataStack.setup(
            onStartMigration: { [weak self] in
                self?.delegate?.sessionManagerWillMigrateAccount(userSessionCanBeTornDown: {})

            }, onFailure: { [weak self] error in
                self?.delegate?.sessionManagerDidFailToLoadDatabase(error: error)
                onCompletion(nil)

            }, onCompletion: { [weak self] coreDataStack in
                guard let self else {
                    assertionFailure("expected 'self' to continue!")
                    return
                }

                let userSession = self.startBackgroundSession(
                    for: account,
                    with: coreDataStack
                )

                triggerSlowSyncIfNeeded(with: userSession)

                onCompletion(userSession)
            }
        )
    }

    private func triggerSlowSyncIfNeeded(with userSession: ZMUserSession) {
        let context = userSession.syncContext
        context.perform {
            if context.readAndResetSlowSyncFlag() {
                userSession.syncStatus.forceSlowSync()
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

        PrivateUserDefaults.removeAll(forUserID: account.userIdentifier, in: sharedUserDefaults)

        let accountID = account.userIdentifier
        self.accountManager.remove(account)

        do {
            try FileManager.default.removeItem(at: CoreDataStack.accountDataFolder(accountIdentifier: accountID, applicationContainer: sharedContainerURL))
        } catch {
            WireLogger.sessionManager.critical("Impossible to delete the account \(account): \(error)")
        }
    }

    fileprivate func registerObservers(account: Account, session: ZMUserSession) {

        let selfUser = ZMUser.selfUser(inUserSession: session)
        let teamObserver = TeamChangeInfo.add(observer: self, for: nil, managedObjectContext: session.managedObjectContext)
        let selfObserver = UserChangeInfo.add(observer: self, for: selfUser, in: session.managedObjectContext)
        let conversationListObserver = ConversationListChangeInfo.add(observer: self, for: ConversationList.conversations(inUserSession: session)!, userSession: session)
        let connectionRequestObserver = ConversationListChangeInfo.add(observer: self, for: ConversationList.pendingConnectionConversations(inUserSession: session)!, userSession: session)
        let unreadCountObserver = NotificationInContext.addObserver(name: .AccountUnreadCountDidChangeNotification,
                                                                    context: account) { [weak self] note in
            guard let account = note.context as? Account else { return }
            self?.accountManager.addOrUpdate(account)
        }

        let databaseEncryptionObserverToken = session.registerDatabaseLockedHandler { [weak self] _ in
            guard session == self?.activeUserSession else { return }
            self?.delegate?.sessionManagerDidReportLockChange(forSession: session)
        }

        accountTokens[account.userIdentifier] = [
            teamObserver,
            selfObserver!,
            conversationListObserver,
            connectionRequestObserver,
            unreadCountObserver,
            databaseEncryptionObserverToken
        ]
    }

    @discardableResult
    func createUnauthenticatedSession(accountId: UUID? = nil) -> UnauthenticatedSession {
        WireLogger.sessionManager.debug("Creating unauthenticated session")
        let unauthenticatedSession = unauthenticatedSessionFactory.session(delegate: self,
                                                                           authenticationStatusDelegate: self)
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

        WireLogger.sessionManager.debug("Deleting messages older than the retention limit = \(messageRetentionInternal)")

        contextProvider.syncContext.performGroupedBlock {
            do {
                try ZMMessage.deleteMessagesOlderThan(Date(timeIntervalSinceNow: -messageRetentionInternal), context: contextProvider.syncContext)
            } catch {
                WireLogger.sessionManager.error("Failed to delete messages older than the retention limit")
            }
        }
    }

    // Creates the user session for @c account given, calls @c completion when done.
    private func startBackgroundSession(
        for account: Account,
        with coreDataStack: CoreDataStack
    ) -> ZMUserSession {
        let sessionConfig = ZMUserSession.Configuration(
            appLockConfig: configuration.legacyAppLockConfig,
            useLegacyPushNotifications: shouldProcessLegacyPushes
        )

        guard let newSession = authenticatedSessionFactory.session(
            for: account,
            coreDataStack: coreDataStack,
            configuration: sessionConfig,
            sharedUserDefaults: sharedUserDefaults,
            isDeveloperModeEnabled: isDeveloperModeEnabled
        ) else {
            preconditionFailure("Unable to create session for \(account)")
        }

        self.configure(session: newSession, for: account)
        self.deleteMessagesOlderThanRetentionLimit(contextProvider: coreDataStack)
        self.updateSystemBootTimeIfNeeded()

        WireLogger.sessionManager.debug("Created ZMUserSession for account \(String(describing: account.userName)) — \(account.userIdentifier)")
        notifyNewUserSessionCreated(newSession)
        return newSession
    }

    internal func tearDownBackgroundSession(for accountId: UUID, completion: (() -> Void)? = nil) {
        guard let userSession = self.backgroundUserSessions[accountId] else {
            WireLogger.sessionManager.error("No session to tear down for \(accountId), known sessions: \(self.backgroundUserSessions)")
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
    internal func tearDownAllBackgroundSessions() {
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
        DispatchQueue.main.async { [backgroundUserSessions, blacklistVerificator, unauthenticatedSession, reachability] in
            backgroundUserSessions.values.forEach { session in
                session.tearDown()
            }
            blacklistVerificator?.tearDown()
            unauthenticatedSession?.tearDown()
            reachability.tearDown()
        }

        if let memoryWarningObserver {
            NotificationCenter.default.removeObserver(memoryWarningObserver)
        }
    }

    public var isUserSessionActive: Bool {
        return activeUserSession != nil
    }

    func updateProfileImage(imageData: Data) {
        activeUserSession?.enqueue {
            self.activeUserSession?.userProfileImage.updateImage(imageData: imageData)
        }
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

            self.delegate?.sessionManagerDidBlacklistJailbrokenDevice()
            // When the device is jailbroken we don't want have a
            // transition to any other state in the UI, so we won't inform it
            // anymore by setting the delegate to nil.
            self.delegate = nil
        }
    }

    func shouldPerformPostRebootLogout() -> Bool {
        guard configuration.authenticateAfterReboot,
              accountManager.selectedAccount != nil,
              let systemBootTime = ProcessInfo.processInfo.bootTime(),
              let previousSystemBootTime = SessionManager.previousSystemBootTime,
              abs(systemBootTime.timeIntervalSince(previousSystemBootTime)) > 1.0
        else { return false }

        WireLogger.sessionManager.debug("Will logout due to device reboot. Previous boot time: \(previousSystemBootTime). Current boot time: \(systemBootTime)")
        return true
    }

    func performPostRebootLogout() {
        let error = NSError(userSessionErrorCode: .needsAuthenticationAfterReboot, userInfo: accountManager.selectedAccount?.loginCredentials?.dictionaryRepresentation)
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
        if let account = accountManager.accounts.first(where: { $0.userIdentifier == selfUser.remoteIdentifier }) {
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

            account.loginCredentials = selfUser.loginCredentials

            // an optional `teamImageData` image could be saved here
            accountManager.addOrUpdate(account)
        }
    }
}

extension SessionManager: TeamObserver {
    public func teamDidChange(_ changeInfo: TeamChangeInfo) {
        let team = changeInfo.team
        guard let managedObjectContext = (team as? Team)?.managedObjectContext else {
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
                analyticsService.isTrackingEnabled,
                changeInfo.user.isSelfUser,
                let userSession = activeUserSession
            else {
                return
            }

            Task {
                do {
                    try await analyticsService.updateCurrentUser(userSession.createAnalyticsUser())
                } catch {
                    WireLogger.analytics.error("failed to update current user: \(error)")
                }
            }
        }
    }
}

// MARK: - UnauthenticatedSessionDelegate

extension SessionManager {

    /// Needs to be called before we try to register another device because API requires password
    public func update(credentials: UserCredentials) -> Bool {
        guard let userSession = activeUserSession, let emailCredentials = credentials as? UserEmailCredentials else { return false }

        userSession.setEmailCredentials(emailCredentials)
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
        return true
    }
}

extension SessionManager: UnauthenticatedSessionDelegate {

    public func sessionIsAllowedToCreateNewAccount(
        _ session: UnauthenticatedSession
    ) -> Bool {
        return accountManager.accounts.count < maxNumberAccounts
    }

    public func session(
        session: UnauthenticatedSession,
        isExistingAccount account: Account
    ) -> Bool {
        return accountManager.accounts.contains(account)
    }

    public func session(
        session: UnauthenticatedSession,
        updatedCredentials credentials: UserCredentials
    ) -> Bool {
        return update(credentials: credentials)
    }

    public func session(
        session: UnauthenticatedSession,
        updatedProfileImage imageData: Data
    ) {
        updateProfileImage(imageData: imageData)
    }

    public func session(
        session: UnauthenticatedSession,
        createdAccount account: Account
    ) {
        let numberOfExistingAccounts = accountManager.accounts.count
        let createdAccountIsKnown = accountManager.account(with: account.userIdentifier) != nil

        guard
            numberOfExistingAccounts < maxNumberAccounts || createdAccountIsKnown
        else {
            let error = NSError(userSessionErrorCode: .accountLimitReached, userInfo: nil)
            loginDelegate?.authenticationDidFail(error)
            return
        }

        accountManager.addAndSelect(account)

        self.activateSession(for: account) { userSession in
            self.updateCurrentAccount(in: userSession.managedObjectContext)

            if let profileImageData = session.authenticationStatus.profileImageData {
                self.updateProfileImage(imageData: profileImageData)
            }

            switch session.backupImportDidSucceed {
            case true?:
                userSession.trackAnalyticsEvent(.backupRestored)
            case false?:
                userSession.trackAnalyticsEvent(.backupRestoredFailed)
            case nil:
                break
            }

            let registered = session.authenticationStatus.completedRegistration || session.registrationStatus.completedRegistration
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
    @objc fileprivate func applicationWillEnterForeground(_ note: Notification) {

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
                self.delegate?.sessionManagerDidReportLockChange(forSession: session)
                Task {
                    await self.requestCertificateEnrollmentIfNeeded()
                }
            }
        }
    }

    @objc func applicationWillResignActive(_ note: Notification) {
        activeUserSession?.appLockController.beginTimer()
    }

    @objc fileprivate func applicationDidBecomeActive(_ note: Notification) {
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
            let account = self.accountManager.account(with: accountID),
            let session = backgroundUserSessions[accountID]
        else {
            return
        }

        account.unreadConversationCount = Int(ZMConversation.unreadConversationCount(in: session.managedObjectContext))
    }

    fileprivate func updateAllUnreadCounts() {
        for accountID in backgroundUserSessions.keys {
            updateUnreadCount(for: accountID)
        }
    }

    public func updateAppIconBadge(accountID: UUID, unreadCount: Int) {
        DispatchQueue.main.async {
            let account = self.accountManager.account(with: accountID)
            account?.unreadConversationCount = unreadCount
            let totalUnreadCount = self.accountManager.totalUnreadCount
            self.application.applicationIconBadgeNumber = totalUnreadCount
            Logging.push.safePublic("Updated badge count to \(SanitizedString(stringLiteral: String(totalUnreadCount)))")
        }
    }
}

extension SessionManager: WireCallCenterCallStateObserver {

    public func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: UserType, timestamp: Date?, previousCallState: CallState?) {
        guard let moc = conversation.managedObjectContext else { return }

        switch callState {
        case .answered, .outgoing:
            for (_, session) in backgroundUserSessions where session.managedObjectContext == moc && activeUserSession != session {
                showConversation(conversation, at: nil, in: session)
            }
        default:
            return
        }
    }

}

extension SessionManager {

    /// The SSO code provided by the user when clicking their company link. Points to a UUID object.
    public static var companyLoginCodeKey: String {
        return "WireCompanyLoginCode"
    }

    /// The timestamp when the user initiated the request.
    public static var companyLoginRequestTimestampKey: String {
        return "WireCompanyLoginTimesta;p"
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

@objc public protocol SessionManagerCreatedSessionObserver: AnyObject {
    /// Invoked when the SessionManager creates a user session either by
    /// activating one or creating one in the background. No assumption should
    /// be made that the session is active.
    func sessionManagerCreated(userSession: ZMUserSession)

    /// Invoked when the SessionManager creates a new unauthenticated session.
    func sessionManagerCreated(unauthenticatedSession: UnauthenticatedSession)
}

@objc public protocol SessionManagerDestroyedSessionObserver: AnyObject {
    /// Invoked when the SessionManager tears down the user session associated
    /// with the accountId.
    func sessionManagerDestroyedUserSession(for accountId: UUID)
}

private let sessionManagerCreatedUnauthenticatedSessionNotificationName = Notification.Name(rawValue: "ZMSessionManagerCreatedUnauthenticatedSessionNotification")
private let sessionManagerCreatedSessionNotificationName = Notification.Name(rawValue: "ZMSessionManagerCreatedSessionNotification")
private let sessionManagerDestroyedSessionNotificationName = Notification.Name(rawValue: "ZMSessionManagerDestroyedSessionNotification")

extension SessionManager: NotificationContext {

    public func addUnauthenticatedSessionManagerCreatedSessionObserver(_ observer: SessionManagerCreatedSessionObserver) -> Any {
        return NotificationInContext.addObserver(
            name: sessionManagerCreatedUnauthenticatedSessionNotificationName,
            context: self) { [weak observer] note in observer?.sessionManagerCreated(unauthenticatedSession: note.object as! UnauthenticatedSession) }
    }

    public func addSessionManagerCreatedSessionObserver(_ observer: SessionManagerCreatedSessionObserver) -> Any {
        return NotificationInContext.addObserver(
            name: sessionManagerCreatedSessionNotificationName,
            context: self) { [weak observer] note in observer?.sessionManagerCreated(userSession: note.object as! ZMUserSession) }
    }

    public func addSessionManagerDestroyedSessionObserver(_ observer: SessionManagerDestroyedSessionObserver) -> Any {
        return NotificationInContext.addObserver(
            name: sessionManagerDestroyedSessionNotificationName,
            context: self) { [weak observer] note in observer?.sessionManagerDestroyedUserSession(for: note.object as! UUID) }
    }

    fileprivate func notifyNewUserSessionCreated(_ userSession: ZMUserSession) {
        NotificationInContext(name: sessionManagerCreatedSessionNotificationName, context: self, object: userSession).post()
    }

    fileprivate func notifyUserSessionDestroyed(_ accountId: UUID) {
        NotificationInContext(name: sessionManagerDestroyedSessionNotificationName, context: self, object: accountId as AnyObject).post()
    }
}

extension SessionManager {
    public func markAllConversationsAsRead(completion: (() -> Void)?) {
        let group = DispatchGroup()

        self.accountManager.accounts.forEach { account in
            group.enter()
            self.withSession(for: account) { userSession in
                userSession.perform {
                    userSession.markAllConversationsAsRead()
                }

                group.leave()
            }
        }

        group.notify(queue: DispatchQueue.main) {
            completion?()
        }
    }
}

extension SessionManager {

    public func confirmSwitchingAccount(completion: @escaping (_ isConfirmed: Bool) -> Void) {
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

extension SessionManager {

    public static func startAVSLogging() {
        avsLogObserver = AVSLogObserver()
    }

    public static func stopAVSLogging() {
        avsLogObserver = nil
    }
}
