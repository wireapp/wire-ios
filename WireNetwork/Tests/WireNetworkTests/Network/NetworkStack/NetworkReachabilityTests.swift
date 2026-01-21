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

import Combine
@preconcurrency import Network
import Testing
@testable @preconcurrency import WireNetwork

@Suite
struct NetworkReachabilityTests {

    @Test
    func isReachablePublisher_emitsOnlyOnReachabilityChange() async {
        // Given
        let mock = MockReachabilityMonitor()
        let sut = NetworkReachability(monitor: mock)

        var cancellables = Set<AnyCancellable>()
        var values: [Bool] = []

        // When + Then
        await confirmation("reachability updates", expectedCount: 3) { confirm in
            sut.isOnlinePublisher
                .sink { v in
                    values.append(v)
                    confirm()
                }
                .store(in: &cancellables)

            mock.send(.init(
                status: .unsatisfied,
                isWifi: false,
                isCellular: false,
                isExpensive: false,
                isConstrained: false
            ))
            mock.send(.init(
                status: .unsatisfied,
                isWifi: true,
                isCellular: false,
                isExpensive: false,
                isConstrained: false
            )) // no reachability change
            mock.send(.init(
                status: .satisfied,
                isWifi: true,
                isCellular: false,
                isExpensive: false,
                isConstrained: false
            ))
            mock.send(.init(
                status: .satisfied,
                isWifi: false,
                isCellular: true,
                isExpensive: true,
                isConstrained: false
            )) // no reachability change
            mock.send(.init(
                status: .unsatisfied,
                isWifi: false,
                isCellular: true,
                isExpensive: true,
                isConstrained: false
            ))
        }

        #expect(values == [false, true, false])
    }

    @Test
    func interfaceSwitchPublisher_emitsOnInterfaceChange() async {
        // Given
        let mock = MockReachabilityMonitor()
        let sut = NetworkReachability(monitor: mock)

        var cancellables = Set<AnyCancellable>()
        var pairs: [(NetworkPathSnapshot, NetworkPathSnapshot)] = []

        // When + Then
        await confirmation("interface switch updates", expectedCount: 2) { confirm in
            sut.interfaceSwitchWhileOnlinePublisher
                .sink { new, old in
                    pairs.append((new, old))
                    confirm()
                }
                .store(in: &cancellables)

            let s1 = NetworkPathSnapshot(
                status: .satisfied,
                isWifi: true,
                isCellular: false,
                isExpensive: false,
                isConstrained: false
            )
            let s2 = NetworkPathSnapshot(
                status: .satisfied,
                isWifi: false,
                isCellular: true,
                isExpensive: true,
                isConstrained: false
            )
            let s3 = NetworkPathSnapshot(
                status: .satisfied,
                isWifi: false,
                isCellular: true,
                isExpensive: true,
                isConstrained: true
            )

            mock.send(s1)
            mock.send(s2)
            mock.send(s3)
        }

        #expect(pairs.count == 2)

        func snapshot(_ snapshot: NetworkPathSnapshot) -> NetworkPathSnapshot {
            .init(
                status: snapshot.status,
                isWifi: snapshot.isWifi,
                isCellular: snapshot.isCellular,
                isExpensive: snapshot.isExpensive,
                isConstrained: snapshot.isConstrained
            )
        }

        let s1 = NetworkPathSnapshot(
            status: .satisfied,
            isWifi: true,
            isCellular: false,
            isExpensive: false,
            isConstrained: false
        )
        let s2 = NetworkPathSnapshot(
            status: .satisfied,
            isWifi: false,
            isCellular: true,
            isExpensive: true,
            isConstrained: false
        )
        let s3 = NetworkPathSnapshot(
            status: .satisfied,
            isWifi: false,
            isCellular: true,
            isExpensive: true,
            isConstrained: true
        )

        #expect(pairs[0].0 == snapshot(s2))
        #expect(pairs[0].1 == snapshot(s1))
        #expect(pairs[1].0 == snapshot(s3))
        #expect(pairs[1].1 == snapshot(s2))
    }
}

final class MockReachabilityMonitor: ReachabilityMonitoring {
    var updateHandler: ((NetworkPathSnapshot) -> Void)?

    private(set) var started = false
    private(set) var cancelled = false

    func start(queue: DispatchQueue) { started = true }
    func cancel() { cancelled = true }

    func send(_ info: NetworkPathSnapshot) {
        updateHandler?(info)
    }
}
