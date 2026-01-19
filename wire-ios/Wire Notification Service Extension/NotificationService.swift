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
import WireDomain
import WireFoundation
import WireLogging
import WireNetwork
import WireTransport
import WireUtilities

final class NotificationService: UNNotificationServiceExtension {

    // MARK: - Properties

    var notificationService: NotificationServiceProtocol?

    override init() {
        super.init()
        DeveloperOverrides.storage = .shared()
        WireAnalytics.setup(for: .notificationServiceExtension)
    }

    // MARK: - Methods

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        WireLogger.notifications.info("did receive notification request: \(request.debugDescription)")

        if notificationService == nil {
            notificationService = loadNotificationService(for: request)
        }

        if let notificationService {
            notificationService.didReceive(
                request,
                withContentHandler: contentHandler
            )
        } else {
            WireLogger.notifications.warn("no notification service loaded", attributes: .safePublic)
            contentHandler(.emptyNotification)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        notificationService?.serviceExtensionTimeWillExpire()
    }

    private func loadNotificationService(for request: UNNotificationRequest) -> NotificationServiceProtocol? {
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

        WireLogger.notifications.info(
            "loading new notification service",
            attributes: .safePublic
        )
        return NotificationServiceExtension(
            currentAppVersion: currentAppVersion,
            currentBuildNumber: currentBuildNumber,
            appContainerURL: appContainerURL,
            sharedUserDefaults: sharedUserDefaults,
            cookieEncryptionKey: UserDefaults.cookiesKey(),
            minTLSVersion: SecurityFlags.minTLSVersion.stringValue,
            preferredAPIVersion: BackendInfo.preferredAPIVersion.map {
                UInt($0.rawValue)
            }
        )
    }
}
