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

/// A service for tracking analytics data generated by the user.
public protocol AnalyticsServiceProtocol: AnalyticsEventTracker {

    /// Whether tracking is currently enabled.

    var isTrackingEnabled: Bool { get }

    /// Start sending analytics data.

    func enableTracking() async throws

    /// Stop sending analytics data.

    func disableTracking() throws

    /// Switch the current analytics user.
    ///
    /// - Parameter user: The user to switch to.

    func switchUser(_ user: AnalyticsUser) throws

    /// Update the current user.
    ///
    /// If the user's id changed, all previously tracked data associated with
    /// the current id will be associated with the new id.
    ///
    /// - Parameter user: The updated current user.

    func updateCurrentUser(_ user: AnalyticsUser) throws

}
