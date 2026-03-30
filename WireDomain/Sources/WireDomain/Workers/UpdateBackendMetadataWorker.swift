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
import Foundation
import Network
import UIKit

public actor UpdateBackendMetadataWorker {

    private static let checkInterval: TimeInterval = .oneHour * 12

    private let useCase: any UpdateBackendMetadataUseCaseProtocol
    private let trigger: AsyncStream<Void>

    private var triggerTask: Task<Void, Never>?
    private var isChecking = false
    private var lastSuccess: Date?

    public init(
        useCase: any UpdateBackendMetadataUseCaseProtocol
    ) {
        self.init(
            useCase: useCase,
            trigger: Self.makeTrigger()
        )
    }

    deinit {
        triggerTask?.cancel()
    }

    public nonisolated func start() {
        Task { await self.startAndWait() }
    }

    // MARK: - Private

    init(
        useCase: any UpdateBackendMetadataUseCaseProtocol,
        trigger: AsyncStream<Void>
    ) {
        self.useCase = useCase
        self.trigger = trigger
    }

    func startAndWait() async {
        guard triggerTask == nil else { return }

        triggerTask = Task {
            for await _ in trigger {
                await self.updateIfNeeded()
            }
        }
        await triggerTask?.value
    }

    private func isStale() -> Bool {
        guard let lastSuccess else { return true }
        return lastSuccess.addingTimeInterval(Self.checkInterval) < Date()
    }

    private func updateIfNeeded() async {
        guard isStale(), !isChecking else { return }

        isChecking = true
        do {
            _ = try await useCase.invoke()
            lastSuccess = Date()
        } catch {
            // Failed to update metadata, will retry on next trigger.
        }
        isChecking = false
    }

    // MARK: - Trigger

    static func makeTrigger() -> AsyncStream<Void> {
        AsyncStream { continuation in
            continuation.yield()

            let isOnlineTrigger = Task {
                let monitor = NWPathMonitor()
                for await path in monitor where path.status == .satisfied {
                    continuation.yield()
                }
            }

            let intervalTrigger = Task {
                while true {
                    try await Task.sleep(for: .seconds(60 * 30)) // 30 min
                    continuation.yield()
                }
            }

            let willEnterForegroundTrigger = Task {
                let notificationCenter = NotificationCenter.default
                for await _ in notificationCenter.notifications(named: UIApplication.willEnterForegroundNotification) {
                    continuation.yield()
                }
            }

            continuation.onTermination = { _ in
                isOnlineTrigger.cancel()
                intervalTrigger.cancel()
                willEnterForegroundTrigger.cancel()
            }
        }
    }

}
