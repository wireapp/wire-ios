//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

public final class NetworkReachability: Sendable {

    private let monitor = NWPathMonitor()
    private let isReachableSubject = CurrentValueSubject<Bool, Never>(true)
    private let queue = DispatchQueue(label: "NetworkReachabilityQueue")

    public var isReachablePublisher: AnyPublisher<Bool, Never> {
        isReachableSubject.eraseToAnyPublisher()
    }

    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isReachableSubject.send(path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

}
