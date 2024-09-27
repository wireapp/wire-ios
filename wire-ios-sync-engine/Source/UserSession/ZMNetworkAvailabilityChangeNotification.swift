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

// MARK: - ZMNetworkAvailabilityChangeNotification

public class ZMNetworkAvailabilityChangeNotification: NSObject {
    static let name = Notification.Name(rawValue: "ZMNetworkAvailabilityChangeNotification")

    static let stateKey = "networkState"

    public static func addNetworkAvailabilityObserver(
        _ observer: ZMNetworkAvailabilityObserver,
        notificationContext: NotificationContext
    ) -> SelfUnregisteringNotificationCenterToken {
        NotificationInContext.addObserver(
            name: name,
            context: notificationContext
        ) { [weak observer] note in
            let networkState = note.userInfo[stateKey] as! NetworkState
            observer?.didChangeAvailability(newState: networkState)
        }
    }

    public static func notify(
        networkState: NetworkState,
        notificationContext: NotificationContext
    ) {
        NotificationInContext(
            name: name,
            context: notificationContext,
            userInfo: [stateKey: networkState]
        ).post()
    }
}

// MARK: - ZMNetworkAvailabilityObserver

public protocol ZMNetworkAvailabilityObserver: AnyObject {
    func didChangeAvailability(newState: NetworkState)
}
