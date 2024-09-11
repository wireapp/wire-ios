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

import Countly
import Foundation
import WireAnalytics

// MARK: - EnableAnalyticsSharingUseCaseProtocol

// sourcery: AutoMockable
/// Protocol defining the interface for enabling analytics sharing.
public protocol EnableAnalyticsUseCaseProtocol {

    /// Invokes the use case to enable analytics sharing.
    func invoke()
}

// MARK: - EnableAnalyticsUseCase

/// Concrete implementation of the EnableAnalyticsUseCaseProtocol.
/// This struct is responsible for enabling analytics sharing for a specific user profile.
struct EnableAnalyticsUseCase<UserSession>: EnableAnalyticsUseCaseProtocol
where UserSession: EnableAnalyticsUseCaseUserSession {

    // MARK: - Properties

    private let analyticsSessionConfiguration: AnalyticsSessionConfiguration

    private let analyticsManagerBuilder: (_ appKey: String, _ host: URL) -> any AnalyticsManagerProtocol

    private let sessionManager: AnalyticsManagerProviding

    private let analyticsUserProfile: AnalyticsUserProfile

    private let userSession: UserSession

    // MARK: - Initialization

    /// Initializes a new instance of EnableAnalyticsUseCase.
    ///
    /// - Parameters:
    ///   - analyticsManager: The analytics manager to use for enabling tracking.
    ///   - analyticsUserProfile: The user profile for which to enable analytics sharing.
    init(
        analyticsManagerBuilder: @escaping (_ appKey: String, _ host: URL) -> some AnalyticsManagerProtocol,
        sessionManager: AnalyticsManagerProviding,
        analyticsSessionConfiguration: AnalyticsSessionConfiguration,
        analyticsUserProfile: AnalyticsUserProfile,
        userSession: UserSession
    ) {
        self.analyticsManagerBuilder = analyticsManagerBuilder
        self.sessionManager = sessionManager
        self.analyticsSessionConfiguration = analyticsSessionConfiguration
        self.analyticsUserProfile = analyticsUserProfile
        self.userSession = userSession
    }

    // MARK: - Public methods

    /// Invokes the use case to enable analytics sharing for the specified user profile.
    ///
    /// This method calls the `enableTracking` method on the analytics manager
    /// with the provided user profile.
    func invoke() {
        let analyticsManager = analyticsManagerBuilder(
            analyticsSessionConfiguration.countlyKey,
            analyticsSessionConfiguration.host
        )

        sessionManager.analyticsManager = analyticsManager

        let analyticsSession = analyticsManager.enableTracking(analyticsUserProfile)
        userSession.analyticsSession = analyticsSession
    }
}

protocol EnableAnalyticsUseCaseUserSession: AnyObject {
    var analyticsSession: (any AnalyticsSessionProtocol)? { get set }
}
