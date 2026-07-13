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

// Test CI: modify this line to run ci tests, sometimes it's the easiest way.

import avs
import Combine
import UIKit
import WireCommonComponents
import WireCoreCrypto
import WireCountly
import WireDomain
import WireFoundation
import WireLogging
import WireNetwork
import WireSyncEngine
import WireSystem

class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Private properties

    private let launchOperations: [LaunchSequenceOperation] = [
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

    private var cancellables = Set<AnyCancellable>()

    private var sceneDelegate: SceneDelegate? {
        UIApplication.shared.connectedScenes.compactMap { $0.delegate as? SceneDelegate }.first
    }

    // MARK: - Public properties

    var mainWindow: UIWindow? {
        sceneDelegate?.window
    }

    // TODO: [WPB-9867]: remove this property
    @available(*, deprecated, message: "Will be removed")
    var mediaPlaybackManager: MediaPlaybackManager? {
        sceneDelegate?.appRootRouter?.zClientViewController?.mediaPlaybackManager
    }

    // When running production code, this should always be true to ensure that we set the self user provider
    // on the `SelfUser` helper. The `TestingAppDelegate` subclass should override this with `false` in order
    // to require explicit configuration of the self user.

    var shouldConfigureSelfUserProvider: Bool {
        true
    }

    // MARK: - UIApplicationDelegate lifecycle

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

        // enable logs
        _ = Settings.shared
        // switch logs
        ZMSLog.switchCurrentLogToPrevious()

        // Set up Datadog and other loggers
        WireAnalytics.setup(for: .app)
        CoreCrypto.registerLogger()

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

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        TemporaryFileService().removeTemporaryData()

        WireLogger.appDelegate
            .info(
                "application:didFinishLaunchingWithOptions START \(String(describing: launchOptions)) (applicationState = \(application.applicationState))"
            )

        // set internal name to lower layers like SyncEngine
        Bundle.mainAppInternalName = Bundle.main.appInternalName

        _ = NSAttributedString.paragraphStyle

        DeveloperOverrides.storage = .shared()
        VoIPPushHelperOperation().execute()

        WireLogger.appDelegate
            .info("application:didFinishLaunchingWithOptions END \(String(describing: launchOptions))")
        WireLogger.appDelegate.info("Application was launched with arguments: \(ProcessInfo.processInfo.arguments)")
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        WireLogger.appDelegate.info(
            "applicationWillTerminate: (applicationState = \(application.applicationState))",
            attributes: .safePublic
        )
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        WireLogger.push.info(
            "application did register for remote notifications, storing standard token",
            attributes: .safePublic
        )
        AppDependencies.pushTokenService.storeLocalToken(.createAPNSToken(from: deviceToken))
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        WireLogger.appDelegate
            .info("application:didReceiveRemoteNotification:fetchCompletionHandler: notification: \(userInfo)")
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

        sceneDelegate?.application(
            application,
            handleEventsForBackgroundURLSession: identifier,
            completionHandler: completionHandler
        )
    }

    func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {
        WireLogger.appDelegate.info("applicationProtectedDataDidBecomeAvailable", attributes: .safePublic)

        sceneDelegate?.createAppRootRouterIfNeeded()
    }

    // MARK: - Reset

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
    #endif

    // MARK: - Complete Initialization

    func queueInitializationOperations() {
        var operations = launchOperations.map {
            BlockOperation(block: $0.execute)
        }

        operations.append(BlockOperation {
            self.sceneDelegate?.startAppRouter()
        })

        OperationQueue.main.addOperations(operations, waitUntilFinished: false)
    }
}
