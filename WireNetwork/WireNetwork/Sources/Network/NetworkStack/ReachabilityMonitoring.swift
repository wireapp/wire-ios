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

public struct NetworkPathSnapshot: Equatable {
    let status: NWPath.Status
    let isWifi: Bool
    let isCellular: Bool
    let isExpensive: Bool // WiFi hotspots
    let isConstrained: Bool  // other / virtual interfaces

    var isOnline: Bool { status == .satisfied }
}

public protocol ReachabilityMonitoring: AnyObject {
    var updateHandler: ((NetworkPathSnapshot) -> Void)? { get set }
    func start(queue: DispatchQueue)
    func cancel()
}

public final class NWReachabilityMonitor: ReachabilityMonitoring {
    private let monitor = NWPathMonitor()
    public var updateHandler: ((NetworkPathSnapshot) -> Void)?

    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.updateHandler?(NetworkPathSnapshot(
                status: path.status,
                isWifi: path.usesInterfaceType(.wifi),
                isCellular: path.usesInterfaceType(.cellular),
                isExpensive: path.isExpensive,
                isConstrained: path.isConstrained
            ))
        }
    }

    public func start(queue: DispatchQueue) {
        monitor.start(queue: queue)
    }

    public func cancel() {
        monitor.cancel()
    }
}
