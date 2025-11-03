//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import UIKit
import WireAnalytics
import WireAuthenticationAPI
import WireFoundation
import WireLogging
import WireNetwork
import WireSyncEngine

final class RegistrationAnalyticsTracker: RegistrationAnalyticsTrackerProtocol {

    /// This UserDefaults key is used for storing an analytics tracking ID during the process of creating a new personal
    /// user account. The value is cleared only once the flow is completed, so that switching back and forth between
    /// enabling or disabling analytics is tracked under the same identifier.
    private let trackingIDDefaultsKey = "tempTrackingID"

    private var analyticsService: AnalyticsService?
    private var analyticsTracker: (any AnalyticsEventTrackerProtocol)?
    private var availabilityChecker: any AnalyticsTrackingAvailabilityCheckerProtocol
    private let userDefaults: UserDefaults
    private let logger: WireLogger

    init(
        analyticsServiceConfiguration: AnalyticsServiceConfiguration?,
        availabilityChecker: any AnalyticsTrackingAvailabilityCheckerProtocol,
        countlyProvider: @escaping () -> any CountlyProtocol,
        userDefaults: UserDefaults
    ) {
        self.analyticsService = analyticsServiceConfiguration.map { config in
            AnalyticsService(
                config: CountlyConfiguration(appKey: config.secretKey, host: config.serverHost),
                deviceModel: UIDevice.current.model,
                osVersion: UIDevice.current.systemVersion,
                countlyProvider: countlyProvider
            )
        }
        self.availabilityChecker = availabilityChecker
        self.userDefaults = userDefaults
        self.logger = .authentication
    }

    var trackingID: String? {
        analyticsService?.currentDeviceID
    }

    func isAnalyticsTrackingAvailable(for environment: BackendEnvironment2) -> Bool {
        guard analyticsService != nil else { return false }
        return availabilityChecker.isAnalyticsTrackingAvailable(for: environment)
    }

    @MainActor
    func setUp() {
        do {
            let analyticsUser = createAnalyticsUserIfNeeded()
            try enableAnalytics(user: analyticsUser)
        } catch {
            logger.error("Can't set up analytics during personal account registration")
        }
    }

    func tearDown() {
        do {
            try disableAnalytics()
        } catch {
            logger.error("Can't disable analytics during personal account registration")
        }
    }

    func trackPersonalAccountCreationStart() {
        analyticsTracker?.trackEvent(.Registration.accountSetupStep0)
    }

    func trackPersonalAccountCreationReachedTermsOfUseConfirmation() {
        analyticsTracker?.trackEvent(.Registration.accountSetupStep1)
    }

    func trackPersonalAccountCreationReachedVerificationCode() {
        analyticsTracker?.trackEvent(.Registration.accountSetupStep2)
    }

    func trackPersonalAccountCreationFailedCodeVerification() {
        analyticsTracker?.trackEvent(.Registration.accountSetupStep3)
    }

    func trackPersonalAccountCreationReachedUsernameForm() {
        analyticsTracker?.trackEvent(.Registration.accountSetupStep4)
    }

    func trackPersonalAccountCreationCompletion() {
        analyticsTracker?.trackEvent(.Registration.accountSetupStep5)
    }

    func deleteTemporaryTrackingID() {
        userDefaults.removeObject(forKey: trackingIDDefaultsKey)
    }

    // MARK: - Helpers

    @MainActor
    private func enableAnalytics(user: AnalyticsUser) throws {
        analyticsService?.enableTracking()
        try analyticsService?.switchUser(user)
        analyticsTracker = analyticsService
    }

    private func disableAnalytics() throws {
        try analyticsService?.disableTracking()
        analyticsTracker = nil
    }

    private func createAnalyticsUserIfNeeded() -> AnalyticsUser {

        if let trackingID = userDefaults.string(forKey: trackingIDDefaultsKey).flatMap(UUID.init(transportString:)) {
            return AnalyticsUser(trackingID: trackingID, teamInfo: nil)
        }

        let trackingID = UUID()
        userDefaults.set(trackingID.transportString(), forKey: trackingIDDefaultsKey)
        return AnalyticsUser(trackingID: trackingID, teamInfo: nil)

    }

}
