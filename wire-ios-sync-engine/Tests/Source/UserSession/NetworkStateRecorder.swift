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

@testable import WireSyncEngine

@objc
public final class NetworkStateRecorder: NSObject, ZMNetworkAvailabilityObserver {
    // MARK: Public

    // MARK: Methods

    @objc
    public func observe() {
        let token = notificationCenter.addObserver(
            forName: ZMNetworkAvailabilityChangeNotification.name,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            let networkState = notification.userInfo![ZMNetworkAvailabilityChangeNotification.stateKey] as! NetworkState
            self?.didChangeAvailability(newState: networkState)
        }
        selfUnregisteringToken = .init(token, notificationCenter: notificationCenter)
    }

    @objc
    public func observe(in notificationContext: NotificationContext) {
        selfUnregisteringToken = ZMNetworkAvailabilityChangeNotification.addNetworkAvailabilityObserver(
            self,
            notificationContext: notificationContext
        )
    }

    public func didChangeAvailability(newState: NetworkState) {
        queue.async {
            self._stateChanges.append(newState)
        }
    }

    // MARK: Internal

    var stateChanges: [NetworkState] {
        queue.sync {
            _stateChanges
        }
    }

    @objc var stateChanges_objc: [NSNumber] {
        queue.sync {
            _stateChanges.map { NSNumber(value: $0.rawValue) }
        }
    }

    // MARK: Private

    // MARK: Properties

    private var _stateChanges: [NetworkState] = []

    private let queue = DispatchQueue(label: "NetworkStateRecorder.queue", qos: .userInitiated)

    private let notificationCenter: NotificationCenter = .default
    private var selfUnregisteringToken: SelfUnregisteringNotificationCenterToken?
}
