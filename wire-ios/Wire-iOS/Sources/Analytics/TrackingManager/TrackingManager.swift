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

enum TrackingMAnagerError: Error {
    case userConsentDenied
}

final class TrackingManager: NSObject, TrackingInterface {

    private let flowManagerObserver: NSObjectProtocol
    private let sessionManager: SessionManager

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager

        AVSFlowManager.getInstance()?.setEnableMetrics(!ExtensionSettings.shared.disableAnalyticsSharing)

        flowManagerObserver = NotificationCenter.default.addObserver(
            forName: FlowManager.AVSFlowManagerCreatedNotification,
            object: nil,
            queue: OperationQueue.main,
            using: { _ in
                AVSFlowManager.getInstance()?.setEnableMetrics(!ExtensionSettings.shared.disableAnalyticsSharing)
            }
        )

        super.init()
    }

    var disableAnalyticsSharing: Bool {
        get { ExtensionSettings.shared.disableAnalyticsSharing }
    }

    func disableAnalyticsSharing(isDisabled: Bool, resultHandler: @escaping (Result<Void, any Error>) -> Void) {
        let isEnabled = !isDisabled

        if isEnabled {
            self.showAnalyticsConsentAlert { userConsented in
                if userConsented {
                    self.updateAnalyticsSharing(disabled: false)
                    resultHandler(.success(()))
                } else {
                    // User rejected, so we keep analytics disabled
                    self.updateAnalyticsSharing(disabled: true)
                    resultHandler(.failure(TrackingMAnagerError.userConsentDenied))
                }
            }
        } else {
            self.updateAnalyticsSharing(disabled: true)
            resultHandler(.success(()))
        }

        
    }

    private func updateAnalyticsSharing(disabled: Bool) {
        do {
            if disabled {
                let disableUseCase = try sessionManager.makeDisableAnalyticsUseCase()
                disableUseCase.invoke()
            } else {
                let enableUseCase = try sessionManager.makeEnableAnalyticsUseCase()
                enableUseCase.invoke()
            }
        } catch {
            WireLogger.analytics.error("Failed to toggle analytics sharing: \(error)")
            return
        }

        ExtensionSettings.shared.disableAnalyticsSharing = disabled
        AVSFlowManager.getInstance()?.setEnableMetrics(!disabled)
    }

}
