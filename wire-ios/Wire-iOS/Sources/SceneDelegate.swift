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
import WireLogging
import WireNetwork
import WireSyncEngine
import WireCommonComponents
import WireCountly

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    private let cookieStorage = CookieStorage(cookieEncryptionKey: UserDefaults.cookiesKey())
    let pushTokenService = PushTokenService()
    private let appStateCalculator = AppStateCalculator()

    private lazy var voIPPushManager: VoIPPushManager = .init(
        application: UIApplication.shared,
        pushTokenService: pushTokenService
    )

    private(set) var appRootRouter: AppRootRouter?

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        WireLogger.appDelegate.info("scene(_:willConnectTo:options:)")

        voIPPushManager.registerForVoIPPushes()

        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = LaunchScreenViewController()
        window.makeKeyAndVisible()

        self.window = window


        setNavigationAppearance(isRightToLeft: window.isRightToLeft)

        (UIApplication.shared.delegate as? AppDelegate)?.sceneDidFinishConnecting(self)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        WireLogger.appDelegate.info("sceneDidDisconnect")

        
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        WireLogger.appDelegate.info(
            "sceneDidBecomeActive: (activationState = \(scene.activationState)",
            attributes: .safePublic
        )
    }

    func sceneWillResignActive(_ scene: UIScene) {
        WireLogger.appDelegate.info(
            "sceneWillResignActive: (activationState = \(scene.activationState))",
            attributes: .safePublic
        )
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        WireLogger.appDelegate.info(
            "sceneWillEnterForeground: (activationState = \(scene.activationState))",
            attributes: .safePublic
        )
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        WireLogger.appDelegate.info(
            "sceneDidEnterBackground: (activationState = \(scene.activationState))",
            attributes: .safePublic
        )
    }

    func scene(_ scene: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        WireLogger.appDelegate.info("scene(_:openURLContexts:)", attributes: .safePublic)

        guard let url = urlContexts.first?.url else { return }

        if appRootRouter?.openDeepLinkURL(url) != true {
            WireLogger.appDelegate.warn("scene(_:openURLContexts:) failed to open url", attributes: .safePublic)
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        WireLogger.appDelegate.info("scene(_:continue:): \(userActivity)", attributes: .safePublic)

        if SessionManager.shared?.continueUserActivity(userActivity) != true {
            WireLogger.appDelegate.warn(
                "scene(_:continue:) failed to continue user activity \(userActivity)",
                attributes: .safePublic
            )
        }
    }

    // MARK: - Public

    func createAppRootRouter() {
        let defaultEnvironment = fetchDefaultEnvironment()

        let sessionManager: SessionManager
        do {
            sessionManager = try createSessionManager(
                defaultEnvironment: defaultEnvironment,
                cookieStorage: cookieStorage
            )
        } catch {
            fatalError("sessionManager is not created")
        }

        guard let window else {
            WireLogger.appDelegate.critical("no window this should not be possible at this point")
            assertionFailure("no window this should not be possible at this point")
            return
        }

        appRootRouter = AppRootRouter(
            defaultEnvironment: defaultEnvironment,
            mainWindow: window,
            sessionManager: sessionManager,
            appStateCalculator: appStateCalculator,
            trackingManager: TrackingManager(
                sessionManager: sessionManager,
                availabilityChecker: .default
            )
        )
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
        cookieStorage: CookieStorage
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
}

private enum SessionManagerSetupError: Error {

    case missingCurrentAppVersion
    case missingCurrentBuildVersion
    case missingConfiguration
    case missingMediaManager
    case initializationFailed(any Error)

}
