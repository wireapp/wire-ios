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

import Combine
import MessageUI
import UIKit
import WireCommonComponents
import WireDataModel
import WireLocators
import WireReusableUIComponents
import WireSyncEngine

final class ShareDebugReportPresenter: NSObject, ShareDebugReportViewModelOutput {

    private(set) var isPresenting = false
    private weak var presentedSheet: UIAlertController?
    private weak var presentingViewController: UIViewController?
    private var mailCancellable: AnyCancellable?
    private var mailDelegate: MailComposeDelegate?
    private var activityIndicator: BlockingActivityIndicator?

    @MainActor
    func dismiss(completion: @escaping @MainActor () -> Void) {
        guard isPresenting, let sheet = presentedSheet else {
            completion()
            return
        }
        sheet.dismiss(animated: true) { [weak self] in
            self?.isPresenting = false
            self?.presentedSheet = nil
            completion()
        }
    }

    @MainActor
    func present(from topMostViewController: UIViewController?) {
        guard !isPresenting, let viewController = topMostViewController else { return }
        isPresenting = true
        presentingViewController = viewController

        let userSession = SessionManager.shared?.activeUserSession
        let mainCoordinator = ZClientViewController.shared?.mainCoordinator
        let selfUserID = userSession?.selfUser.remoteIdentifier

        let viewModel = ShareDebugReportViewModel(
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            selfUserID: selfUserID
        )
        viewModel.output = self

        typealias l10n = L10n.Localizable.Self.Settings.ShareDebugReport.ActionSheet
        typealias ids = Locators.ShareDebugReportPage
        let actionSheet = UIAlertController(
            title: l10n.title,
            message: l10n.message,
            preferredStyle: .actionSheet
        )
        actionSheet.view.accessibilityIdentifier = ids.actionSheet.rawValue

        if viewModel.canShareViaWire {
            actionSheet.addAction(UIAlertAction(
                title: l10n.shareViaWire,
                style: .default,
                accessibilityIdentifier: ids.shareViaWireButton.rawValue
            ) { [weak self] _ in
                self?.isPresenting = false
                Task { await viewModel.shareViaWire() }
            })
        }
        if viewModel.canSendEmail {
            actionSheet.addAction(UIAlertAction(
                title: l10n.sendEmail,
                style: .default,
                accessibilityIdentifier: ids.sendEmailButton.rawValue
            ) { [weak self] _ in
                self?.isPresenting = false
                Task { await viewModel.sendEmail() }
            })
        }
        actionSheet.addAction(UIAlertAction(
            title: l10n.share,
            style: .default,
            accessibilityIdentifier: ids.shareButton.rawValue
        ) { [weak self] _ in
            self?.isPresenting = false
            Task { await viewModel.shareViaActivitySheet() }
        })
        actionSheet.addAction(UIAlertAction(
            title: L10n.Localizable.General.cancel,
            style: .cancel,
            accessibilityIdentifier: ids.cancelButton.rawValue
        ) { [weak self] _ in
            self?.isPresenting = false
        })

        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        presentedSheet = actionSheet
        viewController.present(actionSheet, animated: true)

        mailCancellable = viewModel.$mailComposeItem
            .compactMap(\.self)
            .receive(on: RunLoop.main)
            .sink { [weak self, weak viewController] item in
                guard MFMailComposeViewController.canSendMail() else { return }
                let mailVC = MFMailComposeViewController()
                let delegate = MailComposeDelegate { [weak self] in
                    self?.mailDelegate = nil
                    viewModel.mailComposeItem = nil
                }
                self?.mailDelegate = delegate
                mailVC.mailComposeDelegate = delegate
                mailVC.setToRecipients([item.recipient])
                mailVC.setSubject(item.subject)
                mailVC.setMessageBody(item.messageBody, isHTML: false)
                mailVC.addAttachmentData(item.attachmentData, mimeType: "application/zip", fileName: "logs.zip")
                if let popover = mailVC.popoverPresentationController, let view = viewController?.view {
                    popover.sourceView = view
                    popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                viewController?.present(mailVC, animated: true)
            }
    }

    @MainActor
    func shareDebugReportViewModelDidStartCreatingReport(_ viewModel: ShareDebugReportViewModel) {
        guard let view = presentingViewController?.view else { return }
        let indicator = BlockingActivityIndicator(
            view: view,
            accessibilityAnnouncement: nil,
            style: .card
        )
        activityIndicator = indicator
        indicator.start(text: L10n.Localizable.Self.Settings.ShareDebugReport.creatingReport)
    }

    @MainActor
    func shareDebugReportViewModelDidFinishCreatingReport(_ viewModel: ShareDebugReportViewModel) {
        activityIndicator?.stop()
        activityIndicator = nil
    }

    @MainActor
    func shareDebugReportViewModel(
        _ viewModel: ShareDebugReportViewModel,
        presentWireReportAt url: URL
    ) async {
        guard
            let viewController = presentingViewController,
            let userSession = SessionManager.shared?.activeUserSession,
            let mainCoordinator = ZClientViewController.shared?.mainCoordinator
        else { return }

        let shareFile = ShareFileUseCase(contextProvider: userSession.contextProvider)
        let fetchConversations = FetchShareableConversationsUseCase(contextProvider: userSession.contextProvider)
        let conversations = fetchConversations.invoke()
        let metadata = await FileMetaDataGenerator().metadataForFile(at: url)
        let report = ShareableDebugReport(logFileMetadata: metadata, shareFile: shareFile)
        let shareVC = ShareViewController<ZMConversation, ShareableDebugReport>(
            shareable: report,
            destinations: conversations,
            showPreview: true,
            userSession: userSession,
            mainCoordinator: mainCoordinator
        )
        shareVC.onDismiss = { vc, _ in vc.dismiss(animated: true) }
        configurePopover(for: shareVC, sourceView: viewController.view)
        viewController.present(shareVC, animated: true)
    }

    @MainActor
    func shareDebugReportViewModel(
        _ viewModel: ShareDebugReportViewModel,
        presentActivityReportAt url: URL
    ) async {
        guard let viewController = presentingViewController else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        configurePopover(for: activityVC, sourceView: viewController.view)
        viewController.present(activityVC, animated: true)
    }

    @MainActor
    private func configurePopover(for viewController: UIViewController, sourceView: UIView) {
        guard let popover = viewController.popoverPresentationController else { return }
        popover.sourceView = sourceView
        popover.sourceRect = CGRect(
            x: sourceView.bounds.midX,
            y: sourceView.bounds.midY,
            width: 0,
            height: 0
        )
        popover.permittedArrowDirections = []
    }
}

private final class MailComposeDelegate: NSObject, MFMailComposeViewControllerDelegate {

    private let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)
        onDismiss()
    }
}
