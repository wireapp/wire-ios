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
import UIKit
import WireNetwork
import Network

public actor CheckBlacklistWorker {

    private static let checkInterval: TimeInterval = TimeInterval.oneHour * 6

    private let useCase: any IsBuildBlacklistedUseCase
    private let trigger: AsyncStream<Void>
    private let onIsBuildBlacklisted: @Sendable () -> Void

    private var triggerTask: Task<Void, Never>?
    private var isChecking = false
    private var lastSuccess: Date?

    public init(
        isBuildBlacklistedUseCase: any IsBuildBlacklistedUseCase,
        onIsBuildBlacklisted: @escaping @Sendable () -> Void
    ) {
        self.init(
            isBuildBlacklistedUseCase: isBuildBlacklistedUseCase,
            trigger: CheckBlacklistWorker.makeTrigger(),
            onIsBuildBlacklisted: onIsBuildBlacklisted
        )
    }

    deinit {
        triggerTask?.cancel()
    }

    nonisolated public func start() {
        Task { await self.startAndWait() }
    }

    // MARK: - Private

    init(
        isBuildBlacklistedUseCase: any IsBuildBlacklistedUseCase,
        trigger: AsyncStream<Void> = CheckBlacklistWorker.makeTrigger(),
        onIsBuildBlacklisted: @escaping @Sendable () -> Void
    ) {
        self.useCase = isBuildBlacklistedUseCase
        self.trigger = trigger
        self.onIsBuildBlacklisted = onIsBuildBlacklisted
    }

    func startAndWait() async {
        guard triggerTask == nil else { return }

        triggerTask = Task {
            for await _ in trigger {
                await self.performCheckIfNeeded()
            }
        }
        await triggerTask?.value
    }

    private func isStale() -> Bool {
        guard let lastSuccess else { return true }
        return lastSuccess.addingTimeInterval(Self.checkInterval) < Date()
    }

    private func performCheckIfNeeded() async {
        guard isStale() && !isChecking else { return }

        isChecking = true
        let (isBuildBlacklisted, error) = await useCase.invoke()
        isChecking = false

        if error == nil {
            lastSuccess = Date()
        }

        if isBuildBlacklisted {
            onIsBuildBlacklisted()
        }
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
