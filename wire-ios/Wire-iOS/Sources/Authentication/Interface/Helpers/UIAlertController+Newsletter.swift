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
import WireCommonComponents

extension UIAlertController {
    /// flag for preventing newsletter subscription dialog shows again in team creation workflow.
    /// (team create work flow: newsletter subscription dialog appears after email verification.
    /// email regisration work flow: newsletter subscription dialog appears after conversation list is displayed.)
    static var newsletterSubscriptionDialogWasDisplayed = false

    static func showNewsletterSubscriptionDialog(
        over viewController: UIViewController,
        completionHandler: @escaping ResultHandler
    ) {
        guard !AutomationHelper.sharedHelper.skipFirstLoginAlerts, !dataCollectionDisabled else {
            return
        }

        let alertController = UIAlertController(
            title: L10n.Localizable.NewsOffers.Consent.title,
            message: L10n.Localizable.NewsOffers.Consent.message,
            preferredStyle: .alert
        )

        let privacyPolicyActionHandler: ((UIAlertAction) -> Swift.Void) = { _ in
            let browserViewController = BrowserViewController(url: WireURLs.shared.privacyPolicy)

            browserViewController.completion = {
                UIAlertController.showNewsletterSubscriptionDialog(
                    over: viewController,
                    completionHandler: completionHandler
                )
            }

            viewController.present(browserViewController, animated: true)
        }

        alertController.addAction(UIAlertAction(
            title: L10n.Localizable.NewsOffers.Consent.Button.PrivacyPolicy.title,
            style: .default,
            handler: privacyPolicyActionHandler
        ))

        alertController.addAction(UIAlertAction(
            title: L10n.Localizable.General.decline,
            style: .default,
            handler: { _ in
                completionHandler(false)
            }
        ))

        alertController.addAction(UIAlertAction(
            title: L10n.Localizable.General.accept,
            style: .cancel,
            handler: { _ in
                completionHandler(true)
            }
        ))

        UIAlertController.newsletterSubscriptionDialogWasDisplayed = true
        viewController.present(alertController, animated: true) {
            AppDelegate.shared.mainWindow?.endEditing(true)
        }
    }

    private static  var dataCollectionDisabled: Bool {
        #if DATA_COLLECTION_DISABLED
            return true
        #else
            return false
        #endif
    }

    static func showNewsletterSubscriptionDialogIfNeeded(
        presentViewController: UIViewController,
        completionHandler: @escaping ResultHandler
    ) {
        guard !UIAlertController.newsletterSubscriptionDialogWasDisplayed else {
            return
        }

        showNewsletterSubscriptionDialog(over: presentViewController, completionHandler: completionHandler)
    }
}

extension AuthenticationCoordinatorAlertAction {
    fileprivate static var privacyPolicy: Self {
        Self(
            title: L10n.Localizable.NewsOffers.Consent.Button.PrivacyPolicy.title,
            coordinatorActions: [.showLoadingView, .openURL(WireURLs.shared.privacyPolicy)]
        )
    }

    fileprivate static var decline: Self {
        Self(
            title: L10n.Localizable.General.decline,
            coordinatorActions: [.setMarketingConsent(false)]
        )
    }

    fileprivate static var accept: Self {
        Self(
            title: L10n.Localizable.General.accept,
            coordinatorActions: [.setMarketingConsent(true)]
        )
    }
}
