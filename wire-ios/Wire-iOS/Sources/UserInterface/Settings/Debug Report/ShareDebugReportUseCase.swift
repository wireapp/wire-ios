//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireDataModel
import WireMainNavigationUI
import WireReusableUIComponents
import WireSyncEngine
import WireCommonComponents

// sourcery: AutoMockable
protocol ShareDebugReportUseCaseProtocol {
    @MainActor func invoke(logFileURL: URL, from viewController: UIViewController) async
}

final class ShareDebugReportUseCase: ShareDebugReportUseCaseProtocol {

    private let userSession: UserSession?
    private let mainCoordinator: (any MainCoordinatorProtocol)?
    private let mailRecipient: String

    init(
        userSession: UserSession?,
        mainCoordinator: (any MainCoordinatorProtocol)? = nil,
        mailRecipient: String = WireEmail.shared.supportEmail
    ) {
        self.userSession = userSession
        self.mainCoordinator = mainCoordinator
        self.mailRecipient = mailRecipient
    }

    @MainActor
    func invoke(logFileURL: URL, from viewController: UIViewController) async {
        typealias l10n = L10n.Localizable.Self.Settings.ShareDebugReport.ActionSheet

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if let userSession, let mainCoordinator {
            actionSheet.addAction(UIAlertAction(title: l10n.shareViaWire, style: .default) { [weak self, weak viewController] _ in
                guard let self, let viewController else { return }
                Task { @MainActor in
                    await self.shareViaWire(
                        logFileURL: logFileURL,
                        userSession: userSession,
                        mainCoordinator: mainCoordinator,
                        from: viewController
                    )
                }
            })
        }

        if MFMailComposeViewController.canSendMail() {
            actionSheet.addAction(UIAlertAction(title: l10n.sendEmail, style: .default) { [weak self, weak viewController] _ in
                guard let self, let viewController else { return }
                Task { @MainActor in
                    await self.sendEmail(from: viewController)
                }
            })
        }

        actionSheet.addAction(UIAlertAction(title: l10n.share, style: .default) { [weak viewController] _ in
            let activityVC = UIActivityViewController(activityItems: [logFileURL], applicationActivities: nil)
            viewController?.present(activityVC, animated: true)
        })

        actionSheet.addAction(UIAlertAction(title: L10n.Localizable.General.cancel, style: .cancel))

        viewController.present(actionSheet, animated: true)
    }

    // MARK: - Private

    @MainActor
    private func shareViaWire(
        logFileURL: URL,
        userSession: UserSession,
        mainCoordinator: any MainCoordinatorProtocol,
        from viewController: UIViewController
    ) async {
        let shareFile = ShareFileUseCase(contextProvider: userSession.contextProvider)
        let fetchConversations = FetchShareableConversationsUseCase(contextProvider: userSession.contextProvider)
        let conversations = fetchConversations.invoke()
        let metadata = await FileMetaDataGenerator().metadataForFile(at: logFileURL)
        let report = ShareableDebugReport(logFileMetadata: metadata, shareFile: shareFile)

        let shareVC = ShareViewController<ZMConversation, ShareableDebugReport>(
            shareable: report,
            destinations: conversations,
            showPreview: true,
            userSession: userSession,
            mainCoordinator: mainCoordinator
        )
        shareVC.onDismiss = { vc, _ in vc.dismiss(animated: true) }
        viewController.present(shareVC, animated: true)
    }

    @MainActor
    private func sendEmail(from viewController: UIViewController) async {
        let mailVC = MFMailComposeViewController()
        let delegate = MailDelegate()
        mailVC.mailComposeDelegate = delegate
        objc_setAssociatedObject(mailVC, &mailDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        mailVC.setToRecipients([mailRecipient])
        mailVC.setSubject(L10n.Localizable.Self.Settings.TechnicalReport.Mail.subject)
        mailVC.setMessageBody(mailVC.prefilledBody(), isHTML: false)

        let indicator = BlockingActivityIndicator(view: viewController.view, accessibilityAnnouncement: nil)
        indicator.start()

        Task.detached(priority: .userInitiated) {
            await mailVC.attachLogs()
            await MainActor.run {
                indicator.stop()
                viewController.present(mailVC, animated: true)
            }
        }
    }
}

// MARK: - MailDelegate

private final class MailDelegate: NSObject, MFMailComposeViewControllerDelegate {

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        objc_setAssociatedObject(controller, &mailDelegateKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        controller.dismiss(animated: true)
    }
}

private nonisolated(unsafe) var mailDelegateKey: Void?
