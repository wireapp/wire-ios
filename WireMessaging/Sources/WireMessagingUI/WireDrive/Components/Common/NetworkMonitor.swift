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
import Network
import Observation

/// Provides observable changes in internet connection.
/// Conforms to both, `Observable` and `ObservableObject` to support ViewModels with the old and the new system.
@MainActor
package final class NetworkMonitor: Observable, ObservableObject {

    enum NetworkStatus {
        case connected
        case disconnected
    }

    static let shared = NetworkMonitor()

    private var monitor: any NWPathMonitoring
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    private let subject = CurrentValueSubject<NetworkStatus, Never>(.disconnected)
    private var cancellables = Set<AnyCancellable>()

    @Published var currentStatus: NetworkStatus?

    init(
        monitor: any NWPathMonitoring = NWPathMonitor(),
    ) {
        self.monitor = monitor

        subject
            .debounce(for: .seconds(0.25), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                self.currentStatus = status
            }
            .store(in: &cancellables)

        self.monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            Task { @MainActor in
                let status: NetworkStatus = path.status == .satisfied ? .connected : .disconnected
                subject.send(status)
            }
        }

        monitor.start(queue: queue)
    }
}

protocol NWPathMonitoring {
    var pathUpdateHandler: (@Sendable (NWPath) -> Void)? { get set }
    func start(queue: DispatchQueue)
}

extension NWPathMonitor: NWPathMonitoring {}
