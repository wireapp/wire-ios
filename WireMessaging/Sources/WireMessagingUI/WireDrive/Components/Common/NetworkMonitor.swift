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
import Network

final class NetworkMonitor: Sendable {

    enum NetworkStatus {
        case connected
        case disconnected
    }

    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    private let subject = CurrentValueSubject<NetworkStatus, Never>(.disconnected)

    var statusPublisher: AnyPublisher<NetworkStatus, Never> {
        subject.eraseToAnyPublisher()
    }

    var currentStatus: NetworkStatus {
        subject.value
    }

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let status: NetworkStatus =
                path.status == .satisfied ? .connected : .disconnected

            self?.subject.send(status)
        }

        monitor.start(queue: queue)
    }
}
