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
/// Protocol defining the requirements for an analytics service.
protocol AnalyticsService {
    /// Starts the analytics service with the given app key and host.
    ///
    /// - Parameters:
    ///   - appKey: The key for the analytics application.
    ///   - host: The URL of the analytics host.
    func start(appKey: String, host: URL)

    /// Begins a new analytics session.
    func beginSession()

    /// Ends the current analytics session.
    func endSession()

    /// Changes the device ID used for analytics.
    ///
    /// - Parameter id: The new device ID.
    func changeDeviceID(_ id: String)

    /// Sets a user value for a given key in the analytics service.
    ///
    /// - Parameters:
    ///   - value: The value to set.
    ///   - key: The key for the value.
    func setUserValue(_ value: String?, forKey key: String)

    func trackEvent(name: String, segmentation: [String: String])
}
