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
import WireLogging

// sourcery: AutoMockable
public protocol MainAppPushChannelCoordinatorProtocol {
    // Send a notification signaling informing extensions to yield the push channel
    // and wait for that request to be acknowledged.
    func signalToExtensionsToYieldPushChannel() async
}

public final class MainAppPushChannelCoordinator: MainAppPushChannelCoordinatorProtocol {

    let darwinNotificationManager: DarwinNotificationManager = .init()

    private var observingNotificationName: String
    private var postingNotificationName: String
    private let timeout: Duration

    public init(
        clientID: String,
        timeout: Duration = .seconds(5)
    ) {
        self.timeout = timeout
        self.postingNotificationName = DarwinNotification.didRequestPushChannelAccess + "_" + clientID
        self.observingNotificationName = DarwinNotification.didReleasePushChannelAccess + "_" + clientID
    }

    deinit {
        darwinNotificationManager.stopObserving(name: observingNotificationName)
    }

    public func signalToExtensionsToYieldPushChannel() async {
        await withCheckedContinuation { continuation in
            var resumed = false

            Task {
                // in case the other process is killed we resume anyway
                // so we're not stuck
                do {
                    try await Task.sleep(for: timeout)
                    guard !resumed else { return }
                    resumed = true
                    WireLogger.sync.debug(
                        "timed out waiting for push channel to be closed",
                        attributes: .incrementalSyncV3
                    )
                    self.stopMonitoring()
                    continuation.resume()
                } catch {
                    // sleep is cancelled
                    guard !resumed else { return }
                    resumed = true
                    self.stopMonitoring()
                    continuation.resume()
                }
            }

            startMonitoring {
                guard !resumed else { return }
                resumed = true
                self.stopMonitoring()
                continuation.resume()
            }
            WireLogger.sync.debug("request app extension to release", attributes: .incrementalSyncV3)
            notify()
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
