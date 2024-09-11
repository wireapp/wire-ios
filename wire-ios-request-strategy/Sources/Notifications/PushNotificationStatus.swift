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
import WireDataModel

private let zmLog = ZMSLog(tag: "PushNotificationStatus")

@objcMembers
open class PushNotificationStatus: NSObject {
    public enum FetchError: Error {
        case invalidEventID
        case alreadyFetchedEvent
        case unknown
    }

    public typealias FetchCompletion = (Result<Void, FetchError>) -> Void

    private var eventIdRanking = NSMutableOrderedSet()
    private var completionHandlers: [UUID: FetchCompletion] = [:]
    private let managedObjectContext: NSManagedObjectContext
    private let lastEventIDRepository: LastEventIDRepositoryInterface
    private var isFetching = false

    public var hasEventsToFetch: Bool {
        // swiftformat:disable:next isEmpty
        eventIdRanking.count > 0 && !isFetching
    }

    public init(
        managedObjectContext: NSManagedObjectContext,
        lastEventIDRepository: LastEventIDRepositoryInterface
    ) {
        self.managedObjectContext = managedObjectContext
        self.lastEventIDRepository = lastEventIDRepository
    }

    /// Schedule to fetch an event with a given UUID
    ///
    /// - parameter eventId: UUID of the event to fetch
    /// - parameter completionHandler: The completion handler will be run when event has been downloaded and when
    /// there's no more events to fetch
    @objc(fetchEventId:completionHandler:)
    public func fetch(eventId: UUID, completionHandler: @escaping () -> Void) {
        fetch(eventId: eventId) { _ in
            completionHandler()
        }
    }

    /// Schedule to fetch an event with a given UUID
    ///
    /// - parameter eventId: UUID of the event to fetch
    /// - parameter completionHandler: The completion handler will be run when event has been downloaded and when
    /// there's no more events to fetch

    public func fetch(eventId: UUID, completionHandler: @escaping FetchCompletion) {
        let logAttributes: LogAttributes = [LogAttributesKey.eventId: eventId.safeForLoggingDescription].merging(
            .safePublic,
            uniquingKeysWith: { _, new in new }
        )
        guard eventId.isType1UUID else {
            WireLogger.eventProcessing.error(
                "Attempt to fetch event id not conforming to UUID type1",
                attributes: logAttributes
            )
            completionHandler(.failure(.invalidEventID))
            return
        }

        if lastEventIdIsNewerThan(
            lastEventId: lastEventIDRepository.fetchLastEventID(),
            eventId: eventId
        ) {
            WireLogger.eventProcessing.info("Already fetched event", attributes: logAttributes)
            completionHandler(.failure(.alreadyFetchedEvent))
            return
        }

        WireLogger.eventProcessing.info("Scheduling to fetch events notified by push", attributes: logAttributes)

        eventIdRanking.add(eventId)
        completionHandlers[eventId] = completionHandler

        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
    }

    public func didStartFetching() {
        isFetching = true
    }

    /// Report events that has successfully been downloaded from the notification stream
    ///
    /// - parameter eventIds: List of UUIDs for events that been downloaded
    /// - parameter finished: True when when all available events have been downloaded
    @objc(didFetchEventIds:lastEventId:finished:)
    public func didFetch(eventIds: [UUID], lastEventId: UUID?, finished: Bool) {
        let highestRankingEventId = eventIdRanking.firstObject as? UUID

        highestRankingEventId.map(eventIdRanking.remove)
        eventIdRanking.minusSet(Set<UUID>(eventIds))

        WireLogger.updateEvent.info(
            "finished fetching all available events, last event id: " +
                String(describing: lastEventId?.safeForLoggingDescription),
            attributes: .safePublic
        )

        guard finished else { return }

        // We take all events that are older than or equal to lastEventId and add highest ranking event ID
        for eventId in completionHandlers.keys.filter({ self.lastEventIdIsNewerThan(
            lastEventId: lastEventId,
            eventId: $0
        ) || highestRankingEventId == $0 }) {
            let completionHandler = completionHandlers.removeValue(forKey: eventId)
            completionHandler?(.success(()))
        }

        isFetching = false
    }

    /// Report that events couldn't be fetched due to an error
    public func didFailToFetchEvents(recoverable: Bool) {
        defer { isFetching = false }

        guard !recoverable else { return }

        for completionHandler in completionHandlers.values {
            completionHandler(.failure(.unknown))
        }

        eventIdRanking.removeAllObjects()
        completionHandlers.removeAll()
    }

    private func lastEventIdIsNewerThan(lastEventId: UUID?, eventId: UUID) -> Bool {
        guard let order = lastEventId?.compare(withType1: eventId) else { return false }
        return order == .orderedDescending || order == .orderedSame
    }
}
