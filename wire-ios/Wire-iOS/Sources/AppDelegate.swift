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

// Test CI: modify this line to run ci tests, sometimes it's the easiest way.

import avs
import UIKit
import WireCommonComponents
import WireCoreCrypto
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

    private lazy var voIPPushManager: VoIPPushManager = {
        return VoIPPushManager(
            application: UIApplication.shared,
            requiredPushTokenType: requiredPushTokenType,
            pushTokenService: pushTokenService
        )
    }()

    private let pushTokenService = PushTokenService()

    private var launchOperations: [LaunchSequenceOperation] = [
        DeveloperFlagOperation(),
        BackendEnvironmentOperation(),
        TrackingOperation(),
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
        return SessionManager.shared?.unauthenticatedSession
    }

    var launchOptions: LaunchOptions = [:]

    // TODO [WPB-9867]: remove this property
    @available(*, deprecated, message: "Will be removed")
    var mediaPlaybackManager: MediaPlaybackManager? {
        appRootRouter?.zClientViewController?.mediaPlaybackManager
    }

    // When running production code, this should always be true to ensure that we set the self user provider
    // on the `SelfUser` helper. The `TestingAppDelegate` subclass should override this with `false` in order
    // to require explict configuration of the self user.

    var shouldConfigureSelfUserProvider: Bool {
        return true
    }

    var temporaryFilesService: TemporaryFileServiceInterface = TemporaryFileService()

    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        guard !application.supportsMultipleScenes else {
            fatalError("Multiple scenes are currently not supported")
        }
        guard application.connectedScenes.count == 1, let windowScene = application.connectedScenes.first as? UIWindowScene else {
            fatalError("Expected a single scene of type `UIWindowScene`")
        }
        mainWindow = .init(windowScene: windowScene)

        // enable logs
        _ = Settings.shared
        // switch logs
        ZMSLog.switchCurrentLogToPrevious()

        // Set up Datadog as logger
        WireAnalytics.Datadog.enable()

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

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        WireLogger.push.info(
"application did register for remote notifications, storing standard token",
            attributes: .safePublic
        )
        pushTokenService.storeLocalToken(.createAPNSToken(from: deviceToken))
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        voIPPushManager.registerForVoIPPushes()

        temporaryFilesService.removeTemporaryData()

        WireLogger.appDelegate.info("application:didFinishLaunchingWithOptions START \(String(describing: launchOptions)) (applicationState = \(application.applicationState))")

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userSessionDidBecomeAvailable(_:)),
                                               name: Notification.Name.ZMUserSessionDidBecomeAvailable,
                                               object: nil)

        self.launchOptions = launchOptions ?? [:]

        setupWindowAndRootViewController()

        if UIApplication.shared.isProtectedDataAvailable || ZMPersistentCookieStorage.hasAccessibleAuthenticationCookieData() {
            createAppRootRouterAndInitialiazeOperations(launchOptions ?? [:])
        }

        WireLogger.appDelegate.info("application:didFinishLaunchingWithOptions END \(String(describing: launchOptions))")
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

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
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

    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        appRootRouter?.performQuickAction(for: shortcutItem,
                                          completionHandler: completionHandler)
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

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        WireLogger.appDelegate.info("application:continueUserActivity:restorationHandler: \(userActivity)")

        return SessionManager.shared?.continueUserActivity(userActivity) ?? false
    }

    // MARK: - BackgroundUpdates

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        WireLogger.appDelegate.info("application:didReceiveRemoteNotification:fetchCompletionHandler: notification: \(userInfo)")

        launchType = (application.applicationState == .inactive || application.applicationState == .background) ? .push : .direct
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        WireLogger.appDelegate.info("application:performFetchWithCompletionHandler:", attributes: .safePublic)

        appRootRouter?.performWhenAuthenticated {
            ZMUserSession.shared()?.application(application, performFetchWithCompletionHandler: completionHandler)
        }
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        WireLogger.appDelegate.info("application:handleEventsForBackgroundURLSession:completionHandler: session identifier: \(identifier)")

        appRootRouter?.performWhenAuthenticated {
            ZMUserSession.shared()?.application(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
        }
    }

    func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {
        guard appRootRouter == nil else { return }
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
        createAppRootRouter(launchOptions)
        queueInitializationOperations(launchOptions: launchOptions)
    }

    private func createAppRootRouter(_ launchOptions: LaunchOptions) {

        guard let sessionManager = createSessionManager(launchOptions: launchOptions) else {
            fatalError("sessionManager is not created")
        }

        appRootRouter = AppRootRouter(
            mainWindow: mainWindow,
            sessionManager: sessionManager,
            appStateCalculator: appStateCalculator
        )
    }

    private func createSessionManager(launchOptions: LaunchOptions) -> SessionManager? {
        guard
            let appVersion = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String,
            let url = Bundle.main.url(forResource: "session_manager", withExtension: "json"),
            let configuration = SessionManagerConfiguration.load(from: url),
            let mediaManager = AVSMediaManager.sharedInstance()
        else {
            return nil
        }

        configuration.blacklistDownloadInterval = Settings.shared.blacklistDownloadInterval
        let jailbreakDetector = JailbreakDetector()

        // Get maxNumberAccounts form SecurityFlags or SessionManager.defaultMaxNumberAccounts if no MAX_NUMBER_ACCOUNTS flag defined
        let maxNumberAccounts = SecurityFlags.maxNumberAccounts.intValue ?? SessionManager.defaultMaxNumberAccounts

        let sessionManager = SessionManager(
            maxNumberAccounts: maxNumberAccounts,
            appVersion: appVersion,
            mediaManager: mediaManager,
            analytics: Analytics.shared,
            delegate: appStateCalculator,
            application: UIApplication.shared,
            environment: BackendEnvironment.shared,
            configuration: configuration,
            detector: jailbreakDetector,
            requiredPushTokenType: requiredPushTokenType,
            pushTokenService: pushTokenService,
            callKitManager: voIPPushManager.callKitManager,
            isDeveloperModeEnabled: Bundle.developerModeEnabled,
            sharedUserDefaults: .applicationGroup,
            minTLSVersion: SecurityFlags.minTLSVersion.stringValue,
            deleteUserLogs: LogFileDestination.deleteAllLogs
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

    private var requiredPushTokenType: PushToken.TokenType {
        // Previously VoIP push were available for iOS <15
        // this forces transition to standard ones.
        return .standard
    }
}

/*
 Failing tests:
     CallQualityControllerTests.testThatCallFailureDebugAlertIsPresented_WhenCallIsTerminated()
     CallQualityControllerTests.testThatCallQualitySurveyIsPresented_WhenCallStateIsTerminating_AndReasonIsNormal()
     CallQualityControllerTests.testThatCallQualitySurveyIsPresented_WhenCallStateIsTerminating_AndReasonIsStillOngoing()
     ConversationImagesViewControllerTests.testForWrappedInNavigationController()
     ConversationImagesViewControllerTests.testThatItDisplaysCorrectToolbarForImage_Ephemeral()
     ConversationImagesViewControllerTests.testThatItDisplaysCorrectToolbarForImage_Normal()
     ConversationImagesViewControllerTests.testThatToolBarIsUpdateAfterScollToAnEphemeralImage()
     ConversationListViewControllerTests.testForNoConversations()
     ConversationViewControllerSnapshotTests.testForInitState()
     ConversationViewControllerSnapshotTests.testThatGuestsBarControllerIsVisibleIfExternalsAndServicesArePresent()
     ConversationViewControllerSnapshotTests.testThatGuestsBarControllerIsVisibleIfExternalsArePresent()
     ConversationViewControllerSnapshotTests.testThatGuestsBarControllerIsVisibleIfServicesArePresent()
     ConversationViewControllerSnapshotTests.testThatTheSearchButtonIsDisabledIfMessagesAreEncryptedInTheDataBase()
     ConversationViewControllerSnapshotTests.testThatTheSearchButtonIsEnabledIfMessagesAreNotEncryptedInTheDataBase()
     EphemeralKeyboardViewControllerTests.testThatItRendersCorrectInitially()
     LandingViewControllerSnapshotTests.testForBackendWithCustomURL()
     LandingViewControllerSnapshotTests.testForBackendWithCustomURL()
     LandingViewControllerSnapshotTests.testForBackendWithCustomURL()
     LandingViewControllerSnapshotTests.testForBackendWithCustomURL()
     LandingViewControllerSnapshotTests.testForBackendWithCustomURL()
     LandingViewControllerSnapshotTests.testForBackendWithCustomURL()
     LandingViewControllerSnapshotTests.testForBackendWithCustomURL()
     LandingViewControllerSnapshotTests.testForInitState()
     LandingViewControllerSnapshotTests.testForInitState()
     LandingViewControllerSnapshotTests.testForInitState()
     LandingViewControllerSnapshotTests.testForInitState()
     LandingViewControllerSnapshotTests.testForInitState()
     LandingViewControllerSnapshotTests.testForInitState()
     LandingViewControllerSnapshotTests.testForInitState()
     StartUIViewControllerSnapshotTests.testStartUIViewControllerNoContact()
     StartUIViewControllerSnapshotTests.testStartUIViewControllerNoContactWhenSelfIsPartner()
     StartUIViewControllerSnapshotTests.testStartUIViewControllerNoContactWhenSelfIsTeamMember()
     StartUIViewControllerSnapshotTests.testStartUIViewControllerWrappedInNavigationController()
 */
