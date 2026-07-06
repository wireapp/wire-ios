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

import Foundation
import UserNotifications
import WireCommonComponents
import WireCoreCrypto
import WireDomain
import WireFoundation
import WireLogging
import WireNetwork
import WireTransport
import WireUtilities

final class NotificationService: UNNotificationServiceExtension {

    // MARK: - Properties

    private var notificationHandlers: [String: NotificationServiceExtension] = [:]

    override init() {
        super.init()
        DeveloperOverrides.storage = .shared()
        WireAnalytics.setup(for: .notificationServiceExtension)
        CoreCrypto.registerLogger()
    }

    // MARK: - Methods

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        WireLogger.notifications.info("did receive notification request: \(request.debugDescription)")

        if !notificationHandlers.isEmpty {
            // It is not clearly documented whether a `UNNotificationServiceExtension` instance can be called multiple
            // times. Looking at Apples example code I would assume not but to be safe we are allowing multiple
            // invocations per `UNNotificationServiceExtension` instance. If in practice this warning is never called
            // we can re-architect things.
            WireLogger.notifications.warn("notification service has multiple handlers")
        }

        if let handler  = loadNotificationHandler(for: request, contentHandler: contentHandler) {
            notificationHandlers[request.identifier] = handler
            handler.execute()
        } else {
            WireLogger.notifications.warn("cannot load notification handler", attributes: .safePublic)
            contentHandler(.emptyNotification)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        WireLogger.notifications.warn("notification service will expire", attributes: .safePublic)

        let hasOnGoingTask = notificationHandlers.values.contains { $0.hasOnGoingTask }
        guard hasOnGoingTask == true else {
            WireLogger.notifications.info("no ongoing tasks, no need to cancel", attributes: .safePublic)
            return
        }

        let semaphore = DispatchSemaphore(value: 0)
        Task {
            let handlers = notificationHandlers
            notificationHandlers = [:]

            await withTaskGroup { group in
                for handler in handlers.values {

                    group.addTask {
                        await handler.cancel()
                    }

                    await group.waitForAll()
                }
            }

            WireLogger.notifications.info("did cancel ongoing tasks", attributes: .safePublic)
            semaphore.signal()
        }

        // Keep the notification service alive until the ongoing task has completed cancellation as we have file locks
        // that need releasing. It has been observed when using `performExpiringActivity(withReason:)` from within the
        // NSE that the block might continue a long time after the activity has expired. Therefore we use a timeout.
        ProcessInfo.processInfo.performExpiringActivity(withReason: "cancelling ongoing tasks") { isExpired in
            if isExpired {
                semaphore.signal()
            } else {
                _ = semaphore.wait(wallTimeout: .now() + .seconds(30))
            }
        }
    }

    private func loadNotificationHandler(
        for request: UNNotificationRequest,
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> NotificationServiceExtension? {
        let info = Bundle.appMainBundle.infoDictionary

        guard let currentAppVersion = info?["CFBundleShortVersionString"] as? String else {
            WireLogger.notifications.critical(
                "no current app version, not loading service",
                attributes: .safePublic
            )
            return nil
        }

        guard let currentBuildNumber = info?[kCFBundleVersionKey as String] as? String  else {
            WireLogger.notifications.critical(
                "no current build number, not loading service",
                attributes: .safePublic
            )
            return nil
        }

        guard let appGroupID = info?["WireGroupId"] as? String else {
            WireLogger.notifications.critical(
                "no app group id, not loading service",
                attributes: .safePublic
            )
            return nil
        }

        let appID = "group.\(appGroupID)"
        let appContainerURL = FileManager.sharedContainerDirectory(for: appID)

        guard let sharedUserDefaults = UserDefaults(suiteName: appID) else {
            WireLogger.notifications.critical(
                "no shared user defaults, not loading service",
                attributes: .safePublic
            )
            return nil
        }

        guard let cookiesKey = UserDefaults.existingCookiesKey else {
            WireLogger.notifications.warn(
                "no cookie encryption key, not loading service",
                attributes: .safePublic
            )
            return nil
        }

        WireLogger.notifications.info(
            "loading new notification service",
            attributes: .safePublic
        )
        return NotificationServiceExtension(
            currentAppVersion: currentAppVersion,
            currentBuildNumber: currentBuildNumber,
            appContainerURL: appContainerURL,
            sharedUserDefaults: sharedUserDefaults,
            cookieEncryptionKey: cookiesKey,
            minTLSVersion: SecurityFlags.minTLSVersion.stringValue,
            preferredAPIVersion: BackendInfo.preferredAPIVersion.map {
                UInt($0.rawValue)
            },
            request: request,
            contentHandler: contentHandler,
            didComplete: { [weak self] in
                guard let self else { return }
                notificationHandlers[request.identifier] = nil
            }
        )
    }
}
