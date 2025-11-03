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

import WireLegacyLogging

public struct YieldRequest {
    var action: () -> Void
    public func acknowledge() {
        action()
    }
}

// sourcery: AutoMockable
protocol AppExtensionPushChannelCoordinatorProtocol {
    // Listens for notifications from main app, when one arrives it produces a `YieldRequest`
    // which can be retained while push channel is closed and `acknowledged()` to send // a notification back.
    func listenForYieldRequests() async -> YieldRequest
}

public final class AppExtensionPushChannelCoordinator {
    let darwinNotificationManager: DarwinNotificationManager = .init()

    private var observingNotificationName: String
    private var postingNotificationName: String
    private var _onCancel: (() -> Void)?

    public init(
        clientID: String
    ) {
        self.postingNotificationName = DarwinNotification.didReleasePushChannelAccess + "_" + clientID
        self.observingNotificationName = DarwinNotification.didRequestPushChannelAccess + "_" + clientID
    }

    deinit {
        darwinNotificationManager.stopObserving(name: observingNotificationName)
    }

    public func listenForYieldRequests() async -> YieldRequest {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                var resumed = false
                func finish() {
                    guard !resumed else { return }
                    resumed = true
                    // stop observing when we finish (either by notification or by cancellation)
                    self.stopMonitoring()
                    // clear stored cancel hook to avoid retaining the continuation
                    self._onCancel = nil
                    continuation.resume(returning: YieldRequest {
                        self.notify()
                    })
                }

                // Store a cancel hook so the outer cancellation handler can finish the continuation
                self._onCancel = { finish() }

                // Begin monitoring for the yield request; when it arrives, finish
                startMonitoring {
                    finish()
                }

                // If the task was already cancelled before we installed the hook, finish now
                if Task.isCancelled {
                    finish()
                }
            }
        } onCancel: {
            // Cancellation should complete the continuation just like a notification
            _onCancel?()
        }
    }

    private func startMonitoring(onNotification action: @escaping () -> Void) {
        darwinNotificationManager.startObserving(name: observingNotificationName) {
            action()
        }
    }

    private func stopMonitoring() {
        darwinNotificationManager.stopObserving(name: observingNotificationName)
    }

    private func notify() {
        darwinNotificationManager.postNotification(name: postingNotificationName)
    }
}
