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

@testable import WireSyncEngine

@objcMembers
public final class NetworkStateRecorder: NSObject, ZMNetworkAvailabilityObserver {

    private(set) var stateChanges: [ZMNetworkState] = []
    var stateChanges_objc: [NSNumber] {
        stateChanges.map { NSNumber(value: $0.rawValue) }
    }

    private let notificationCenter: NotificationCenter = .default
    private var selfUnregisteringToken: SelfUnregisteringNotificationCenterToken?

    public func observe() {
        let token = notificationCenter.addObserver(
            forName: ZMNetworkAvailabilityChangeNotification.name,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            let networkState = notification.userInfo![ZMNetworkAvailabilityChangeNotification.stateKey] as! ZMNetworkState
            self?.didChangeAvailability(newState: networkState)
        }
        selfUnregisteringToken = .init(token, notificationCenter: notificationCenter)
    }

    public func observe(in notificationContext: NotificationContext) {
        selfUnregisteringToken = ZMNetworkAvailabilityChangeNotification.addNetworkAvailabilityObserver(
            self,
            notificationContext: notificationContext
        )
    }

    public func didChangeAvailability(newState: ZMNetworkState) {
        stateChanges.append(newState)
    }

}
