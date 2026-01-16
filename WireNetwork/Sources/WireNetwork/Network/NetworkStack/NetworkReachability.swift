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

@preconcurrency import Combine
import Foundation
@preconcurrency import Network

/// One monitor, two publishers.
/// - Reachability: `isReachablePublisher`
/// - Network interface changes: `interfaceSwitchPublisher`
public final class NetworkReachability {

    public struct Snapshot: Equatable {
        let status: NWPath.Status
        let isWifi: Bool
        let isCellular: Bool
        let isExpensive: Bool // WiFi hotspots
        let isConstrained: Bool // other / virtual interfaces

        var isOnline: Bool { status == .satisfied }
    }

    private let monitor: any ReachabilityMonitoring
    private let queue: DispatchQueue
    private let snapshotSubject = CurrentValueSubject<Snapshot?, Never>(nil)

    public var snapshotPublisher: AnyPublisher<Snapshot, Never> {
        snapshotSubject
            .compactMap(\.self)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public var isOnlinePublisher: AnyPublisher<Bool, Never> {
        snapshotPublisher
            .map(\.isOnline)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private var interfaceSwitchPublisher: AnyPublisher<(new: Snapshot, old: Snapshot), Never> {
        snapshotPublisher
            .scan((old: Snapshot?.none, new: Snapshot?.none)) { currentSnap, newSnap in
                (old: currentSnap.new, new: newSnap)
            }
            .compactMap { pair -> (new: Snapshot, old: Snapshot)? in
                guard let old = pair.old, let new = pair.new else { return nil }
                return (new: new, old: old)
            }
            .filter { pair in
                (pair.new.isWifi != pair.old.isWifi) ||
                    (pair.new.isCellular != pair.old.isCellular) ||
                    (pair.new.isExpensive != pair.old.isExpensive) ||
                    (pair.new.isConstrained != pair.old.isConstrained)
            }
            .eraseToAnyPublisher()
    }

    public var interfaceSwitchWhileOnlinePublisher: AnyPublisher<(new: Snapshot, old: Snapshot), Never> {
        interfaceSwitchPublisher
            .filter { $0.old.isOnline && $0.new.isOnline }
            .eraseToAnyPublisher()
    }

    public init(
        monitor: any ReachabilityMonitoring = NWReachabilityMonitor(),
        queue: DispatchQueue = DispatchQueue(label: "NetworkReachabilityQueue")
    ) {
        self.monitor = monitor
        self.queue = queue
        self.monitor.updateHandler = { [weak self] info in
            guard let self else { return }
            snapshotSubject.send(Snapshot(
                status: info.status,
                isWifi: info.isWifi,
                isCellular: info.isCellular,
                isExpensive: info.isExpensive,
                isConstrained: info.isConstrained
            ))
        }

        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

}
