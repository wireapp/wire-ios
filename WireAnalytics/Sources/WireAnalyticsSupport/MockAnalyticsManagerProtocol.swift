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

import WireAnalytics

// MARK: - MockAnalyticsManagerProtocol

public class MockAnalyticsManagerProtocol: AnalyticsManagerProtocol {

    public init() {}

    // MARK: - switchUser

    public var invokedSwitchUser = false
    public var invokedSwitchUserCount = 0
    public var invokedSwitchUserParameters: (userProfile: AnalyticsUser, Void)?
    public var invokedSwitchUserParametersList = [(userProfile: AnalyticsUser, Void)]()
    public var stubbedSwitchUserResult: AnalyticsSessionProtocol!

    public func switchUser(_ userProfile: AnalyticsUser) -> any AnalyticsSessionProtocol {
        invokedSwitchUser = true
        invokedSwitchUserCount += 1
        invokedSwitchUserParameters = (userProfile, ())
        invokedSwitchUserParametersList.append((userProfile, ()))
        return stubbedSwitchUserResult
    }

    // MARK: - disableTracking

    public var invokedDisableTracking = false
    public var invokedDisableTrackingCount = 0

    public func disableTracking() {
        invokedDisableTracking = true
        invokedDisableTrackingCount += 1
    }

    // MARK: - enableTracking

    public var invokedEnableTracking = false
    public var invokedEnableTrackingCount = 0
    public var invokedEnableTrackingParameters: (userProfile: AnalyticsUser, Void)?
    public var invokedEnableTrackingParametersList = [(userProfile: AnalyticsUser, Void)]()
    public var stubbedEnableTrackingResult: AnalyticsSessionProtocol!

    public func enableTracking(_ userProfile: AnalyticsUser) -> any AnalyticsSessionProtocol {
        invokedEnableTracking = true
        invokedEnableTrackingCount += 1
        invokedEnableTrackingParameters = (userProfile, ())
        invokedEnableTrackingParametersList.append((userProfile, ()))
        return stubbedEnableTrackingResult
    }

    // MARK: - updateUserAnalyticsIdentifier

    public var invokedUpdateUserAnalyticsIdentifier = false
    public var invokedUpdateUserAnalyticsIdentifierCount = 0
    public var invokedUpdateUserAnalyticsIdentifierParameters: (userProfile: AnalyticsUser, mergeData: Bool)?
    public var invokedUpdateUserAnalyticsIdentifierParametersList = [(userProfile: AnalyticsUser, mergeData: Bool)]()

    public func updateUserAnalyticsIdentifier(_ userProfile: AnalyticsUser, mergeData: Bool) {
        invokedUpdateUserAnalyticsIdentifier = true
        invokedUpdateUserAnalyticsIdentifierCount += 1
        invokedUpdateUserAnalyticsIdentifierParameters = (userProfile, mergeData)
        invokedUpdateUserAnalyticsIdentifierParametersList.append((userProfile, mergeData))
    }
}
