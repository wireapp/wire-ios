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

// sourcery: AutoMockable
/// An API access object for endpoints concerning update events.
public protocol UpdateEventsAPI {

    /// Get the last (most recent) update event for the self client.
    ///
    /// - Parameter selfClientID: The id of the self client.
    /// - Returns: An update envelope containing the last update event.

    func getLastUpdateEvent(selfClientID: String) async throws -> UpdateEventEnvelope

    /// Get all update events for the self client since a particular event.
    ///
    /// - Parameters:
    ///   - selfClientID: The id of the self client.
    ///   - sinceEventID: The id of the event after which the events should be returned.
    ///
    /// - Returns: A pager of events since (but not including) the specified event.

    func getUpdateEvents(
        selfClientID: String,
        sinceEventID: UUID
    ) -> PayloadPager<UpdateEventEnvelope>

}
