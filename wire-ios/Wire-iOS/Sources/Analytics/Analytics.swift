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
import WireSyncEngine

final class Analytics: NSObject {

    private var callingTracker: AnalyticsCallingTracker?

    static var shared: Analytics!

    func tagEvent(_ event: String,
                  attributes: [String: Any]) {
        guard let attributes = attributes as? [String: NSObject] else { return }

        tagEvent(event, attributes: attributes)
    }
}

extension Analytics: AnalyticsType {
    func setPersistedAttributes(_ attributes: [String: NSObject]?, for event: String) {
        // no-op
    }

    func persistedAttributes(for event: String) -> [String: NSObject]? {
        // no-op
        return nil
    }

    /// Record an event with optional attributes.
    /// - Parameters:
    ///   - event: event to tag
    ///   - attributes: attributes of the event
    func tagEvent(_ event: String, attributes: [String: NSObject]) {
    }
}
