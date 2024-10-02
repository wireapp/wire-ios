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

    func showAnalyticsConsentAlert(completion: @escaping (Bool) -> Void) {
        guard let topViewController = UIApplication.shared.topmostViewController(onlyFullScreen: false) else {
            WireLogger.ui.error("No topmost view controller found.")
            return
        }

        let alertController = UIAlertController(
            title: AlertLocale.title,
            message: AlertLocale.message,
            preferredStyle: .alert
        )

        let actions: [(title: String, style: UIAlertAction.Style, handler: (UIAlertAction) -> Void)] = [
            (AlertLocale.Button.agree, .default, { _ in completion(true) }),
            (AlertLocale.Button.decline, .cancel, { _ in completion(false) }),
            (AlertLocale.Button.privacyPolicy, .default, { [weak self] _ in
                self?.presentPrivacyPolicy()
                completion(false)
            })
        ]

        actions.forEach { action in
            alertController.addAction(UIAlertAction(title: action.title, style: action.style, handler: action.handler))
        }

        topViewController.present(alertController, animated: true)
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
