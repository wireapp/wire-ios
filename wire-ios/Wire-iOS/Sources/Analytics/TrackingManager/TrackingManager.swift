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

import avs
import Foundation
import WireCommonComponents
import WireSyncEngine

final class TrackingManager: NSObject, TrackingInterface {

    private let sessionManager: SessionManager
    private var observerToken: NSObjectProtocol?

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
        super.init()
        AVSFlowManager.getInstance()?.setEnableMetrics(!isAnalyticsDisabled)
        observerToken = NotificationCenter.default.addObserver(
            forName: FlowManager.AVSFlowManagerCreatedNotification,
            object: nil,
            queue: OperationQueue.main,
            using: { [weak self] _ in
                guard let self else { return }
                AVSFlowManager.getInstance()?.setEnableMetrics(!self.isAnalyticsDisabled)
            }
        )
    }

    var doesUserConsentPreferenceExist: Bool {
        ExtensionSettings.shared.disableAnalyticsSharing != nil
    }

    var isAnalyticsDisabled: Bool {
        ExtensionSettings.shared.disableAnalyticsSharing ?? true
    }

    @MainActor
    func firstTimeRequestToEnableAnalytics() async throws {
        // Only ask if user has not given a preference yet.
        guard !doesUserConsentPreferenceExist else {
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
        ExtensionSettings.shared.disableAnalyticsSharing = false
        AVSFlowManager.getInstance()?.setEnableMetrics(true)
    }

    func disableAnalytics() throws {
        try sessionManager.makeDisableAnalyticsUseCase().invoke()
        ExtensionSettings.shared.disableAnalyticsSharing = true
        AVSFlowManager.getInstance()?.setEnableMetrics(false)
    }

}
