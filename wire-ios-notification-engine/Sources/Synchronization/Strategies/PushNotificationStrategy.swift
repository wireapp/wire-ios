//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

import WireRequestStrategy
import Foundation

protocol PushNotificationStrategyDelegate: AnyObject {

    func pushNotificationStrategy(_ strategy: PushNotificationStrategy, didFetchEvents events: [ZMUpdateEvent])
    func pushNotificationStrategyDidFinishFetchingEvents(_ strategy: PushNotificationStrategy)

}

final class PushNotificationStrategy: AbstractRequestStrategy, ZMRequestGeneratorSource {

    // MARK: - Properties

    var sync: NotificationStreamSync!
    private var pushNotificationStatus: PushNotificationStatus!

    weak var delegate: PushNotificationStrategyDelegate?

    // MARK: - Life cycle

    init(
        syncContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        pushNotificationStatus: PushNotificationStatus,
        notificationsTracker: NotificationsTracker?
    ) {
        super.init(
            withManagedObjectContext: syncContext,
            applicationStatus: applicationStatus
        )

        sync = NotificationStreamSync(
            moc: syncContext,
            notificationsTracker: notificationsTracker,
            delegate: self
        )

        self.pushNotificationStatus = pushNotificationStatus
    }

    // MARK: - Methods

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return nextRequest(for: apiVersion)
    }

    public override func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard isFetchingStreamForAPNS else { return nil }
        return requestGenerators.nextRequest(for: apiVersion)
    }

    public var requestGenerators: [ZMRequestGenerator] {
           return [sync]
       }

    public var isFetchingStreamForAPNS: Bool {
        return self.pushNotificationStatus.hasEventsToFetch
    }

}

// MARK: - Notification stream sync delegate

extension PushNotificationStrategy: NotificationStreamSyncDelegate {

    public func fetchedEvents(_ events: [ZMUpdateEvent], hasMoreToFetch: Bool) {
        WireLogger.notifications.info("fetched \(events.count) events, \(hasMoreToFetch ? "" : "no ")more to fetch")

        var eventIds: [UUID] = []
        var parsedEvents: [ZMUpdateEvent] = []
        var latestEventId: UUID?

        for event in events {
            event.appendDebugInformation("From missing update events transcoder, processUpdateEventsAndReturnLastNotificationIDFromPayload")
            parsedEvents.append(event)

            if let uuid = event.uuid {
                eventIds.append(uuid)
            }

            if !event.isTransient {
                latestEventId = event.uuid
            }
        }

        delegate?.pushNotificationStrategy(self, didFetchEvents: parsedEvents)
        pushNotificationStatus.didFetch(eventIds: eventIds, lastEventId: latestEventId, finished: !hasMoreToFetch)

        if !hasMoreToFetch {
            delegate?.pushNotificationStrategyDidFinishFetchingEvents(self)
        }
    }

    public func failedFetchingEvents() {
        pushNotificationStatus.didFailToFetchEvents()
    }
}
