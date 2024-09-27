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

// MARK: - NotificationsTracker

@objcMembers
public class NotificationsTracker: NSObject {
    // MARK: Lifecycle

    public init(analytics: AnalyticsType) {
        self.analytics = analytics
    }

    // MARK: Public

    public enum Attributes: String {
        case startedProcessing
        case startedFetchingStream
        case finishedFetchingStream
        case finishedProcessing
        case processingExpired
        case abortedProcessing
        case tokenMismatch

        // MARK: Public

        public var identifier: String {
            "notifications_" + rawValue
        }
    }

    public let eventName = "notifications.processing"

    public func registerReceivedPush() {
        increment(attribute: .startedProcessing)
    }

    public func registerNotificationProcessingCompleted() {
        increment(attribute: .finishedProcessing)
    }

    public func registerFinishStreamFetching() {
        increment(attribute: .finishedFetchingStream)
    }

    public func registerStartStreamFetching() {
        increment(attribute: .startedFetchingStream)
    }

    public func registerProcessingExpired() {
        increment(attribute: .processingExpired)
    }

    public func registerProcessingAborted() {
        increment(attribute: .abortedProcessing)
    }

    public func registerTokenMismatch() {
        increment(attribute: .tokenMismatch)
    }

    public func dispatchEvent() {
        isolationQueue.sync {
            if let analytics, let attributes = analytics.persistedAttributes(for: eventName), !attributes.isEmpty {
                analytics.tagEvent(eventName, attributes: attributes)
                analytics.setPersistedAttributes(nil, for: eventName)
            }
        }
    }

    // MARK: Internal

    weak var analytics: AnalyticsType?

    // MARK: Private

    private let isolationQueue = DispatchQueue(label: "NotificationsProcessing")

    private func increment(attribute: Attributes, by amount: Double = 1) {
        isolationQueue.sync {
            var currentAttributes = analytics?.persistedAttributes(for: eventName) ?? [:]
            var value = (currentAttributes[attribute.identifier] as? Double) ?? 0
            value += amount
            currentAttributes[attribute.identifier] = value as NSObject
            analytics?.setPersistedAttributes(currentAttributes, for: eventName)
        }
    }
}

extension NotificationsTracker {
    override public var debugDescription: String {
        "Current values: \(analytics?.persistedAttributes(for: eventName) ?? [:])"
    }
}
