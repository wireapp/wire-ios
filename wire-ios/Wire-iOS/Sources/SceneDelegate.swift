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
import UIKit
import WireCommonComponents
import WireCountly
import WireLogging
import WireNetwork
import WireSyncEngine

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // MARK: - Private properties

    private let appStateCalculator = AppStateCalculator()
    private var connectionOptions: UIScene.ConnectionOptions?

    // MARK: - Public properties

    private(set) var appRootRouter: AppRootRouter?

    // MARK: - UISceneDelegate

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        WireLogger.sceneDelegate.info("scene(_:willConnectTo:options:)")

        self.connectionOptions = connectionOptions
        AppDependencies.voIPPushManager.registerForVoIPPushes()

        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = LaunchScreenViewController()
        window.makeKeyAndVisible()

        self.window = window

        setNavigationAppearance(isRightToLeft: window.isRightToLeft)

        // TODO: [WPB-24600] Use method on CookieStorage instead of ZMKeychain.
        if UIApplication.shared.isProtectedDataAvailable || ZMKeychain.hasAccessibleAccountData() {
            createAppRootRouterIfNeeded()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        WireLogger.sceneDelegate.info(
            "sceneDidDisconnect: (activationState = \(scene.activationState))",
            attributes: .safePublic
        )
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        WireLogger.sceneDelegate.info(
            "sceneDidBecomeActive: (activationState = \(scene.activationState))",
            attributes: .safePublic
        )
        appRootRouter?.sceneDidBecomeActive()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        WireLogger.sceneDelegate.info(
            "sceneWillResignActive: (activationState = \(scene.activationState))",
            attributes: .safePublic
        )
        appRootRouter?.sceneWillResignActive()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        WireLogger.sceneDelegate.info(
            "sceneWillEnterForeground: (activationState = \(scene.activationState))",
            attributes: .safePublic
        )
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        WireLogger.sceneDelegate.info(
            "sceneDidEnterBackground: (activationState = \(scene.activationState))",
            attributes: .safePublic
        )
    }

    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        WireLogger.sceneDelegate.info("scene(_:openURLContexts:)", attributes: .safePublic)

        let didOpen = urlContexts.first.flatMap { appRootRouter?.openDeepLinkURL($0.url) }
        if didOpen != true {
            let hasRouter = appRootRouter != nil
            WireLogger.sceneDelegate.warn(
                "scene(_:openURLContexts:) failed - hasRouter: \(hasRouter), contextCount: \(urlContexts.count)",
                attributes: .safePublic
            )
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        WireLogger.sceneDelegate.info("scene(_:continue:): \(userActivity)", attributes: .safePublic)

        if SessionManager.shared?.continueUserActivity(userActivity) != true {
            WireLogger.sceneDelegate.warn(
                "scene(_:continue:) failed to continue user activity \(userActivity)",
                attributes: .safePublic
            )
        }
    }

    // MARK: - Public

    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        guard let appRootRouter else {
            WireLogger.sceneDelegate.info("no appRouter, calling completionHandler", attributes: .safePublic)
            completionHandler()
            return
        }

        let sessionManager = appRootRouter.sessionManager
        appRootRouter.performWhenAuthenticated {
            sessionManager.activeUserSession?.application(
                application,
                handleEventsForBackgroundURLSession: identifier,
                completionHandler: completionHandler
            )
        }
    }

    func createAppRootRouterIfNeeded() {
        guard appRootRouter == nil else { return }

        let defaultEnvironment = fetchDefaultEnvironment()
        let appTaskExecuter = AppBackgroundTaskExecuter(
            application: UIApplication.shared,
            isInBackground: UIApplication.shared.applicationState == .background
        )
        appTaskExecuter.startObservingLifecycleNotifications()

        let sessionManager: SessionManager
        do {
            sessionManager = try createSessionManager(
                defaultEnvironment: defaultEnvironment,
                cookieStorage: AppDependencies.cookieStorage,
                backgroundTaskExecuter: appTaskExecuter
            )
        } catch {
            fatalError("sessionManager is not created: \(error)")
        }

        guard let window else {
            WireLogger.sceneDelegate.critical("no window this should not be possible at this point")
            assertionFailure("no window this should not be possible at this point")
            return
        }

        guard let connectionOptions else {
            WireLogger.sceneDelegate.critical("no connectionOptions this should not be possible at this point")
            assertionFailure("no connectionOptions this should not be possible at this point")
            return
        }

        appRootRouter = AppRootRouter(
            defaultEnvironment: defaultEnvironment,
            mainWindow: window,
            sessionManager: sessionManager,
            appStateCalculator: appStateCalculator,
            trackingManager: TrackingManager(
                sessionManager: sessionManager,
                availabilityChecker: .default,
            ),
            backgroundTaskExecuter: appTaskExecuter,
            sceneConnectionOptions: connectionOptions
        )

        (UIApplication.shared.delegate as? AppDelegate)?.queueInitializationOperations()
    }

    func startAppRouter() {
        appRootRouter?.start()
    }

    // MARK: - Private

    private func setNavigationAppearance(isRightToLeft: Bool) {
        let backIndicator = UIImage(resource: isRightToLeft ? .forwardArrow : .backArrow)
        UINavigationBar.appearance().backIndicatorImage = backIndicator
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backIndicator
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
            fatalError("unable to fetch default environment: \(error)")
        }
    }

    private func createSessionManager(
        defaultEnvironment: BackendEnvironment2,
        cookieStorage: CookieStorage,
        backgroundTaskExecuter: any BackgroundTaskExecuter
    ) throws -> SessionManager {
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
            cookieStorage: cookieStorage,
            mediaManager: mediaManager,
            delegate: appStateCalculator,
            application: UIApplication.shared,
            defaultEnvironment: defaultEnvironment,
            environment: BackendEnvironment.shared,
            configuration: configuration,
            detector: jailbreakDetector,
            pushTokenService: AppDependencies.pushTokenService,
            callKitManager: AppDependencies.voIPPushManager.callKitManager,
            isDeveloperModeEnabled: Bundle.developerModeEnabled,
            sharedUserDefaults: .applicationGroup,
            minTLSVersion: SecurityFlags.minTLSVersion.stringValue,
            deleteUserLogs: deleteAllAccountsLogs,
            analyticsServiceConfiguration: AnalyticsServiceConfigurationBuilder.build(),
            countlyProvider: { CountlyWrapper() },
            logFilesProvider: LogFilesProvider(),
            backgroundTaskExecuter: backgroundTaskExecuter
        )

        AppDependencies.voIPPushManager.delegate = sessionManager
        return sessionManager
    }
}

private enum SessionManagerSetupError: Error {

    case missingCurrentAppVersion
    case missingCurrentBuildVersion
    case missingConfiguration
    case missingMediaManager

}
