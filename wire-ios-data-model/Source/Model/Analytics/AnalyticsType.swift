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

// MARK: - AnalyticsType

@objc
public protocol AnalyticsType: NSObjectProtocol {
    func tagEvent(_ event: String)
    func tagEvent(_ event: String, attributes: [String: NSObject])

    @objc(setPersistedAttributes:forEvent:)
    func setPersistedAttributes(_ attributes: [String: NSObject]?, for event: String)
    @objc(persistedAttributesForEvent:)
    func persistedAttributes(for event: String) -> [String: NSObject]?
}

// MARK: - DebugAnalytics

// Used for debugging only
@objc
public final class DebugAnalytics: NSObject, AnalyticsType {
    // MARK: Public

    public func tagEvent(_ event: String) {
        print(Date(), "[ANALYTICS]", #function, event)
    }

    public func tagEvent(_ event: String, attributes: [String: NSObject]) {
        print(Date(), "[ANALYTICS]", #function, event, attributes)
    }

    public func setPersistedAttributes(_ attributes: [String: NSObject]?, for event: String) {
        if let attributes {
            eventAttributes[event] = attributes
        } else {
            eventAttributes.removeValue(forKey: event)
        }
        print(Date(), "[ANALYTICS]", #function, event, eventAttributes[event] ?? [:])
    }

    public func persistedAttributes(for event: String) -> [String: NSObject]? {
        let value = eventAttributes[event] ?? [:]
        print(Date(), "[ANALYTICS]", #function, event, value)
        return value
    }

    // MARK: Internal

    var eventAttributes = [String: [String: NSObject]]()
}
