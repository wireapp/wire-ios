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

import UIKit
import WireDataModel
import WireLogging
import WireSyncEngine

extension ConversationContentViewController {
    // MARK: - EditMessages

    func editLastMessage() {
        if let lastEditableMessage = conversation.lastEditableMessage {
            perform(action: .edit, for: lastEditableMessage, view: tableView)
        }
    }

    func presentDetails(for message: ZMConversationMessage) {
        let isFile = Message.isFileTransfer(message)
        let isImage = Message.isImage(message)
        let isLocation = Message.isLocation(message)

        guard isFile || isImage || isLocation else {
            return
        }

        messagePresenter.open(
            message,
            targetView: tableView.targetView(for: message, dataSource: dataSource),
            actionResponder: self,
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            selfProfileUIBuilder: selfProfileUIBuilder
        )
    }

    func openSketch(for message: ZMConversationMessage, in editMode: CanvasViewControllerEditMode) {
        let canvasViewController = CanvasViewController()
        if let imageData = message.imageMessageData?.imageData {
            canvasViewController.sketchImage = UIImage(data: imageData)
        }
        canvasViewController.delegate = self
        canvasViewController.setupNavigationBarTitle(message.conversationLike?.displayName ?? "")
        canvasViewController.select(editMode: editMode, animated: false)

        present(canvasViewController.wrapInNavigationController(), animated: true)
    }

    func messageAction(
        actionId: MessageAction,
        for message: ZMConversationMessage,
        view: UIView
    ) {
        switch actionId {
        case .cancel:
            userSession.enqueue {
                WireLogger.messaging.info(
                    "cancel message",
                    attributes: [
                        LogAttributesKey.conversationId: message.conversation?.qualifiedID?
                            .safeForLoggingDescription ?? "<nil>"
                    ], .safePublic
                )

                message.fileMessageData?.cancelTransfer()
            }
        case .resend:
            userSession.enqueue {
                WireLogger.messaging.info(
                    "resend message",
                    attributes: [
                        LogAttributesKey.conversationId: message.conversation?.qualifiedID?
                            .safeForLoggingDescription ?? "<nil>"
                    ], .safePublic
                )

                message.resend()
            }
        case .delete:
            assert(message.canBeDeleted)
            let attachments = message.multipartMessageData?.attachments

            deletionDialogPresenter = DeletionDialogPresenter(sourceViewController: presentedViewController ?? self)
            deletionDialogPresenter?.presentDeletionAlertController(
                forMessage: message,
                source: view,
                userSession: userSession
            ) { [weak self] deleted, deletionType in
                guard let self else { return }

                if deleted {
                    presentedViewController?.dismiss(animated: true)
                    if let attachments, let deletionType {
                        delegate?.conversationContentViewController(
                            self,
                            didDeleteMultipartMessage: message,
                            withAttachments: attachments,
                            deletionType: deletionType
                        )
                    }
                }
            }
        case .present:
            dataSource.selectedMessage = message
            presentDetails(for: message)
        case .save:
            if Message.isImage(message) {
                saveImage(from: message, view: view)
            } else if let fileURL = message.fileMessageData?.temporaryURLToDecryptedFile() {
                dataSource.selectedMessage = message

                let activityViewController = UIActivityViewController(
                    activityItems: [fileURL],
                    applicationActivities: nil
                )
                activityViewController.configurePopoverPresentationController(
                    using: .superviewAndFrame(of: (view as? SelectableView)?.selectionView ?? view)
                )
                present(activityViewController, animated: true)
            } else {
                WireLogger.conversation
                    .warn("Saving a message of any type other than image or file is currently not handled.")
            }
        case .digitallySign:
            dataSource.selectedMessage = message
            if message.isFileDownloaded() {
                signPDFDocument(for: message, observer: self)
            } else {
                presentDownloadNecessaryAlert(for: message)
            }
        case .edit:
            dataSource.editingMessage = message
            delegate?.conversationContentViewController(self, didTriggerEditing: message)
        case .sketchDraw:
            openSketch(for: message, in: .draw)
        case .sketchEmoji:
            openSketch(for: message, in: .emoji)
        case .showInConversation:
            scroll(to: message) { _ in
                self.dataSource.highlight(message: message)
            }
        case .copy:
            message.copy(in: .general)
        case .download:
            userSession.enqueue {
                message.fileMessageData?.requestFileDownload()
            }
        case .reply:
            delegate?.conversationContentViewController(self, didTriggerReplyingTo: message)
        case .openQuote:
            if let quote = message.textMessageData?.quoteMessage {
                scroll(to: quote) { _ in
                    self.dataSource.highlight(message: quote)
                }
            }
        case .openDetails:
            let detailsViewController = MessageDetailsViewController(
                message: message,
                userSession: userSession,
                mainCoordinator: mainCoordinator,
                selfProfileUIBuilder: selfProfileUIBuilder
            )

            let navigationController = UINavigationController(rootViewController: detailsViewController)
            navigationController.modalPresentationStyle = .formSheet

            parent?.present(navigationController, animated: true)
        case .resetSession:
            guard let client = message.systemMessageData?.clients.first as? UserClient else { return }
            activityIndicator.start()
            userClientToken = UserClientChangeInfo.add(observer: self, for: client)
            client.resetSession()
        case let .react(reaction):
            userSession.perform {
                let useCase = self.userSession.makeToggleMessageReactionUseCase()
                useCase.invoke(reaction, for: message, in: self.conversation)
            }
        case .visitLink:
            let textMessageData = message.textMessageData
            let content = textMessageData?.linkPreview?.originalURLString ?? textMessageData?.messageText
            guard let content, let url = linkDetector?.detectLinks(in: content).first else { return }
            UIApplication.shared.open(url)
        case .collapse:
            dataSource.collapse(message: message)
        }
    }

