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
import Network

extension NetworkMonitor {

    /// Raw key of `DeveloperFlag.simulateDriveOffline`, which is not accessible from this module.
    private static let simulateOfflineFlagKey = "simulateDriveOffline"

    /// Creates the shared monitor. When the `simulateDriveOffline` developer flag is on (set by UI tests
    /// through a launch argument), the monitor never reports a connection, so Drive stays offline.
    static func makeShared() -> NetworkMonitor {
        if UserDefaults.standard.object(forKey: simulateOfflineFlagKey) as? Bool == true {
            return NetworkMonitor(monitor: OfflineNWPathMonitor(), initialStatus: .disconnected)
        }
        return NetworkMonitor()
    }
}

/// A path monitor that never reports a path update, so the monitor keeps its initial status.
private struct OfflineNWPathMonitor: NWPathMonitoring {
    var pathUpdateHandler: (@Sendable (NWPath) -> Void)?
    func start(queue: DispatchQueue) {}
}
