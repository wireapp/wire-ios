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

import Foundation
import UserNotifications
import WireCommonComponents
import WireDomain
import WireLogging
import WireTransport
import WireUtilities

final class NotificationService: UNNotificationServiceExtension {

    // MARK: - Properties

    var notificationService: NotificationServiceProtocol?

    override init() {
        super.init()
        WireAnalytics.setup()
    }

    // MARK: - Methods

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        WireLogger.notifications.info("did receive notification request: \(request.debugDescription)")

        if notificationService == nil {
            notificationService = loadNotificationService()
        }

        if let notificationService {
            notificationService.didReceive(
                request,
                withContentHandler: contentHandler
            )
        } else {
            contentHandler(.empty)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        notificationService?.serviceExtensionTimeWillExpire()
    }

    private func loadNotificationService() -> NotificationServiceProtocol? {
        // API version decides which service to use, if we don't have it
        // yet then we simply supress the notification request.
        guard let apiVersion = BackendInfo.apiVersion else {
            WireLogger.notifications.warn("no resolved api version, not loading service")
            return nil
        }

        /// With v8, the new extension is available, but not necessarily
        /// turned on yet. Regardless, we will use it and later check
        /// if the new sync is enabled.
        if apiVersion >= .v8 {
            WireLogger.notifications.warn("loading new notification service")
            return NotificationServiceExtension()
        } else {
            WireLogger.notifications.warn("loading legacy notification service")
            return LegacyNotificationService()
        }
    }

}
