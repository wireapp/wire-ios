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

protocol SendTechnicalReportPresenter: MFMailComposeViewControllerDelegate {
    func presentMailComposer()
}

extension SendTechnicalReportPresenter where Self: UIViewController {
    @MainActor
    func presentMailComposer() {
        presentMailComposer(sourceView: nil)
    }

    @MainActor
    func presentMailComposer(sourceView: UIView?) {
        let mailRecipient = WireEmail.shared.callingSupportEmail

        guard MFMailComposeViewController.canSendMail() else {
            DebugAlert.displayFallbackActivityController(
                logPaths: DebugLogSender.existingDebugLogs,
                email: mailRecipient,
                from: self, sourceView: sourceView
            )
            return
        }

        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self
        mailComposeViewController.setToRecipients([mailRecipient])
        mailComposeViewController.setSubject(L10n.Localizable.Self.Settings.TechnicalReport.Mail.subject)
        let body = mailComposeViewController.prefilledBody()
        mailComposeViewController.setMessageBody(body, isHTML: false)

        let topMostViewController: SpinnerCapableViewController? = UIApplication.shared.topmostViewController(onlyFullScreen: false) as? SpinnerCapableViewController
        topMostViewController?.isLoadingViewVisible = true

        Task.detached(priority: .userInitiated, operation: { [topMostViewController] in
            await mailComposeViewController.attachLogs()

            await self.present(mailComposeViewController, animated: true, completion: nil)
            await MainActor.run {
                topMostViewController?.isLoadingViewVisible = false
            }
        })
    }
}
