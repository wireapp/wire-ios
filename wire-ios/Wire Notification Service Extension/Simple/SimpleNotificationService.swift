//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import UserNotifications
import WireCommonComponents
import WireTransport

final class SimpleNotificationService: UNNotificationServiceExtension, Loggable {
    // MARK: Lifecycle

    override init() {
        WireLogger.notifications.info("initializing new simple notification service")
        super.init()
    }

    // MARK: Internal

    // MARK: - Types

    typealias ContentHandler = (UNNotificationContent) -> Void

    // MARK: - Methods

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping ContentHandler
    ) {
        WireLogger.notifications.info("simple notification service will process request: \(request.identifier)")

        let task = Task { [weak self] in
            do {
                WireLogger.notifications.info("initializing job for request (\(request.identifier))")
                let job = try Job(request: request)
                let content = try await job.execute()
                WireLogger.notifications.info("showing notification for request (\(request.identifier))")
                contentHandler(content)
            } catch {
                WireLogger.notifications
                    .error("job for request (\(request.identifier)) failed: \(error.localizedDescription)")
                self?.finishWithoutShowingNotification()
            }
            self?.currentTasks[request.identifier] = nil
        }
        currentTasks[request.identifier] = task
        latestContentHandler = contentHandler
    }

    override func serviceExtensionTimeWillExpire() {
        WireLogger.notifications.warn("simple notification service will expire")
        currentTasks.values.forEach { task in task.cancel() }
        currentTasks = [:]
        finishWithoutShowingNotification()
    }

    // MARK: Private

    // MARK: - Properties

    private let environment: BackendEnvironmentProvider = BackendEnvironment.shared
    private var currentTasks: [String: Task<Void, Never>] = [:]
    private var latestContentHandler: ContentHandler?

    private func finishWithoutShowingNotification() {
        WireLogger.notifications.info("finishing without showing notification")
        latestContentHandler?(.empty)
    }
}
