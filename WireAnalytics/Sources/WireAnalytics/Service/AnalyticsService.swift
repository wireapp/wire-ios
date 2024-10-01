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

/// A service for tracking analytics data generated by the user.

public final class AnalyticsService: AnalyticsEventTracker {

    public typealias Config = (secretKey: String, serverHost: URL)

    private let config: Config?
    private let countlyProvider: () -> any CountlyProtocol
    private var countly: (any CountlyProtocol)?
    private var currentUser: AnalyticsUser?

    // MARK: - Life cycle

    /// Create a new `AnalyticsService`.
    ///
    /// A non-nil config is needed to track analytics data.
    ///
    /// - Parameters:
    ///   - config: A config containing the authentication key and server host.

    public convenience init(config: Config?) {
        self.init(config: config) {
            Countly.sharedInstance()
        }
    }

    init(
         config: Config?,
         countlyProvider: @escaping () -> any CountlyProtocol
    ) {
        self.config = config
        self.countlyProvider = countlyProvider
    }

    // MARK: - Enable / disable

    /// Start sending analytics data.

    public func enableTracking() throws {
        guard let config else {
            throw AnalyticsServiceError.serviceIsNotConfigured
        }

        print("[ANALYTICS] enabling tracking")

        let countly = countlyProvider()
        self.countly = countly


        countly.start(
            appKey: config.secretKey,
            host: config.serverHost
        )
    }

    /// Stop sending analytics data.

    public func disableTracking() throws {
        guard let countly else {
            throw AnalyticsServiceError.serviceIsNotConfigured
        }

        print("[ANALYTICS] disabling tracking")

        countly.endSession()
        clearCurrentUser()
        countly.resetInstance()
        self.countly = nil
    }

    // MARK: - User

    /// Switch the current analytics user.
    ///
    /// - Parameter user: The user to switch to.

    public func switchUser(_ user: AnalyticsUser) {
        guard 
            let countly,
            user != currentUser
        else {
            return
        }

        print("[ANALYTICS] switching user")

        countly.endSession()
        
        pushUser(
            user,
            mergeData: false
        )

        countly.beginSession()
    }
    
    /// Update the current user.
    ///
    /// If the user's id changed, all previously tracked data associated with
    /// the current id will be associated with the new id.
    ///
    /// - Parameter user: The updated current user.

    public func updateCurrentUser(_ user: AnalyticsUser) {
        print("[ANALYTICS] updating current user")

        pushUser(
            user,
            mergeData: true
        )
    }

    private func pushUser(
        _ user: AnalyticsUser?,
        mergeData: Bool
    ) {
        guard let countly else {
            return
        }

        if let id = user?.analyticsIdentifier {
            countly.changeDeviceID(
                id,
                mergeData: mergeData
            )
        }

        countly.setUserValue(
            user?.teamInfo?.id,
            forKey: AnalyticsUserKey.teamID.rawValue
        )

        countly.setUserValue(
            user?.teamInfo?.role,
            forKey: AnalyticsUserKey.teamRole.rawValue
        )

        countly.setUserValue(
            user?.teamInfo.map { String($0.size.logRound()) },
            forKey: AnalyticsUserKey.teamSize.rawValue
        )

        currentUser = user
    }

    private func clearCurrentUser() {
        print("[ANALYTICS] clearing current user")

        pushUser(
            nil,
            mergeData: false
        )
    }


    // MARK: - Event

    /// Track an event.
    ///
    /// - Parameter event: The event to track.

    public func trackEvent(_ event: AnalyticsEvent) {
        guard let countly else {
            return
        }

        guard let currentUser else {
            return
        }

        var segmentation = event.segmentation
        segmentation.insert(.isSelfTeamMember(currentUser.teamInfo != nil))
        segmentation.insert(.deviceModel(UIDevice.current.model))
        segmentation.insert(.deviceOS(UIDevice.current.systemVersion))

        let rawSegmentation = Dictionary(uniqueKeysWithValues: segmentation.map {
            ($0.key, $0.value)
        })

        print("[ANALYTICS] tracking event: \(event)")

        countly.recordEvent(
            event.name,
            segmentation: rawSegmentation
        )
    }

}
