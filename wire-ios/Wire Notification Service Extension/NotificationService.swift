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

import Foundation
import UserNotifications
import WireCommonComponents
import WireUtilities

final class NotificationService: UNNotificationServiceExtension {

    // MARK: - Properties

    let simpleService = SimpleNotificationService()
    let legacyService = LegacyNotificationService()
    
    override init() {
        super.init()
        WireAnalytics.Datadog.enable()
        // pass tags to DataDog through WireLogger
        WireLogger.notifications.addTag(.processId, value: "\(ProcessInfo.processInfo.processIdentifier)")
        WireLogger.notifications.addTag(.processName, value: ProcessInfo.processInfo.processName)
    }


    // MARK: - Methods

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        WireAnalytics.Datadog.enable()
        // pass tags to DataDog through WireLogger
        WireLogger.notifications.addTag(.processId, value: "\(ProcessInfo.processInfo.processIdentifier)")
        WireLogger.notifications.addTag(.processName, value: ProcessInfo.processInfo.processName)
        
        WireLogger.notifications.info("did receive notification request: \(request.debugDescription)")

        if DeveloperFlag.nseV2.isOn {
            simpleService.didReceive(
                request,
                withContentHandler: contentHandler
            )
        } else {
            legacyService.didReceive(
                request,
                withContentHandler: contentHandler
            )
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if DeveloperFlag.nseV2.isOn {
            simpleService.serviceExtensionTimeWillExpire()
        } else {
            legacyService.serviceExtensionTimeWillExpire()
        }
    }
}