    private func signPDFDocument(
        for message: ZMConversationMessage,
        observer: SignatureObserver
    ) {
        guard let token = message.fileMessageData?.signPDFDocument(observer: observer) else {
            didFailSignature(errorType: .noConsentURL)
            return
        }
        digitalSignatureToken = token
    }

    private func presentDownloadNecessaryAlert(for message: ZMConversationMessage) {
        let alertMessage = L10n.Localizable.DigitalSignature.Alert.downloadNecessary
        let alertController = UIAlertController(title: "", message: alertMessage, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: L10n.Localizable.General.close, style: .default)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
}

// MARK: - UserClientObserver

extension ConversationContentViewController: UserClientObserver {

    func userClientDidChange(_ changeInfo: UserClientChangeInfo) {
        if changeInfo.sessionHasBeenReset {
            userClientToken = nil
            activityIndicator.stop()
        }
    }
}

// MARK: - SignatureObserver

extension ConversationContentViewController: SignatureObserver {

    func willReceiveSignatureURL() {
        activityIndicator.start()
    }

    func didReceiveSignatureURL(_ url: URL) {
        activityIndicator.stop()
        presentDigitalSignatureVerification(with: url)
    }

    func didReceiveDigitalSignature(_ cmsFileMetadata: ZMFileMetadata) {
        dismissDigitalSignatureVerification { [weak self] in
            ZMUserSession.shared()?.perform {
                do {
                    try self?.conversation.appendFile(with: cmsFileMetadata)
                } catch {
                    Logging.messageProcessing.warn("Failed to append file. Reason: \(error.localizedDescription)")
                }
            }
        }
    }

    func didFailSignature(errorType: SignatureStatus.ErrorYpe) {
        activityIndicator.stop()
        if isDigitalSignatureVerificationShown {
            dismissDigitalSignatureVerification { [weak self] in
                self?.presentDigitalSignatureErrorAlert(errorType: errorType)
            }
        } else {
            presentDigitalSignatureErrorAlert(errorType: errorType)
        }
    }

    // MARK: - Helpers

    private func presentDigitalSignatureVerification(with url: URL) {
        let digitalSignatureVerification = DigitalSignatureVerificationViewController(url: url) { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
                    self?.retriveSignature()
                }
            case let .failure(error):
                self?.dismissDigitalSignatureVerification(completion: {
                    if case DigitalSignatureVerificationError.otherError = error {
                        self?.retriveSignature()
                        return
                    }

                    self?.presentDigitalSignatureErrorAlert(errorType: .retrieveFailed)
                })
            }
        }
        let navigationController = UINavigationController(rootViewController: digitalSignatureVerification)
        present(navigationController, animated: true, completion: { [weak self] in
            self?.isDigitalSignatureVerificationShown = true
        })
    }

    private func retriveSignature() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
            self?.dataSource.selectedMessage?
                .fileMessageData?.retrievePDFSignature()
        }
    }

    private func presentDigitalSignatureErrorAlert(errorType: SignatureStatus.ErrorYpe) {
        let message: String? = switch errorType {
        case .noConsentURL:
            L10n.Localizable.DigitalSignature.Alert.Error.noConsentUrl
        case .retrieveFailed:
            L10n.Localizable.DigitalSignature.Alert.Error.noSignature
        }

        let alertController = UIAlertController(
            title: "",
            message: message,
            preferredStyle: .alert
        )

        let closeAction = UIAlertAction(
            title: L10n.Localizable.General.close,
            style: .default
        )

        alertController.addAction(closeAction)
        present(alertController, animated: true)
    }

    private func dismissDigitalSignatureVerification(completion: (() -> Void)? = nil) {
        dismiss(animated: true, completion: { [weak self] in
            self?.isDigitalSignatureVerificationShown = false
            completion?()
        })
    }
}
