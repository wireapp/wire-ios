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
import UIKit

public actor BackoffRetrier {
    public typealias SleepFunction = @Sendable (
        _ seconds: Double
    ) async throws -> Void

    public enum Failure: Error {
        case exceededMaxAttempts(latestError: any Error)
    }

    private let policy: BackoffRetryPolicy
    private let monitor = NWPathMonitor()
    private let sleep: SleepFunction
    private var attempt: Int = 0

    public init(
        policy: BackoffRetryPolicy = .init(),
        sleep: @escaping SleepFunction = { delay in
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    ) {
        self.policy = policy
        self.sleep = sleep

        setupObservers()
    }

    deinit {
        monitor.cancel()
    }

    public func retry<T: Sendable>(
        _ operation: @escaping () async throws -> T
    ) async throws -> T {

        while true {
            do {
                return try await operation()
            } catch {

                guard attempt < policy.maxRetries else {
                    throw Failure.exceededMaxAttempts(latestError: error)
                }

                // Exponential backoff
                var delay = policy.baseTime * Double(pow(policy.exponentMultiplier, Double(attempt)))

                if policy.jitter {
                    // Adds jitter (randomness)
                    delay = Double.random(in: 0 ... min(policy.maxTime, delay))
                }

                try await sleep(delay)

                attempt += 1
            }
        }
    }

    private nonisolated func setupObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.reset()
            }
        }

        let queue = DispatchQueue(label: "BackoffRetrier")

        monitor.pathUpdateHandler = { [weak self] newPath in
            guard let self else { return }

            let currentPath = monitor.currentPath
            let didRetrieveConnection = currentPath.status != .satisfied && newPath.status == .satisfied

            if didRetrieveConnection {
                Task {
                    await reset()
                }
            }
        }

        monitor.start(queue: queue)
    }

    private func reset() {
        attempt = 0
    }
}
