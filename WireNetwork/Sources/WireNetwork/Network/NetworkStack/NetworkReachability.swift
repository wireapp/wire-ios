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
import Network

/// One monitor, two publishers.
/// - Reachability: `isReachablePublisher`
/// - Network interface changes: `interfaceSwitchPublisher`
public final class NetworkReachability: Sendable {

    public struct Snapshot: Equatable {
        let status: NWPath.Status
        let isWifi: Bool
        let isCellular: Bool
        let isExpensive: Bool // WiFi hotspots
        let isConstrained: Bool // other / virtual interfaces

        var isOnline: Bool { status == .satisfied }
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkReachabilityQueue")
    private let snapshotSubject = CurrentValueSubject<Snapshot?, Never>(nil)

    public var snapshotPublisher: AnyPublisher<Snapshot, Never> {
        snapshotSubject
            .compactMap { $0 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public var isReachablePublisher: AnyPublisher<Bool, Never> {
        snapshotPublisher
            .map { $0.isOnline }
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

    public init() {
        self.monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }

            let snap = Snapshot(
                status: path.status,
                isWifi: path.usesInterfaceType(.wifi),
                isCellular: path.usesInterfaceType(.cellular),
                isExpensive: path.isExpensive,
                isConstrained: path.isConstrained
            )

            self.snapshotSubject.send(snap)
        }

        self.monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

}
