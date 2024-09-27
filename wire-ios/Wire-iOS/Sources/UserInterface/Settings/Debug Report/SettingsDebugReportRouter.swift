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
import WireDataModel
import WireReusableUIComponents

// MARK: - SettingsDebugReportRouterProtocol

// sourcery: AutoMockable
protocol SettingsDebugReportRouterProtocol {
    /// Presents the mail composer with the debug report

    @MainActor
    func presentMailComposer()

    /// Presents the fallback alert

    func presentFallbackAlert(sender: UIView)

    /// Presents the share view controller
    ///
    /// - Parameters:
    ///   - destinations: list of conversations to choose from to send the report
    ///   - debugReport: the debug report to share

    func presentShareViewController(
        destinations: [ZMConversation],
        debugReport: ShareableDebugReport
    )
}

// MARK: - SettingsDebugReportRouter

final class SettingsDebugReportRouter: NSObject, SettingsDebugReportRouterProtocol {
    // MARK: Internal

    // MARK: - Properties

    weak var viewController: UIViewController?

    // MARK: - Interface

    func presentShareViewController(
        destinations: [ZMConversation],
        debugReport: ShareableDebugReport
    ) {
        let shareViewController = ShareViewController<ZMConversation, ShareableDebugReport>(
            shareable: debugReport,
            destinations: destinations,
            showPreview: true
        )

        shareViewController.onDismiss = { shareController, _ in
            shareController.dismiss(animated: true)
        }

        viewController?.present(shareViewController, animated: true)
    }

    @MainActor
    func presentMailComposer() {
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self
        mailComposeViewController.setToRecipients([mailRecipient])
        mailComposeViewController.setSubject(L10n.Localizable.Self.Settings.TechnicalReport.Mail.subject)
        let body = mailComposeViewController.prefilledBody()
        mailComposeViewController.setMessageBody(body, isHTML: false)

        activityIndicator.stop()
        let topMostViewController = UIApplication.shared.topmostViewController(onlyFullScreen: false)
        Task.detached(priority: .userInitiated) { [activityIndicator] in
            await mailComposeViewController.attachLogs()

            await self.viewController?.present(mailComposeViewController, animated: true, completion: nil)
            await MainActor.run {
                activityIndicator.stop()
            }
        }
    }

    @MainActor
    func presentFallbackAlert(sender: UIView) {
        guard let viewController else {
            return
        }

        DebugAlert.displayFallbackActivityController(
            email: mailRecipient,
            from: viewController,
            popoverPresentationConfiguration: .superviewAndFrame(of: sender, insetBy: (dx: -4, dy: -4))
        )
    }

    // MARK: Private

    private let mailRecipient = WireEmail.shared.callingSupportEmail

    private lazy var activityIndicator = {
        let topMostViewController = UIApplication.shared.topmostViewController(onlyFullScreen: false)
        return BlockingActivityIndicator(view: topMostViewController!.view)
    }()
}

// MARK: MFMailComposeViewControllerDelegate

extension SettingsDebugReportRouter: MFMailComposeViewControllerDelegate {
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)
    }
}
