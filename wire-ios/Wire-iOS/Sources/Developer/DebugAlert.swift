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
import WireCommonComponents
import WireDataModel
import WireSystem

/// Presents debug alerts
final class DebugAlert {

    private struct Action {
        let text: String
        let type: UIAlertAction.Style
        let action: (() -> Void)?
    }

    private static var isShown = false

    /// Presents an alert to send logs, if in developer mode, otherwise do nothing
    static func showSendLogsMessage(
        message: String,
        presentingViewController: UIViewController,
        fallbackActivityPopoverConfiguration: PopoverPresentationControllerConfiguration
    ) {
        let action1 = Action(text: "Send to Devs", type: .destructive) {
            DebugLogSender.sendLogsByEmail(
                message: message,
                shareWithAVS: false,
                presentingViewController: presentingViewController,
                fallbackActivityPopoverConfiguration: fallbackActivityPopoverConfiguration
            )
        }

        let action2 = Action(text: "Send to Devs & AVS", type: .destructive) {
            DebugLogSender.sendLogsByEmail(
                message: message,
                shareWithAVS: true,
                presentingViewController: presentingViewController,
                fallbackActivityPopoverConfiguration: fallbackActivityPopoverConfiguration
            )
        }

        self.show(
            message: message,
            actions: [action1, action2],
            title: "Send debug logs"
        )
    }

    /// Presents a debug alert with configurable messages and events.
    /// If not in developer mode, does nothing.
    private static func show(
        message: String,
        actions: [Action] = [Action(text: "OK", type: .default, action: nil)],
        title: String = "DEBUG MESSAGE",
        cancelText: String? = "Cancel"
    ) {

        guard Bundle.developerModeEnabled else { return }
        guard let controller = UIApplication.shared.topmostViewController(onlyFullScreen: false), !isShown else { return }
        isShown = true

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        for action in actions {
            let alertAction = UIAlertAction(title: action.text, style: action.type, handler: { _ in
                isShown = false
                action.action?()
            })

            alert.addAction(alertAction)
        }

        if let cancelText {
            let cancelAction = UIAlertAction(title: cancelText, style: .cancel) { _ in
                isShown = false
            }
            alert.addAction(cancelAction)
        }

        controller.present(alert, animated: true, completion: nil)
    }

    static func displayFallbackActivityController(
        email: String,
        from controller: UIViewController,
        popoverPresentationConfiguration: PopoverPresentationControllerConfiguration
    ) {
        let alert = UIAlertController(
            title: L10n.Localizable.Self.Settings.TechnicalReportSection.title,
            message: L10n.Localizable.Self.Settings.TechnicalReport.noMailAlert + email,
            preferredStyle: .alert
        )
        alert.addAction(.cancel())
        alert.addAction(makeFallbackAlertAction(from: controller, popoverPresentationConfiguration: popoverPresentationConfiguration))
        controller.present(alert, animated: true, completion: nil)
    }

    private static func makeFallbackAlertAction(
        from controller: UIViewController,
        popoverPresentationConfiguration: PopoverPresentationControllerConfiguration
    ) -> UIAlertAction {
        UIAlertAction(title: L10n.Localizable.General.ok, style: .default) { _ in
            let logFilesProvider = LogFilesProvider()
            let logsFileURL: URL
            do {
                logsFileURL = try logFilesProvider.generateLogFilesZip()
            } catch {
                WireLogger.system.error("Failed to generate log files zip: \(error)")
                return
            }

            let activityViewController = UIActivityViewController(activityItems: [logsFileURL], applicationActivities: nil)
            activityViewController.configurePopoverPresentationController(using: popoverPresentationConfiguration)
            activityViewController.completionWithItemsHandler = { _, _, _, _ in
                do {
                    try logFilesProvider.clearLogsDirectory()
                } catch {
                    WireLogger.system.warn("Unable to clear temporary directory: \(error)")
                }
            }

            controller.present(activityViewController, animated: true, completion: nil)
        }
    }
}

/// Sends debug logs by email
final class DebugLogSender: NSObject, MFMailComposeViewControllerDelegate {

    private var mailViewController: MFMailComposeViewController?
    static private var senderInstance: DebugLogSender?

    /// Sends recorded logs by email
    static func sendLogsByEmail(
        message: String,
        shareWithAVS: Bool,
        presentingViewController: UIViewController,
        fallbackActivityPopoverConfiguration: PopoverPresentationControllerConfiguration
    ) {
        guard self.senderInstance == nil else { return }

        // Prepare subject & body
        let user = SelfUser.provider?.providedSelfUser as? ZMUser
        let userID = user?.remoteIdentifier?.transportString() ?? ""
        let device = UIDevice.current.name
        let userDescription = "\(user?.name ?? "") [user: \(userID)] [device: \(device)]"
        let mail = shareWithAVS ? WireEmail.shared.callingSupportEmail : WireEmail.shared.supportEmail

        guard MFMailComposeViewController.canSendMail() else {
            return DebugAlert.displayFallbackActivityController(
                email: mail,
                from: presentingViewController,
                popoverPresentationConfiguration: fallbackActivityPopoverConfiguration
            )
        }

        // compose
        let alert = DebugLogSender()

        let mailVC = MFMailComposeViewController()
        mailVC.setToRecipients([mail])
        mailVC.setSubject("iOS logs from \(userDescription)")
        let body = mailVC.prefilledBody(withMessage: message)
        mailVC.setMessageBody(body, isHTML: false)

        mailVC.mailComposeDelegate = alert
        alert.mailViewController = mailVC

        self.senderInstance = alert

        Task {
            await mailVC.attachLogs()
            // as UIViewController is marked @MainActor, this will be executed on mainThread automatically
            await presentingViewController.present(mailVC, animated: true, completion: nil)
        }
    }

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        self.mailViewController = nil
        controller.dismiss(animated: true)
        type(of: self).senderInstance = nil
    }
}
