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

public protocol AnalyticsManagerProtocol {

    /// Switches the current analytics user and starts a new session.
    /// - Parameter userProfile: The profile of the user to switch to.
    /// - Returns: A new analytics session for the switched user.
    func switchUser(_ userProfile: AnalyticsUserProfile) -> any AnalyticsSessionProtocol

    /// Disables analytics tracking and reporting.
    /// This method should be used when analytics tracking needs to be disables, such as for privacy reasons.
    func disableTracking()

    /// Enables analytics tracking and reporting.
    /// This method should be used to re-enable analytics tracking after it has been disabled.
    /// - Parameter userProfile: The profile of the user to enable analytics for.
    /// - Returns: A new analytics session for the user.
    /// 
    /// - Warning: Ensure that any necessary state or user context is correctly restored before resuming tracking.
    func enableTracking(_ userProfile: AnalyticsUserProfile) -> any AnalyticsSessionProtocol

}
