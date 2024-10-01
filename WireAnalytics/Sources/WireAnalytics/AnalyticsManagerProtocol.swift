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

    /// Updates the user analytics identifier and merges data from the previous identifier.
    ///
    /// - Parameters:
    ///   - userProfile: The updated profile of the user.
    ///   - mergeData: A Boolean indicating whether to merge data from the previous identifier.
    func updateUserAnalyticsIdentifier(_ userProfile: AnalyticsUser, mergeData: Bool)

    /// Switches the current analytics user and starts a new session.
    /// - Parameter userProfile: The profile of the user to switch to.
    /// - Returns: A new analytics session for the switched user.
    func switchUser(_ userProfile: AnalyticsUser) -> any AnalyticsSessionProtocol

    /// Disables analytics tracking and reporting.
    /// This method should be used when analytics tracking needs to be disables, such as for privacy reasons.
    func disableTracking()

    /// Enables analytics tracking and reporting.
    /// This method should be used to re-enable analytics tracking after it has been disabled.
    /// - Parameter userProfile: The profile of the user to enable analytics for.
    /// - Returns: A new analytics session for the user.
    func enableTracking(_ userProfile: AnalyticsUser) -> any AnalyticsSessionProtocol

}
