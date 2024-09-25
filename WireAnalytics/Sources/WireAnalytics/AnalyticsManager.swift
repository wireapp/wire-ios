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

/// Struct responsible for managing analytics operations.
public struct AnalyticsManager<Countly: CountlyAbstraction>: AnalyticsManagerProtocol {
    /// The underlying analytics service.
    private let analyticsService: any AnalyticsServiceProtocol

    /// Initializes a new AnalyticsManager with the given app key and host.
    ///
    /// - Parameters:
    ///   - appKey: The key for the analytics application.
    ///   - host: The URL of the analytics host.
    public init(appKey: String, host: URL) {
        self.init(
            appKey: appKey,
            host: host,
            analyticsService: AnalyticsService(countly: Countly.sharedInstance())
        )
    }

    /// Initializes a new AnalyticsManager with the given app key, host, and analytics service.
    ///
    /// - Parameters:
    ///   - appKey: The key for the analytics application.
    ///   - host: The URL of the analytics host.
    ///   - analyticsService: The analytics service to use.
    init(
        appKey: String,
        host: URL,
        analyticsService: any AnalyticsServiceProtocol
    ) {
        self.analyticsService = analyticsService
        self.analyticsService.start(appKey: appKey, host: host)
    }

    public func updateUserAnalyticsIdentifier(_ userProfile: AnalyticsUserProfile, mergeData: Bool) {
        analyticsService.changeDeviceID(userProfile.analyticsIdentifier, mergeData: mergeData)
        updateUserProfile(userProfile)
    }

    /// Switches the current user and begins a new analytics session.
    ///
    /// - Parameter userProfile: The profile of the user to switch to.
    /// - Returns: An object conforming to AnalyticsSessionProtocol for the new session.
    public func switchUser(_ userProfile: AnalyticsUserProfile) -> any AnalyticsSessionProtocol {
        analyticsService.endSession()
        updateUserProfile(userProfile)
        analyticsService.changeDeviceID(userProfile.analyticsIdentifier, mergeData: false)
        analyticsService.beginSession()

        return AnalyticsSession(
            isSelfTeamMember: userProfile.teamInfo != nil,
            service: analyticsService
        )
    }

    /// Disables tracking by ending the current session and clearing user data.
    public func disableTracking() {
        analyticsService.endSession()
        clearUserData()
    }

    /// Enables tracking for a given user profile.
    ///
    /// - Parameter userProfile: The profile of the user to enable tracking for.
    /// - Returns: An object conforming to AnalyticsSessionProtocol for the new session.
    public func enableTracking(_ userProfile: AnalyticsUserProfile) -> any AnalyticsSessionProtocol {
        switchUser(userProfile)
    }

    // MARK: - Private Helper Methods

    private func updateUserProfile(_ userProfile: AnalyticsUserProfile) {
        analyticsService.setUserValue(userProfile.teamInfo?.id, forKey: AnalyticsUserKey.teamID.rawValue)
        analyticsService.setUserValue(userProfile.teamInfo?.role, forKey: AnalyticsUserKey.teamRole.rawValue)
        analyticsService.setUserValue(userProfile.teamInfo.map { String($0.size.logRound()) }, forKey: AnalyticsUserKey.teamSize.rawValue)
    }

    private func clearUserData() {
        for key in AnalyticsUserKey.allCases {
            analyticsService.setUserValue(nil, forKey: key.rawValue)
        }
    }

}
