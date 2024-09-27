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

// MARK: - MockAnalytics

final class MockAnalytics: NSObject, AnalyticsType {
    // MARK: Public

    public func setPersistedAttributes(_ attributes: [String: NSObject]?, for event: String) {
        if let attributes {
            eventAttributes[event] = attributes
        } else {
            eventAttributes.removeValue(forKey: event)
        }
    }

    public func persistedAttributes(for event: String) -> [String: NSObject]? {
        eventAttributes[event] ?? [:]
    }

    // MARK: Internal

    var eventAttributes = [String: [String: NSObject]]()

    var taggedEvents = [String]()
    var taggedEventsWithAttributes = [EventWithAttributes]()
    var uploadCallCount = 0

    @objc
    func tagEvent(_ event: String) {
        taggedEvents.append(event)
    }

    @objc
    func tagEvent(_ event: String, attributes: [String: NSObject]) {
        taggedEventsWithAttributes.append(EventWithAttributes(event: event, attributes: attributes))
    }

    @objc
    func upload() {
        uploadCallCount += 1
    }
}

// MARK: - EventWithAttributes

struct EventWithAttributes: Equatable {
    let event: String
    let attributes: [String: NSObject]
}

func == (lhs: EventWithAttributes, rhs: EventWithAttributes) -> Bool {
    lhs.event == rhs.event && lhs.attributes == rhs.attributes
}
