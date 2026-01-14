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
import XCTest
@testable import WireNetwork

final class NetworkReachabilityTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()
    private var networkReachability: NetworkReachability!

    override func setUp() async throws {
        networkReachability = NetworkReachability()
    }

    override func tearDown() async throws {
        networkReachability = nil
    }

    func test_isReachablePublisher_emitsOnlyOnReachabilityChange() {
        // Given
        var values: [Bool] = []
        let exp = expectation(description: "reachability updates")
        exp.expectedFulfillmentCount = 3

        // When
        networkReachability.isReachablePublisher
            .dropFirst()
            .sink { v in
                values.append(v)
                exp.fulfill()
            }
            .store(in: &cancellables)

        networkReachability._sendForTests(.init(
            status: .unsatisfied,
            isWifi: false,
            isCellular: false,
            isExpensive: false,
            isConstrained: false)
        )
        networkReachability._sendForTests(.init(
            status: .unsatisfied,
            isWifi: true,
            isCellular: false,
            isExpensive: false,
            isConstrained: false)
        )
        networkReachability._sendForTests(.init(
            status: .satisfied,
            isWifi: true,
            isCellular: false,
            isExpensive: false,
            isConstrained: false)
        )
        networkReachability._sendForTests(.init(
            status: .satisfied,
            isWifi: false,
            isCellular: true,
            isExpensive: true,
            isConstrained: false)
        )
        networkReachability._sendForTests(.init(
            status: .unsatisfied,
            isWifi: false,
            isCellular: true,
            isExpensive: true,
            isConstrained: false)
        )

        wait(for: [exp], timeout: 1.0)

        // Then
        XCTAssertEqual(values, [false, true, false])
    }

    func test_interfaceSwitchPublisher_emitsOnInterfaceOrFlagChange() {
        // Given
        var pairs: [(NetworkReachability.Snapshot, NetworkReachability.Snapshot)] = []
        let exp = expectation(description: "interface switch updates")
        exp.expectedFulfillmentCount = 2

        // When
        networkReachability.interfaceSwitchWhileOnlinePublisher
            .sink { new, old in
                pairs.append((new, old))
                exp.fulfill()
            }
            .store(in: &cancellables)

        let s1 = NetworkReachability.Snapshot(
            status: .satisfied,
            isWifi: true,
            isCellular: false,
            isExpensive: false,
            isConstrained: false
        )
        let s2 = NetworkReachability.Snapshot(
            status: .satisfied,
            isWifi: false,
            isCellular: true,
            isExpensive: true,
            isConstrained: false
        )
        let s3 = NetworkReachability.Snapshot(
            status: .satisfied,
            isWifi: false,
            isCellular: true,
            isExpensive: true,
            isConstrained: true)

        networkReachability._sendForTests(s1)
        networkReachability._sendForTests(s2)
        networkReachability._sendForTests(s3)

        wait(for: [exp], timeout: 1.0)

        // Then
        XCTAssertEqual(pairs.count, 2)
        XCTAssertEqual(pairs[0].0, s2)
        XCTAssertEqual(pairs[0].1, s1)
        XCTAssertEqual(pairs[1].0, s3)
        XCTAssertEqual(pairs[1].1, s2)
    }

}

