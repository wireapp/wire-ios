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
import WireAnalytics

// sourcery: AutoMockable
/// Protocol defining the interface for disabling analytics sharing.
public protocol DisableAnalyticsUseCaseProtocol {

    /// Invokes the use case to disable analytics sharing.
    func invoke()
}

/// Concrete implementation of the DisableAnalyticsUseCaseProtocol.
/// This struct is responsible for disabling analytics sharing.
public struct DisableAnalyticsUseCase: DisableAnalyticsUseCaseProtocol {

    private let analyticsManager: AnalyticsManagerProtocol

    /// Initializes a new instance of DisableAnalyticsUseCase.
    ///
    /// - Parameter analyticsManager: The analytics manager to use for disabling tracking.
    public init(analyticsManager: AnalyticsManagerProtocol) {
        self.analyticsManager = analyticsManager
    }

    /// Invokes the use case to disable analytics sharing.
    ///
    /// This method calls the `disableTracking` method on the analytics manager if it exists.
    public func invoke() {
        analyticsManager.disableTracking()
    }
}
