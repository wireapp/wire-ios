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

import avs
import Foundation
import WireCommonComponents
import WireDomain
import WireFoundation
import WireLogging
import WireSyncEngine

final class TrackingManager: TrackingInterface {

    private let sessionManager: SessionManager
    private var observerToken: NSObjectProtocol?

    private typealias UserDefaultsKey = AnalyticsTrackingPrivateUserDefaultsKey
    private var privateUserDefaults: PrivateUserDefaults<UserDefaultsKey>? {
        sessionManager.accountManager.selectedAccount.map { selectedAccount in
            PrivateUserDefaults<UserDefaultsKey>(
                userID: selectedAccount.userIdentifier,
                storage: UserDefaults.standard
            )
        }
    }

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager

        self.observerToken = NotificationCenter.default.addObserver(
            forName: FlowManager.AVSFlowManagerCreatedNotification,
            object: nil,
            queue: .main,
            using: { [weak self] _ in
                guard let self else { return }
                AVSFlowManager.getInstance()?.setEnableMetrics(isAnalyticsTrackingEnabled)
            }
        )

        AVSFlowManager.getInstance()?.setEnableMetrics(isAnalyticsTrackingEnabled)
    }

    private var doesUserConsentPreferenceExist: Bool {
        privateUserDefaults?.object(forKey: .isAnalyticsTrackingEnabled) is Bool
    }

    var isAnalyticsTrackingEnabled: Bool {
        privateUserDefaults?.object(forKey: .isAnalyticsTrackingEnabled) as? Bool ?? false
    }

    func migrateAnalyticsSetupIfNeeded() async throws {
        if doesUserConsentPreferenceExist {
            if isAnalyticsTrackingEnabled {
                try await enableAnalytics()
            } else {
                try disableAnalytics()
            }
        }
    }

    @MainActor
    func firstTimeRequestToEnableAnalytics() async throws {
        // Ask if user has not given a preference yet
        // and tracking can be enabled
        guard !doesUserConsentPreferenceExist, sessionManager.canEnableTracking else {
            return
        }

        WireLogger.analytics.debug("requesting first time analytics content")
        let didConsent = try await requestAnalyticsConsent()
        WireLogger.analytics.debug("user did consent: \(didConsent)")

        if didConsent {
            try await enableAnalytics()
        } else {
            try disableAnalytics()
        }
    }

    func enableAnalytics() async throws {
        try await sessionManager.makeEnableAnalyticsUseCase()?.invoke()
        AVSFlowManager.getInstance()?.setEnableMetrics(true)
        privateUserDefaults?.set(true, forKey: .isAnalyticsTrackingEnabled)
    }

    func disableAnalytics() throws {
        try sessionManager.makeDisableAnalyticsUseCase()?.invoke()
        AVSFlowManager.getInstance()?.setEnableMetrics(false)
        privateUserDefaults?.set(false, forKey: .isAnalyticsTrackingEnabled)
    }

}
