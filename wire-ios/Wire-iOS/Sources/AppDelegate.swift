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

// Test CI: modify this line to run ci tests, sometimes it's the easiest way.

import avs
import UIKit
import WireCommonComponents
import WireCoreCrypto
import WireCountly
import WireDomain
import WireFoundation
import WireLegacyLogging
import WireNetwork
import WireSyncEngine

enum ApplicationLaunchType {
    case unknown
    case direct
    case push
    case url
    case registration
    case passwordReset
}

extension Notification.Name {
    static let ZMUserSessionDidBecomeAvailable = Notification.Name("ZMUserSessionDidBecomeAvailableNotification")
}

final class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Private Property

    private lazy var voIPPushManager: VoIPPushManager = .init(
        application: UIApplication.shared,
        pushTokenService: pushTokenService
    )

    private let pushTokenService = PushTokenService()
    private var launchOperations: [LaunchSequenceOperation] = [
        DeveloperFlagOperation(),
        BackendEnvironmentOperation(),
        PerformanceDebuggerOperation(),
        AVSLoggingOperation(),
        AutomationHelperOperation(),
        MediaManagerOperation(),
        FileBackupExcluderOperation(),
        BackendInfoOperation(),
        FontSchemeOperation(),
        CleanUpDebugStateOperation()
    ]
    private var appStateCalculator = AppStateCalculator()

    // MARK: - Private Set Property

    private(set) var appRootRouter: AppRootRouter?
    private(set) var launchType: ApplicationLaunchType = .unknown

    // MARK: - Public Set Property

    private(set) var mainWindow: UIWindow!

    // Singletons
    var unauthenticatedSession: UnauthenticatedSession? {
        SessionManager.shared?.unauthenticatedSession
    }

    var launchOptions: LaunchOptions = [:]

    // TODO: [WPB-9867]: remove this property
    @available(*, deprecated, message: "Will be removed")
    var mediaPlaybackManager: MediaPlaybackManager? {
        appRootRouter?.zClientViewController?.mediaPlaybackManager
    }

    // When running production code, this should always be true to ensure that we set the self user provider
    // on the `SelfUser` helper. The `TestingAppDelegate` subclass should override this with `false` in order
    // to require explicit configuration of the self user.

    var shouldConfigureSelfUserProvider: Bool {
        true
    }

    var temporaryFilesService: TemporaryFileServiceInterface = TemporaryFileService()

    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        #if DEBUG
            resetApp()
        #endif

        guard !application.supportsMultipleScenes else {
            fatalError("Multiple scenes are currently not supported")
        }
        guard application.connectedScenes.count == 1,
              let windowScene = application.connectedScenes.first as? UIWindowScene else {
            fatalError("Expected a single scene of type `UIWindowScene`")
        }
        mainWindow = .init(windowScene: windowScene)

        setNavigationAppearance()
        // enable logs
        _ = Settings.shared
        // switch logs
        ZMSLog.switchCurrentLogToPrevious()

        // Set up Datadog and other loggers
        WireAnalytics.setup(for: .app)

        WireLogger.appDelegate.info(
            "application:willFinishLaunchingWithOptions \(String(describing: launchOptions)) (applicationState = \(application.applicationState))"
        )

        // Initial log line to indicate the client version and build
        WireLogger.appDelegate.info(
            Bundle.main.appInfo.safeForLoggingDescription,
            attributes: .safePublic
        )

        return true
    }

    #if DEBUG
        private func resetApp() {
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("-resetData") {
                resetFileSystem()
                resetUserDefaults()
                resetKeychain()
                print("app reset done")
            }
        }
    #endif

    // MARK: - Reset

    private func resetUserDefaults() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
        }
    }

    private func resetKeychain() {
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        for itemClass in secItemClasses {
            let query: [String: Any] = [kSecClass as String: itemClass]
            SecItemDelete(query as CFDictionary)
        }
    }

    private func resetFileSystem() {
        guard let rootURL = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else {
            preconditionFailure("Unable to get shared container URL")
        }
        AccountManager.delete(at: rootURL)
        let fileManager = FileManager.default
        let directories: [FileManager.SearchPathDirectory] = [
            .documentDirectory,
            .cachesDirectory,
            .applicationSupportDirectory
        ]

        for dir in directories {
            if let url = fileManager.urls(for: dir, in: .userDomainMask).first {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    private func setNavigationAppearance() {
        let backIndicator = UIImage(resource: mainWindow.isRightToLeft == true ? .forwardArrow : .backArrow)
        UINavigationBar.appearance().backIndicatorImage = backIndicator
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backIndicator
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        WireLogger.push.info(
            "application did register for remote notifications, storing standard token",
            attributes: .safePublic
        )
        pushTokenService.storeLocalToken(.createAPNSToken(from: deviceToken))
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        voIPPushManager.registerForVoIPPushes()

        temporaryFilesService.removeTemporaryData()

        WireLogger.appDelegate
            .info(
                "application:didFinishLaunchingWithOptions START \(String(describing: launchOptions)) (applicationState = \(application.applicationState))"
            )

        // set internal name to lower layers like SyncEngine
        Bundle.mainAppInternalName = Bundle.main.appInternalName

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userSessionDidBecomeAvailable(_:)),
            name: Notification.Name.ZMUserSessionDidBecomeAvailable,
            object: nil
        )

        self.launchOptions = launchOptions ?? [:]

        _ = NSAttributedString.paragraphStyle

        DeveloperOverrides.storage = .shared()
        setupWindowAndRootViewController()

        if UIApplication.shared.isProtectedDataAvailable || ZMPersistentCookieStorage
            .hasAccessibleAuthenticationCookieData() {
            createAppRootRouterAndInitialiazeOperations(launchOptions ?? [:])
        }

        WireLogger.appDelegate
            .info("application:didFinishLaunchingWithOptions END \(String(describing: launchOptions))")
        WireLogger.appDelegate.info("Application was launched with arguments: \(ProcessInfo.processInfo.arguments)")
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        WireLogger.appDelegate.info(
            "applicationWillEnterForeground: (applicationState = \(application.applicationState)",
            attributes: .safePublic
        )
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        WireLogger.appDelegate.info(
            "applicationDidBecomeActive (applicationState = \(application.applicationState))",
            attributes: .safePublic
        )

        switch launchType {
        case .url,
             .push:
            break
        default:
            launchType = .direct
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        WireLogger.appDelegate.info(
            "applicationWillResignActive: (applicationState = \(application.applicationState))",
            attributes: .safePublic
        )
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        WireLogger.appDelegate.info(
            "applicationDidEnterBackground: (applicationState = \(application.applicationState))",
            attributes: .safePublic
        )

        launchType = .unknown
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        WireLogger.appDelegate.info(
            "application:openURL:options",
            attributes: .safePublic
        )
        return appRootRouter?.openDeepLinkURL(url) ?? false
    }

    func applicationWillTerminate(_ application: UIApplication) {
        WireLogger.appDelegate.info(
            "applicationWillTerminate: (applicationState = \(application.applicationState))",
            attributes: .safePublic
        )
    }

    @objc
    func userSessionDidBecomeAvailable(_ notification: Notification?) {
        launchType = .direct
        if launchOptions[UIApplication.LaunchOptionsKey.url] != nil {
            launchType = .url
        }

        if launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] != nil {
            launchType = .push
        }
    }

    // MARK: - URL handling

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        WireLogger.appDelegate.info("application:continueUserActivity:restorationHandler: \(userActivity)")

        return SessionManager.shared?.continueUserActivity(userActivity) ?? false
    }

    // MARK: - BackgroundUpdates

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        WireLogger.appDelegate
            .info("application:didReceiveRemoteNotification:fetchCompletionHandler: notification: \(userInfo)")

        launchType = (application.applicationState == .inactive || application.applicationState == .background) ?
            .push :
            .direct
    }

    func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        WireLogger.appDelegate.info("application:performFetchWithCompletionHandler:", attributes: .safePublic)

        guard let appRootRouter else {
            WireLogger.appDelegate.info("no appRouter, calling completionHandler", attributes: .safePublic)
            completionHandler(.noData)
            return
        }

        appRootRouter.performWhenAuthenticated {
            ZMUserSession.shared()?.application(application, performFetchWithCompletionHandler: completionHandler)
        }
    }

    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        WireLogger.appDelegate
            .info(
                "application:handleEventsForBackgroundURLSession:completionHandler: session identifier: \(identifier)"
            )

        guard let appRootRouter else {
            WireLogger.appDelegate.info("no appRouter, calling completionHandler", attributes: .safePublic)
            completionHandler()
            return
        }

        appRootRouter.performWhenAuthenticated {
            ZMUserSession.shared()?.application(
                application,
                handleEventsForBackgroundURLSession: identifier,
                completionHandler: completionHandler
            )
        }
    }

    func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {
        WireLogger.appDelegate.info("applicationProtectedDataDidBecomeAvailable", attributes: .safePublic)
        guard appRootRouter == nil else {
            WireLogger.appDelegate.debug("applicationProtectedDataDidBecomeAvailable: appRootRouter nil")
            return
        }
        createAppRootRouterAndInitialiazeOperations(launchOptions)
    }
}

