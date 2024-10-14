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

import UIKit
import WireSystem

extension TrackingManager {

    typealias AlertLocale = L10n.Localizable.Self.Settings.PrivacyAnalytics.Alert

    enum AnalyticsError: Error {

        case unableToPresentAlert

    }

    @MainActor
    func requestFirstTimeAnalyticsConsentIfNeeded() async throws {
        // Only ask if user has not given a preference yet.
        guard !doesUserConsentPreferenceExist else {
            return
        }

        WireLogger.analytics.debug("requesting first time analytics content")
        let didConsent = try await requestAnalyticsConsent()
        WireLogger.analytics.debug("user did consent: \(didConsent)")
        await updateAnalyticsSharing(disabled: !didConsent)
    }

    @MainActor
    func requestAnalyticsConsent() async throws -> Bool {
        guard let viewController = UIApplication.shared.topmostViewController(onlyFullScreen: false) else {
            throw AnalyticsError.unableToPresentAlert
        }

        return await withCheckedContinuation { continuation in
            let alert = UIAlertController(
                title: AlertLocale.title,
                message: AlertLocale.message,
                preferredStyle: .alert
            )

            alert.addAction(
                UIAlertAction(
                    title: AlertLocale.Button.agree,
                    style: .default,
                    handler: { _ in
                        continuation.resume(returning: true)
                    }
                )
            )

            alert.addAction(
                UIAlertAction(
                    title: AlertLocale.Button.decline,
                    style: .cancel,
                    handler: { _ in
                        continuation.resume(returning: false)
                    }
                )
            )

            alert.addAction(
                UIAlertAction(
                    title: AlertLocale.Button.privacyPolicy,
                    style: .default,
                    handler: { [weak self] _ in
                        self?.presentPrivacyPolicy()
                        continuation.resume(returning: false)
                    }
                )
            )

            viewController.present(
                alert,
                animated: true
            )
        }
    }

    private func presentPrivacyPolicy() {
        guard let topViewController = UIApplication.shared.topmostViewController(onlyFullScreen: false) else {
            WireLogger.ui.error("No topmost view controller found.")
            return
        }

        let browserViewController = BrowserViewController(url: WireURLs.shared.privacyPolicy)
        topViewController.present(browserViewController, animated: true)
    }
}
