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
import WireRequestStrategy

// MARK: - PushNotificationStrategyDelegate

protocol PushNotificationStrategyDelegate: AnyObject {
    func pushNotificationStrategy(
        _ strategy: PushNotificationStrategy,
        didFetchEvents events: [ZMUpdateEvent]
    ) async throws
    func pushNotificationStrategyDidFinishFetchingEvents(_ strategy: PushNotificationStrategy)
}

// MARK: - PushNotificationStrategy

final class PushNotificationStrategy: AbstractRequestStrategy {
    // MARK: Lifecycle

    init(
        syncContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        pushNotificationStatus: PushNotificationStatus,
        notificationsTracker: NotificationsTracker?,
        lastEventIDRepository: LastEventIDRepositoryInterface
    ) {
        super.init(
            withManagedObjectContext: syncContext,
            applicationStatus: applicationStatus
        )

        self.sync = NotificationStreamSync(
            moc: syncContext,
            notificationsTracker: notificationsTracker,
            eventIDRespository: lastEventIDRepository,
            delegate: self
        )

        self.pushNotificationStatus = pushNotificationStatus
    }

    // MARK: Public

    public var isFetchingStreamForAPNS: Bool {
        pushNotificationStatus.hasEventsToFetch
    }

    // MARK: - Methods

    override public func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        nextRequest(for: apiVersion)
    }

    override public func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard isFetchingStreamForAPNS, !isProcessingNotifications else {
            return nil
        }
        let request = sync.nextRequest(for: apiVersion)

        if request != nil {
            pushNotificationStatus.didStartFetching()
        }

        return request
    }

    // MARK: Internal

    // MARK: - Properties

    var sync: NotificationStreamSync!
    weak var delegate: PushNotificationStrategyDelegate?

    // MARK: Private

    private var pushNotificationStatus: PushNotificationStatus!
    private var isProcessingNotifications = false
}

// MARK: NotificationStreamSyncDelegate

extension PushNotificationStrategy: NotificationStreamSyncDelegate {
    public func fetchedEvents(_ events: [ZMUpdateEvent], hasMoreToFetch: Bool) {
        WireLogger.notifications.info("fetched \(events.count) events, \(hasMoreToFetch ? "" : "no ")more to fetch")

        isProcessingNotifications = true

        let eventIds = events.compactMap(\.uuid)
        let latestEventId = events.last(where: { !$0.isTransient })?.uuid

        for event in events {
            event
                .appendDebugInformation(
                    "From missing update events transcoder, processUpdateEventsAndReturnLastNotificationIDFromPayload"
                )
            WireLogger.updateEvent.info("received event", attributes: event.logAttributes)
        }

        Task {
            do {
                try await delegate?.pushNotificationStrategy(self, didFetchEvents: events)
                await managedObjectContext.perform {
                    self.isProcessingNotifications = false
                    self.pushNotificationStatus.didFetch(
                        eventIds: eventIds,
                        lastEventId: latestEventId,
                        finished: !hasMoreToFetch
                    )
                    RequestAvailableNotification.notifyNewRequestsAvailable(nil)
                }

                if !hasMoreToFetch {
                    delegate?.pushNotificationStrategyDidFinishFetchingEvents(self)
                }
            } catch {
                WireLogger.notifications.warn("Failed to process fetched events: \(error)")
                await managedObjectContext.perform {
                    self.isProcessingNotifications = false
                }
                sync.reset()
                delegate?.pushNotificationStrategyDidFinishFetchingEvents(self)
            }
        }
    }

    func failedFetchingEvents(recoverable: Bool) {
        pushNotificationStatus.didFailToFetchEvents(recoverable: recoverable)
    }
}