// MARK: - Private Helpers

private extension AppDelegate {

    private func setupWindowAndRootViewController() {
        mainWindow.rootViewController = LaunchScreenViewController()
        mainWindow.makeKeyAndVisible()
    }

    private func createAppRootRouterAndInitialiazeOperations(_ launchOptions: LaunchOptions) {
        // Fix: set the applicationGroup so updating the callkit enable is set to NSE
        VoIPPushHelperOperation().execute()
        createAppRootRouter()
        queueInitializationOperations(launchOptions: launchOptions)
    }

    private func createAppRootRouter() {
        let sessionManager: SessionManager
        do {
            sessionManager = try createSessionManager()
        } catch {
            fatalError("sessionManager is not created")
        }

        guard mainWindow != nil else {
            WireLogger.appDelegate.critical("no mainWindow this should not be possible at this point")
            assertionFailure("no mainWindow this should not be possible at this point")
            return
        }

        appRootRouter = AppRootRouter(
            defaultEnvironment: fetchDefaultEnvironment(),
            mainWindow: mainWindow,
            sessionManager: sessionManager,
            appStateCalculator: appStateCalculator,
            trackingManager: TrackingManager(
                sessionManager: sessionManager,
                availabilityChecker: .default
            )
        )
    }

    private func createSessionManager() throws -> SessionManager {
        let infoDictionary = Bundle.main.infoDictionary

        guard let currentAppVersion = infoDictionary?["CFBundleShortVersionString"] as? String  else {
            throw SessionManagerSetupError.missingCurrentAppVersion
        }

        guard let currentBuildNumber = infoDictionary?[kCFBundleVersionKey as String] as? String  else {
            throw SessionManagerSetupError.missingCurrentBuildVersion
        }

        guard
            let url = Bundle.main.url(forResource: "session_manager", withExtension: "json"),
            let configuration = SessionManagerConfiguration.load(from: url)
        else {
            throw SessionManagerSetupError.missingConfiguration
        }

        guard let mediaManager = AVSMediaManager.sharedInstance() else {
            throw SessionManagerSetupError.missingMediaManager
        }

        configuration.blacklistDownloadInterval = Settings.shared.blacklistDownloadInterval
        let jailbreakDetector = JailbreakDetector()

        // Get maxNumberAccounts form SecurityFlags or SessionManager.defaultMaxNumberAccounts if no MAX_NUMBER_ACCOUNTS
        // flag defined
        let maxNumberAccounts = SecurityFlags.maxNumberAccounts.intValue ?? SessionManager.defaultMaxNumberAccounts

        func deleteAllAccountsLogs() { // we don't have per account logging yet
            let fileManager = FileManager.default
            if let appGroupIdentifier = Bundle.main.applicationGroupIdentifier,
               let logsDirectory = FileManager.default.sharedLogsDirectoryURL(for: appGroupIdentifier) {
                try? fileManager.removeItem(at: logsDirectory)
            }
        }

        let sessionManager = try SessionManager(
            maxNumberAccounts: maxNumberAccounts,
            currentAppVersion: currentAppVersion,
            currentBuildNumber: currentBuildNumber,
            mediaManager: mediaManager,
            delegate: appStateCalculator,
            application: UIApplication.shared,
            environment: BackendEnvironment.shared,
            configuration: configuration,
            detector: jailbreakDetector,
            pushTokenService: pushTokenService,
            callKitManager: voIPPushManager.callKitManager,
            isDeveloperModeEnabled: Bundle.developerModeEnabled,
            sharedUserDefaults: .applicationGroup,
            minTLSVersion: SecurityFlags.minTLSVersion.stringValue,
            deleteUserLogs: deleteAllAccountsLogs,
            analyticsServiceConfiguration: AnalyticsServiceConfigurationBuilder.build(),
            countlyProvider: { CountlyWrapper() },
            logFilesProvider: LogFilesProvider()
        )

        voIPPushManager.delegate = sessionManager
        return sessionManager
    }

    private func queueInitializationOperations(launchOptions: LaunchOptions) {
        var operations = launchOperations.map {
            BlockOperation(block: $0.execute)
        }

        operations.append(BlockOperation {
            self.startAppRouter(launchOptions: launchOptions)
        })

        OperationQueue.main.addOperations(operations, waitUntilFinished: false)
    }

    private func startAppRouter(launchOptions: LaunchOptions) {
        appRootRouter?.start(launchOptions: launchOptions)
    }

    private func fetchDefaultEnvironment() -> BackendEnvironment2 {
        let env = ProcessInfo.processInfo.arguments.contains("--useEnvStaging") ? "staging" : "default"
        guard let path = Bundle.backendBundle.path(
            forResource: env,
            ofType: "json"
        ) else {
            fatalError("\(env).json missing in Backend.bundle")
        }

        do {
            let data = try Data(contentsOf: URL(filePath: path))
            return try BackendEnvironment2.fromJSON(data, environmentType: .default)
        } catch {
            fatalError("unabled to fetch default environment: \(error)")
        }
    }

}

private enum SessionManagerSetupError: Error {

    case missingCurrentAppVersion
    case missingCurrentBuildVersion
    case missingConfiguration
    case missingMediaManager
    case initializationFailed(any Error)

}
