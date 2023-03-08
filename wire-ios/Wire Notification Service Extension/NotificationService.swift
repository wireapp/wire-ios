//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireCommonComponents
import UserNotifications
import WireUtilities
#if DATADOG_IMPORT
import Datadog
#endif

public class NotificationService: UNNotificationServiceExtension {

    // MARK: - Properties

    let simpleService = SimpleNotificationService()
    let legacyService = LegacyNotificationService()

    // MARK: - Methods

    public override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        DatadogWrapper.shared?.startMonitoring()
        DatadogWrapper.shared?.log(level: .debug, message: "request: \(request.debugDescription)")
        if DeveloperFlag.breakMyNotifications.isOn {
            // By doing nothing, we hope to get in a state where iOS will no
            // longer deliver pushes to us.
            return
        } else if DeveloperFlag.nseV2.isOn {
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

    public override func serviceExtensionTimeWillExpire() {
        if DeveloperFlag.breakMyNotifications.isOn {
            // By doing nothing, we hope to get in a state where iOS will no
            // longer deliver pushes to us.
            return
        } else if DeveloperFlag.nseV2.isOn {
            simpleService.serviceExtensionTimeWillExpire()
        } else {
            legacyService.serviceExtensionTimeWillExpire()
        }
    }

}
