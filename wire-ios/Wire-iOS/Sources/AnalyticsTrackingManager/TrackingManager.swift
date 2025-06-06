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
import WireLogging
import WireSyncEngine

final class TrackingManager: TrackingInterface {

    private let sessionManager: SessionManager
    private var observerToken: NSObjectProtocol?

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager

        migrateFromLegacyStorageIfNeeded()

        self.observerToken = NotificationCenter.default.addObserver(
            forName: FlowManager.AVSFlowManagerCreatedNotification,
            object: nil,
            queue: .main,
            using: { [weak self] _ in
                guard let self else { return }
                AVSFlowManager.getInstance()?.setEnableMetrics(isAnalyticsEnabled)
            }
        )

        AVSFlowManager.getInstance()?.setEnableMetrics(isAnalyticsEnabled)
    }

    private var doesUserConsentPreferenceExist: Bool {
        migrateFromLegacyStorageIfNeeded()

        guard let selectedAccount = sessionManager.accountManager.selectedAccount else { return false }
        return ExtensionSettings.shared.analyticsEnabledAccounts.keys.contains(selectedAccount.userIdentifier)
    }

    var isAnalyticsEnabled: Bool {
        migrateFromLegacyStorageIfNeeded()

        guard let selectedAccount = sessionManager.accountManager.selectedAccount else { return false }
        return ExtensionSettings.shared.analyticsEnabledAccounts[selectedAccount.userIdentifier] ?? false
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
        try await sessionManager.makeEnableAnalyticsUseCase().invoke()
        AVSFlowManager.getInstance()?.setEnableMetrics(true)

        if let userIdentifier = sessionManager.accountManager.selectedAccount.map(\.userIdentifier) {
            ExtensionSettings.shared.analyticsEnabledAccounts[userIdentifier] = true
        }
    }

    func disableAnalytics() throws {
        try sessionManager.makeDisableAnalyticsUseCase().invoke()
        AVSFlowManager.getInstance()?.setEnableMetrics(false)

        if let userIdentifier = sessionManager.accountManager.selectedAccount.map(\.userIdentifier) {
            ExtensionSettings.shared.analyticsEnabledAccounts[userIdentifier] = false
        }
    }

    /// Previously the consent for analytics tracking was stored only once per app.
    /// If the consent has been given, mark all currently set up accounts as consent being given.

    private func migrateFromLegacyStorageIfNeeded() {
        guard let disableAnalyticsSharing = ExtensionSettings.shared.disableAnalyticsSharing_ else { return }

        let userIdentifiers = sessionManager.accountManager.accounts.map(\.userIdentifier)
        let analyticsEnabledAccounts = userIdentifiers.reduce(into: [:]) { result, userIdentifier in
            result[userIdentifier] = !disableAnalyticsSharing
        }
        ExtensionSettings.shared.analyticsEnabledAccounts = analyticsEnabledAccounts

        ExtensionSettings.shared.disableAnalyticsSharing_ = nil
    }

}
