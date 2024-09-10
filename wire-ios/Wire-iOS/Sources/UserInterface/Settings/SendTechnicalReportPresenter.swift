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

import MessageUI
import UIKit
import WireReusableUIComponents
import WireSystem

protocol SendTechnicalReportPresenter: MFMailComposeViewControllerDelegate {
    @MainActor
    func presentMailComposer(fallbackActivityPopoverConfiguration: PopoverPresentationControllerConfiguration)
}

extension SendTechnicalReportPresenter where Self: UIViewController {

    @MainActor
    func presentMailComposer(fallbackActivityPopoverConfiguration: PopoverPresentationControllerConfiguration) {
        let mailRecipient = WireEmail.shared.callingSupportEmail

        guard MFMailComposeViewController.canSendMail() else {
            // we will be stuck on the blocker screen after that
            // considering this an edge case for now
            return DebugAlert.displayFallbackActivityController(
                email: mailRecipient,
                from: self,
                popoverPresentationConfiguration: fallbackActivityPopoverConfiguration
            )
        }

        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self
        mailComposeViewController.setToRecipients([mailRecipient])
        mailComposeViewController.setSubject(L10n.Localizable.Self.Settings.TechnicalReport.Mail.subject)
        let body = mailComposeViewController.prefilledBody()
        mailComposeViewController.setMessageBody(body, isHTML: false)

        let topMostViewController = UIApplication.shared.topmostViewController(onlyFullScreen: false)
        let activityIndicator = BlockingActivityIndicator(view: topMostViewController!.view)
        activityIndicator.start()

        Task.detached(priority: .userInitiated) {
            await mailComposeViewController.attachLogs()

            await self.present(mailComposeViewController, animated: true, completion: nil)
            await MainActor.run {
                activityIndicator.stop()
            }
        }
    }
}
